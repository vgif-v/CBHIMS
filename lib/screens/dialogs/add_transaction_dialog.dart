import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/product.dart';
import '../../models/transaction.dart';
import '../../models/transaction_item.dart';
import '../../services/auth_service.dart';
import '../../services/product_service.dart';
import '../../services/transaction_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/notification_banner.dart';
import '../transaction_receipt_screen.dart';

class _TxnItemRow {
  final Key key = UniqueKey();
  Product? selectedProduct;
  final TextEditingController quantityController;

  _TxnItemRow({int initialQty = 1})
      : quantityController = TextEditingController(text: '$initialQty');

  void dispose() {
    quantityController.dispose();
  }
}

/// A dialog to record or edit an Inbound/Outbound Stock Transaction.
///
/// Pass [existingTransaction] to open in edit mode: fields are pre-filled
/// and submitting calls [TransactionService.update] instead of
/// [TransactionService.create]. Editing does not change product stock —
/// use the separate cancel flow to reverse stock.
class AddTransactionDialog extends StatefulWidget {
  final Transaction? existingTransaction;

  const AddTransactionDialog({super.key, this.existingTransaction});

  /// Shows the dialog in create mode. Returns `true` if a transaction was created.
  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AddTransactionDialog(),
    );
  }

  /// Shows the dialog in edit mode for an existing transaction.
  /// Returns `true` if the transaction was updated.
  static Future<bool?> showEdit(BuildContext context, Transaction transaction) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AddTransactionDialog(existingTransaction: transaction),
    );
  }

  @override
  State<AddTransactionDialog> createState() => _AddTransactionDialogState();
}

