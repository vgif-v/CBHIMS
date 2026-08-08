import 'package:flutter/material.dart';
import '../../models/transaction.dart';
import '../../services/product_service.dart';
import '../../services/transaction_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/section_card.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/top_header_bar.dart';
import '../dialogs/add_product_dialog.dart';
import '../dialogs/add_transaction_dialog.dart';
import '../transaction_receipt_screen.dart';
import 'account_screen.dart';

class DashboardScreen extends StatefulWidget {
  final ValueChanged<int>? onNavigateToTab;

  const DashboardScreen({super.key, this.onNavigateToTab});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _totalProducts = 0;
  int _lowStockCount = 0;
  List<Transaction> _recentTransactions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _loading = true);
    try {
      final totalFuture = ProductService.instance.getTotalCount();
      final lowStockFuture = ProductService.instance.getLowStockCount();
      final recentTxnsFuture = TransactionService.instance.getRecent(limit: 5);

      final results = await Future.wait([
        totalFuture,
        lowStockFuture,
        recentTxnsFuture,
      ]);

      if (!mounted) return;
      setState(() {
        _totalProducts = results[0] as int;
        _lowStockCount = results[1] as int;
        _recentTransactions = results[2] as List<Transaction>;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _onAddProduct() async {
    await AddProductDialog.show(
      context,
      onProductAdded: _loadDashboardData,
    );
    _loadDashboardData();
  }

  Future<void> _onAddTransaction() async {
    final added = await AddTransactionDialog.show(context);
    if (added == true) {
      _loadDashboardData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final horizontalPadding = width < 520 ? 16.0 : 32.0;

    return SingleChildScrollView(
      padding:
          EdgeInsets.fromLTRB(horizontalPadding, 28, horizontalPadding, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TopHeaderBar(
            title: 'Dashboard',
            subtitle:
                'Welcome back — here\'s what\'s happening in your warehouse.',
            onAccountTap: () {
              if (widget.onNavigateToTab != null) {
                widget.onNavigateToTab!(5);
              } else {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const Scaffold(body: AccountScreen())),
                );
              }
            },
          ),
          const SizedBox(height: AppSpacing.xl),
          _buildStatGrid(context),
          const SizedBox(height: AppSpacing.lg),
          _buildMiddleSection(context),
          const SizedBox(height: AppSpacing.lg),
          _buildRecentTransactions(context),
        ],
      ),
    );
  }

  Widget _buildStatGrid(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cards = [
          StatCard(
            label: 'Total Products',
            value: _loading ? '...' : '$_totalProducts',
            icon: Icons.inventory_2_rounded,
            iconColor: AppColors.primary,
            iconBg: AppColors.primarySoft,
          ),
          StatCard(
            label: 'Low Stock Alert',
            value: _loading ? '...' : '$_lowStockCount',
            icon: Icons.warning_rounded,
            iconColor: AppColors.warning,
            iconBg: AppColors.warningSoft,
            badgeText: _lowStockCount > 0 ? 'Needs review' : 'Optimal',
            badgeTone:
                _lowStockCount > 0 ? BadgeTone.warning : BadgeTone.success,
          ),
        ];

        if (constraints.maxWidth <= 520) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (int i = 0; i < cards.length; i++) ...[
                cards[i],
                if (i != cards.length - 1)
                  const SizedBox(height: AppSpacing.md),
              ],
            ],
          );
        }

        if (constraints.maxWidth <= 900) {
          final itemWidth = (constraints.maxWidth - AppSpacing.md) / 2;
          return Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children:
                cards.map((c) => SizedBox(width: itemWidth, child: c)).toList(),
          );
        }

        return Row(
          children: [
            for (int i = 0; i < cards.length; i++) ...[
              Expanded(child: cards[i]),
              if (i != cards.length - 1) const SizedBox(width: AppSpacing.md),
            ],
          ],
        );
      },
    );
  }

  Widget _buildMiddleSection(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final actions = _buildQuickActions();
        return actions;
      },
    );
  }

  Widget _buildQuickActions() {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Quick Actions', style: AppTextStyles.h3),
          const SizedBox(height: 4),
          Text('Common tasks, one tap away.', style: AppTextStyles.caption),
          const SizedBox(height: AppSpacing.lg),
          _QuickActionButton(
            icon: Icons.add_circle_rounded,
            label: 'Add Product',
            iconColor: AppColors.primary,
            iconBg: AppColors.primarySoft,
            onTap: _onAddProduct,
          ),
          const SizedBox(height: AppSpacing.sm),
          _QuickActionButton(
            icon: Icons.sync_alt_rounded,
            label: 'Add Transaction (Inbound/Outbound)',
            iconColor: AppColors.success,
            iconBg: AppColors.successSoft,
            onTap: _onAddTransaction,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTransactions(BuildContext context) {
    return SectionCard(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Recent Transactions', style: AppTextStyles.h3),
              TextButton(
                onPressed: _loadDashboardData,
                style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                child: Text('Refresh',
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.primary)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          _loading
              ? const SizedBox(
                  height: 140,
                  child: Center(child: CircularProgressIndicator()),
                )
              : _recentTransactions.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          'No recent transactions recorded yet.',
                          style: AppTextStyles.body
                              .copyWith(color: AppColors.textSecondary),
                        ),
                      ),
                    )
                  : _TransactionsTable(transactions: _recentTransactions),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color iconColor;
  final Color iconBg;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.iconColor,
    required this.iconBg,
    required this.onTap,
  });

  @override
  State<_QuickActionButton> createState() => _QuickActionButtonState();
}

