import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/transaction.dart';
import '../../services/auth_service.dart';
import '../../services/connectivity_service.dart';
import '../../services/offline_queue_service.dart';
import '../../services/sync_service.dart';
import '../../services/transaction_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/buttons.dart';
import '../../widgets/notification_banner.dart';
import '../../widgets/section_card.dart';
import '../../widgets/status_badge.dart';
import '../dialogs/add_transaction_dialog.dart';
import '../transaction_receipt_screen.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  List<Transaction> _transactions = [];
  bool _loading = true;
  String? _error;
  StreamSubscription<bool>? _syncSubscription;

  bool get _isAdmin => AuthService.instance.isAdmin;

  int get _pendingSyncCount =>
      _transactions.where((t) => t.isPendingSync).length;

  @override
  void initState() {
    super.initState();
    _loadTransactions();

    // Auto-sync and refresh whenever we come back online.
    _syncSubscription =
        ConnectivityService.instance.onOnlineStatusChanged.listen((isOnline) async {
      if (isOnline) {
        await SyncService.instance.syncPendingTransactions();
        if (mounted) _loadTransactions();
      }
    });
  }

  @override
  void dispose() {
    _syncSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadTransactions() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final txns = await TransactionService.instance.getAll();

      // Merge in anything still waiting in the offline queue — these
      // haven't reached the server yet so getAll() won't include them.
      final pendingLocal = OfflineQueueService.instance.getAll().map((p) {
        return Transaction(
          billNo: p.billNo,
          type: p.type,
          status: p.status,
          totalItems: p.items.fold<int>(0, (sum, item) => sum + item.quantity),
          remarks: p.remarks,
          issuedTo: p.issuedTo,
          createdBy: p.userId,
          createdAt: p.queuedAt,
          items: p.items,
          localId: p.localId,
          isPendingSync: true,
        );
      }).toList();

      if (!mounted) return;
      setState(() {
        _transactions = [...pendingLocal, ...txns];
        _loading = false;
      });

      if (pendingLocal.isNotEmpty) {
        NotificationBanner.show(
          context,
          '${pendingLocal.length} transaction'
          '${pendingLocal.length == 1 ? '' : 's'} waiting to sync — '
          'look for the "Pending Sync" badge below.',
          tone: NotificationTone.warning,
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _onAddTransaction() async {
    final added = await AddTransactionDialog.show(context);
    if (added == true) {
      _loadTransactions();
    }
  }

  Future<void> _onEditTransaction(Transaction txn) async {
    if (txn.isPendingSync) {
      NotificationBanner.show(
        context,
        'This transaction hasn\'t synced yet — it can\'t be edited until it\'s online.',
        tone: NotificationTone.warning,
      );
      return;
    }
    try {
      // Fetch the full transaction (with items) before opening edit mode.
      final full =
          txn.id != null ? await TransactionService.instance.getById(txn.id!) : txn;
      if (!mounted) return;
      final updated = await AddTransactionDialog.showEdit(context, full);
      if (updated == true) {
        _loadTransactions();
      }
    } catch (e) {
      if (!mounted) return;
      NotificationBanner.show(
        context,
        'Failed to load transaction for editing: $e',
        tone: NotificationTone.error,
      );
    }
  }

  Future<void> _onDeleteTransaction(Transaction txn) async {
    if (txn.isPendingSync) {
      if (txn.localId != null) {
        await OfflineQueueService.instance.remove(txn.localId!);
        if (!mounted) return;
        NotificationBanner.show(
          context,
          'Removed unsynced transaction ${txn.billNo} from the queue.',
          tone: NotificationTone.success,
        );
        _loadTransactions();
      }
      return;
    }
    if (txn.id == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete Transaction ${txn.billNo}?', style: AppTextStyles.h3),
        content: Text(
          'This will permanently delete this transaction and its items. '
          'This action cannot be undone and does NOT reverse stock — '
          'cancel the transaction first if you need stock reversed.',
          style: AppTextStyles.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Keep Transaction', style: AppTextStyles.bodyMedium),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await TransactionService.instance.deleteTransaction(txn.id!);
      if (!mounted) return;
      NotificationBanner.show(
        context,
        'Transaction ${txn.billNo} deleted.',
        tone: NotificationTone.success,
      );
      _loadTransactions();
    } catch (e) {
      if (!mounted) return;
      NotificationBanner.show(
        context,
        'Failed to delete transaction: $e',
        tone: NotificationTone.error,
      );
    }
  }

  Future<void> _showTransactionDetails(Transaction txn) async {
    if (txn.isPendingSync) {
      NotificationBanner.show(
        context,
        'This transaction is still queued offline — details will be available once it syncs.',
        tone: NotificationTone.warning,
      );
      return;
    }
    try {
      final detailedTxn = txn.id != null
          ? await TransactionService.instance.getById(txn.id!)
          : txn;
      if (!mounted) return;
      TransactionReceiptScreen.navigateTo(context, detailedTxn);
    } catch (e) {
      if (!mounted) return;
      NotificationBanner.show(
        context,
        'Failed to load transaction details: $e',
        tone: NotificationTone.error,
      );
    }
  }

  BadgeTone _statusTone(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return BadgeTone.success;
      case 'pending':
        return BadgeTone.warning;
      case 'cancelled':
        return BadgeTone.danger;
      default:
        return BadgeTone.neutral;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(32, 28, 32, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ScreenHeader(
            title: 'Transactions',
            subtitle: _loading
                ? 'Loading transactions...'
                : _pendingSyncCount > 0
                    ? '${_transactions.length} total stock transactions '
                        '· $_pendingSyncCount pending sync'
                    : '${_transactions.length} total stock transactions',
            actions: [
              PrimaryButton(
                label: 'Add Transaction',
                icon: Icons.add_rounded,
                onPressed: _onAddTransaction,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          SectionCard(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.sm),
            child: _loading
                ? const SizedBox(
                    height: 240,
                    child: Center(child: CircularProgressIndicator()),
                  )
                : _error != null
                    ? SizedBox(
                        height: 200,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Failed to load transactions',
                                  style: AppTextStyles.h3),
                              const SizedBox(height: 8),
                              Text(_error!,
                                  style: AppTextStyles.caption
                                      .copyWith(color: AppColors.danger)),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _loadTransactions,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _transactions.isEmpty
                        ? SizedBox(
                            height: 200,
                            child: Center(
                              child: Text(
                                'No transactions recorded yet. Click "Add Transaction" to create one.',
                                style: AppTextStyles.body
                                    .copyWith(color: AppColors.textSecondary),
                              ),
                            ),
                          )
                        : SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(minWidth: 840),
                              child: DataTable(
                                showCheckboxColumn: false,
                                headingRowColor:
                                    WidgetStateProperty.all(Colors.transparent),
                                dividerThickness: 0.6,
                                columnSpacing: 28,
                                horizontalMargin: 4,
                                headingTextStyle: AppTextStyles.label,
                                dataTextStyle: AppTextStyles.body,
                                columns: [
                                  const DataColumn(label: Text('BILL NO.')),
                                  const DataColumn(label: Text('TYPE')),
                                  const DataColumn(
                                      label: Text('TOTAL ITEMS'), numeric: true),
                                  const DataColumn(label: Text('CREATED BY')),
                                  const DataColumn(label: Text('ISSUED TO')),
                                  const DataColumn(label: Text('STATUS')),
                                  const DataColumn(label: Text('DATE')),
                                  // Action column only shown to admins.
                                  if (_isAdmin)
                                    const DataColumn(label: Text('')),
                                ],
                                rows: _transactions.map((t) {
                                  final isInbound = t.type == 'inbound';
                                  final isCancelled =
                                      t.status.toLowerCase() == 'cancelled';
                                  final dateStr = t.createdAt != null
                                      ? '${t.createdAt!.year}-${t.createdAt!.month.toString().padLeft(2, '0')}-${t.createdAt!.day.toString().padLeft(2, '0')}'
                                      : 'N/A';

                                  return DataRow(
                                    cells: [
                                      DataCell(
                                        Text(
                                          t.billNo,
                                          style: AppTextStyles.mono.copyWith(
                                              color: AppColors.textPrimary,
                                              fontWeight: FontWeight.w600),
                                        ),
                                        onTap: () => _showTransactionDetails(t),
                                      ),
                                      DataCell(
                                        StatusBadge(
                                          label: isInbound ? '+ Inbound' : '- Outbound',
                                          tone: isInbound
                                              ? BadgeTone.success
                                              : BadgeTone.danger,
                                        ),
                                        onTap: () => _showTransactionDetails(t),
                                      ),
                                      DataCell(
                                        Text('${t.totalItems}',
                                            style: AppTextStyles.bodyMedium),
                                        onTap: () => _showTransactionDetails(t),
                                      ),
                                      DataCell(
                                        Text(t.createdByName ?? 'User',
                                            style: AppTextStyles.body),
                                        onTap: () => _showTransactionDetails(t),
                                      ),
                                      DataCell(
                                        Text(t.issuedTo ?? '—',
                                            style: AppTextStyles.body
                                                .copyWith(color: AppColors.textSecondary)),
                                        onTap: () => _showTransactionDetails(t),
                                      ),
                                      DataCell(
                                        t.isPendingSync
                                            ? const StatusBadge(
                                                label: 'Pending Sync',
                                                tone: BadgeTone.warning,
                                              )
                                            : StatusBadge(
                                                label: t.status,
                                                tone: _statusTone(t.status)),
                                        onTap: () => _showTransactionDetails(t),
                                      ),
                                      DataCell(
                                        Text(dateStr,
                                            style: AppTextStyles.body.copyWith(
                                                color: AppColors.textSecondary)),
                                        onTap: () => _showTransactionDetails(t),
                                      ),
                                      // Admin-only actions: edit + delete.
                                      if (_isAdmin)
                                        DataCell(
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                onPressed: isCancelled
                                                    ? null
                                                    : () => _onEditTransaction(t),
                                                icon: const Icon(
                                                    Icons.edit_outlined,
                                                    size: 19,
                                                    color: AppColors.primary),
                                                splashRadius: 18,
                                                tooltip: isCancelled
                                                    ? 'Cancelled transactions cannot be edited'
                                                    : 'Edit Transaction',
                                              ),
                                              IconButton(
                                                onPressed: () =>
                                                    _onDeleteTransaction(t),
                                                icon: const Icon(
                                                    Icons.delete_outline_rounded,
                                                    size: 19,
                                                    color: AppColors.danger),
                                                splashRadius: 18,
                                                tooltip: 'Delete Transaction',
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}