class _AddTransactionDialogState extends State<AddTransactionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _billNoController = TextEditingController();
  final _remarksController = TextEditingController();
  final _issuedToController = TextEditingController();

  String _type = 'inbound'; // 'inbound' or 'outbound'
  String _status = 'Completed'; // 'Completed' or 'Pending'
  List<Product> _allProducts = [];
  bool _loadingProducts = true;
  bool _submitting = false;

  final List<_TxnItemRow> _itemRows = [];

  bool get _isEditMode => widget.existingTransaction != null;

  @override
  void initState() {
    super.initState();

    final existing = widget.existingTransaction;
    if (existing != null) {
      _billNoController.text = existing.billNo;
      _type = existing.type;
      _status = existing.status;
      _remarksController.text =
          (existing.remarks != null && existing.remarks != 'N/A')
              ? existing.remarks!
              : '';
      _issuedToController.text =
          (existing.issuedTo != null && existing.issuedTo != 'N/A')
              ? existing.issuedTo!
              : '';
    } else {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _billNoController.text = 'BILL-$timestamp';
    }

    _loadProducts();
  }

  @override
  void dispose() {
    _billNoController.dispose();
    _remarksController.dispose();
    _issuedToController.dispose();
    for (var item in _itemRows) {
      item.dispose();
    }
    super.dispose();
  }

  Future<void> _loadProducts() async {
    try {
      final products = await ProductService.instance.getAll();
      if (!mounted) return;
      setState(() {
        _allProducts = products;
        _loadingProducts = false;

        if (_itemRows.isEmpty) {
          final existing = widget.existingTransaction;
          if (existing != null && existing.items.isNotEmpty) {
            // Pre-fill rows from the existing transaction's items.
            for (final item in existing.items) {
              final row = _TxnItemRow(initialQty: item.quantity);
              if (item.productId != null) {
                for (final p in products) {
                  if (p.id == item.productId) {
                    row.selectedProduct = p;
                    break;
                  }
                }
              }
              _itemRows.add(row);
            }
          } else {
            _addItemRow();
          }
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingProducts = false);
    }
  }

  void _addItemRow() {
    setState(() {
      _itemRows.add(_TxnItemRow());
    });
  }

  void _removeItemRow(int index) {
    if (_itemRows.length <= 1) return;
    setState(() {
      final removed = _itemRows.removeAt(index);
      removed.dispose();
    });
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final validItems = <TransactionItem>[];
    for (int i = 0; i < _itemRows.length; i++) {
      final row = _itemRows[i];
      if (row.selectedProduct == null) {
        NotificationBanner.show(
          context,
          'Please select a product for item #${i + 1}.',
          tone: NotificationTone.warning,
        );
        return;
      }

      final qty = int.tryParse(row.quantityController.text.trim()) ?? 0;
      if (qty <= 0) {
        NotificationBanner.show(
          context,
          'Quantity for ${row.selectedProduct!.productName} must be greater than 0.',
          tone: NotificationTone.warning,
        );
        return;
      }

      if (!_isEditMode &&
          _type == 'outbound' &&
          qty > row.selectedProduct!.quantity) {
        NotificationBanner.show(
          context,
          'Warning: ${row.selectedProduct!.productName} only has ${row.selectedProduct!.quantity} in stock.',
          tone: NotificationTone.warning,
        );
      }

      validItems.add(TransactionItem(
        productId: row.selectedProduct!.id,
        productName: row.selectedProduct!.productName,
        quantity: qty,
      ));
    }

    setState(() => _submitting = true);
    try {
      if (_isEditMode) {
        final updatedTxn = await TransactionService.instance.update(
          transactionId: widget.existingTransaction!.id!,
          billNo: _billNoController.text.trim(),
          type: _type,
          status: _status,
          items: validItems,
          remarks: _remarksController.text.trim(),
          issuedTo: _issuedToController.text.trim(),
        );

        if (!mounted) return;
        NotificationBanner.show(
          context,
          'Transaction updated successfully!',
          tone: NotificationTone.success,
        );
        Navigator.of(context).pop(true);
        TransactionReceiptScreen.navigateTo(context, updatedTxn);
      } else {
        final currentUserId = AuthService.instance.userId;

        final createdTxn = await TransactionService.instance.create(
          billNo: _billNoController.text.trim(),
          type: _type,
          status: _status,
          items: validItems,
          remarks: _remarksController.text.trim(),
          issuedTo: _issuedToController.text.trim(),
          userId: currentUserId,
        );

        if (!mounted) return;
        NotificationBanner.show(
          context,
          'Transaction created successfully!',
          tone: NotificationTone.success,
        );
        Navigator.of(context).pop(true);
        TransactionReceiptScreen.navigateTo(context, createdTxn);
      }
    } catch (e, st) {
      debugPrint('[AddTransactionDialog] Error saving transaction: $e\n$st');
      if (!mounted) return;
      NotificationBanner.show(
        context,
        'Failed to save transaction: $e',
        tone: NotificationTone.error,
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final dialogWidth = width > 720 ? 660.0 : width * 0.94;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: dialogWidth,
        constraints: const BoxConstraints(maxHeight: 740),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 40,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            const Divider(height: 1, color: AppColors.border),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(28, 20, 28, 8),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Bill No & Type Row
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: _buildField(
                              label: 'Bill No. / Reference',
                              child: TextFormField(
                                controller: _billNoController,
                                style: AppTextStyles.body
                                    .copyWith(color: AppColors.textPrimary),
                                decoration: _inputDecoration('e.g. BILL-1001'),
                                validator: (v) => v == null || v.trim().isEmpty
                                    ? 'Required'
                                    : null,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 2,
                            child: _buildField(
                              label: 'Transaction Type',
                              child: DropdownButtonFormField<String>(
                                initialValue: _type,
                                decoration: _inputDecoration(''),
                                style: AppTextStyles.body
                                    .copyWith(color: AppColors.textPrimary),
                                borderRadius: BorderRadius.circular(12),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'inbound',
                                    child: Row(
                                      children: [
                                        Icon(Icons.arrow_downward_rounded,
                                            size: 16, color: AppColors.success),
                                        SizedBox(width: 6),
                                        Text('Inbound (+)'),
                                      ],
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: 'outbound',
                                    child: Row(
                                      children: [
                                        Icon(Icons.arrow_upward_rounded,
                                            size: 16, color: AppColors.danger),
                                        SizedBox(width: 6),
                                        Text('Outbound (-)'),
                                      ],
                                    ),
                                  ),
                                ],
                                onChanged: (v) =>
                                    setState(() => _type = v ?? 'inbound'),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // Status & Remarks Row
                      Row(
                        children: [
                          Expanded(
                            child: _buildField(
                              label: 'Status',
                              child: DropdownButtonFormField<String>(
                                initialValue: _status,
                                decoration: _inputDecoration(''),
                                style: AppTextStyles.body
                                    .copyWith(color: AppColors.textPrimary),
                                borderRadius: BorderRadius.circular(12),
                                items: [
                                  const DropdownMenuItem(
                                      value: 'Completed',
                                      child: Text('Completed')),
                                  const DropdownMenuItem(
                                      value: 'Pending', child: Text('Pending')),
                                  // Cancelled is only offered in edit mode —
                                  // choosing it here does NOT reverse stock.
                                  // Use the dedicated Cancel action for that.
                                  if (_isEditMode)
                                    const DropdownMenuItem(
                                        value: 'Cancelled',
                                        child: Text('Cancelled')),
                                ],
                                onChanged: (v) =>
                                    setState(() => _status = v ?? 'Completed'),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildField(
                              label: 'Remarks (Optional)',
                              child: TextFormField(
                                controller: _remarksController,
                                style: AppTextStyles.body
                                    .copyWith(color: AppColors.textPrimary),
                                decoration: _inputDecoration('Notes / Purpose'),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_isEditMode &&
                          widget.existingTransaction!.status.toLowerCase() !=
                              'cancelled') ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.warningSoft,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline_rounded,
                                  size: 16, color: AppColors.warning),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Setting status to Cancelled will reverse this '
                                  'transaction\'s stock impact when you save.',
                                  style: AppTextStyles.caption,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 18),
                      _buildField(
                        label: 'Issued To / Recipient Name',
                        child: TextFormField(
                          controller: _issuedToController,
                          style: AppTextStyles.body
                              .copyWith(color: AppColors.textPrimary),
                          decoration: _inputDecoration(
                              'e.g. John Doe, Construction Site A, Contractor'),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Item List Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Items in Transaction', style: AppTextStyles.h3),
                          TextButton.icon(
                            onPressed: _addItemRow,
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: Text('Add Another Item',
                                style: AppTextStyles.bodyMedium
                                    .copyWith(color: AppColors.primary)),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      if (_loadingProducts)
                        const Padding(
                          padding: EdgeInsets.all(24.0),
                          child: Center(
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else if (_allProducts.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.warningSoft,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.warning_amber_rounded,
                                  color: AppColors.warning),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'No products found in inventory. Please add products first before creating a transaction.',
                                  style: AppTextStyles.body,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        ..._itemRows.asMap().entries.map((entry) {
                          final i = entry.key;
                          final row = entry.value;

                          final selectedProduct = row.selectedProduct != null
                              ? _allProducts.firstWhere(
                                  (p) => p.id == row.selectedProduct!.id,
                                  orElse: () => row.selectedProduct!,
                                )
                              : null;

                          return Container(
                            key: row.key,
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 4,
                                  child: DropdownButtonFormField<Product>(
                                    initialValue: selectedProduct,
                                    isExpanded: true,
                                    decoration:
                                        _inputDecoration('Select product'),
                                    style: AppTextStyles.body
                                        .copyWith(color: AppColors.textPrimary),
                                    borderRadius: BorderRadius.circular(12),
                                    items: _allProducts
                                        .map((p) => DropdownMenuItem<Product>(
                                              value: p,
                                              child: Text(
                                                '${p.productName} (${p.quantity} ${p.unit} in stock)',
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ))
                                        .toList(),
                                    onChanged: (v) =>
                                        setState(() => row.selectedProduct = v),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                SizedBox(
                                  width: 90,
                                  child: TextFormField(
                                    controller: row.quantityController,
                                    style: AppTextStyles.body
                                        .copyWith(color: AppColors.textPrimary),
                                    decoration: _inputDecoration('Qty'),
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly
                                    ],
                                  ),
                                ),
                                if (_itemRows.length > 1) ...[
                                  const SizedBox(width: 4),
                                  IconButton(
                                    onPressed: () => _removeItemRow(i),
                                    icon: const Icon(
                                        Icons.delete_outline_rounded,
                                        color: AppColors.danger,
                                        size: 20),
                                    splashRadius: 18,
                                    tooltip: 'Remove row',
                                  ),
                                ],
                              ],
                            ),
                          );
                        }),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
            const Divider(height: 1, color: AppColors.border),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 22, 16, 16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
                _isEditMode ? Icons.edit_rounded : Icons.swap_horiz_rounded,
                color: AppColors.primary,
                size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_isEditMode ? 'Edit Transaction' : 'Add New Transaction',
                    style: AppTextStyles.h3),
                const SizedBox(height: 2),
                Text(
                    _isEditMode
                        ? 'Update this transaction\'s details.'
                        : 'Record stock movement (Inbound or Outbound).',
                    style: AppTextStyles.caption),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(false),
            icon: const Icon(Icons.close_rounded,
                color: AppColors.textMuted, size: 20),
            splashRadius: 18,
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 14, 28, 18),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 46,
              child: OutlinedButton(
                onPressed:
                    _submitting ? null : () => Navigator.of(context).pop(false),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                  side: const BorderSide(color: AppColors.border),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('Cancel', style: AppTextStyles.bodyMedium),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SizedBox(
              height: 46,
              child: ElevatedButton(
                onPressed: _submitting ? null : _handleSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      AppColors.primary.withValues(alpha: 0.6),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        _isEditMode ? 'Save Changes' : 'Save Transaction',
                        style: AppTextStyles.bodyMedium
                            .copyWith(color: Colors.white)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.label),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: AppTextStyles.body.copyWith(color: AppColors.textMuted),
      filled: true,
      fillColor: AppColors.background,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.danger),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
      ),
    );
  }
}