class _QuickActionButtonState extends State<_QuickActionButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _hovering ? AppColors.background : AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                    color: widget.iconBg,
                    borderRadius: BorderRadius.circular(8)),
                child: Icon(widget.icon, size: 17, color: widget.iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                  child: Text(widget.label, style: AppTextStyles.bodyMedium)),
              const Icon(Icons.chevron_right_rounded,
                  size: 18, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class _TransactionsTable extends StatelessWidget {
  final List<Transaction> transactions;
  const _TransactionsTable({required this.transactions});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 600),
        child: DataTable(
          showCheckboxColumn: false,
          dataRowMaxHeight: double.infinity,
          headingRowColor: WidgetStateProperty.all(Colors.transparent),
          dividerThickness: 1,
          columnSpacing: 32,
          horizontalMargin: 4,
          headingTextStyle: AppTextStyles.label,
          dataTextStyle: AppTextStyles.body,
          columns: const [
            DataColumn(label: Text('BILL NO.')),
            DataColumn(label: Text('TYPE')),
            DataColumn(label: Text('TOTAL ITEMS'), numeric: true),
            DataColumn(label: Text('DATE')),
          ],
          rows: transactions.map((t) {
            final inbound = t.type == 'inbound';
            final dateStr = t.createdAt != null
                ? '${t.createdAt!.year}-${t.createdAt!.month.toString().padLeft(2, '0')}-${t.createdAt!.day.toString().padLeft(2, '0')}'
                : 'N/A';

            void openDetails() async {
              try {
                final detailedTxn = t.id != null
                    ? await TransactionService.instance.getById(t.id!)
                    : t;
                if (!context.mounted) return;
                TransactionReceiptScreen.navigateTo(context, detailedTxn);
              } catch (e) {
                if (!context.mounted) return;
                TransactionReceiptScreen.navigateTo(context, t);
              }
            }

            return DataRow(
              cells: [
                DataCell(
                  Text(t.billNo,
                      style: AppTextStyles.mono
                          .copyWith(fontWeight: FontWeight.w600)),
                  onTap: openDetails,
                ),
                DataCell(
                  StatusBadge(
                    label: inbound ? '+ Inbound' : '- Outbound',
                    tone: inbound ? BadgeTone.success : BadgeTone.danger,
                  ),
                  onTap: openDetails,
                ),
                DataCell(
                  Text('${t.totalItems}', style: AppTextStyles.bodyMedium),
                  onTap: openDetails,
                ),
                DataCell(
                  Text(dateStr,
                      style: AppTextStyles.body
                          .copyWith(color: AppColors.textSecondary)),
                  onTap: openDetails,
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
