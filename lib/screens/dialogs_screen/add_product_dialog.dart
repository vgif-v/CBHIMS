import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/product.dart';
import '../../services/product_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/notification_banner.dart';

/// A dialog for adding new products to the inventory.
/// Stays open after submission to allow adding multiple products sequentially,
/// showing a green toaster notification, clearing input fields, and resetting the category dropdown.
class AddProductDialog extends StatefulWidget {
  final VoidCallback? onProductAdded;

  const AddProductDialog({super.key, this.onProductAdded});

  /// Shows the dialog. Pass [onProductAdded] to refresh table data in the background.
  static Future<void> show(BuildContext context,
      {VoidCallback? onProductAdded}) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => AddProductDialog(onProductAdded: onProductAdded),
    );
  }

  @override
  State<AddProductDialog> createState() => _AddProductDialogState();
}

class _AddProductDialogState extends State<AddProductDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController(text: '0');
  final _newCategoryController = TextEditingController();
  final _remarksController = TextEditingController();

  String _selectedUnit = 'pcs';
  bool _loading = false;

  static const _units = [
    'pcs',
    'kg',
    'box',
    'pack',
    'meter',
    'set',
    'roll',
    'pair',
    'liter',
    'bag'
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _newCategoryController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  void _resetForm() {
    _nameController.clear();
    _quantityController.text = '0';
    _newCategoryController.clear();
    _remarksController.clear();
    setState(() {
      _selectedUnit = 'pcs';
    });
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      final product = Product(
        productName: _nameController.text.trim(),
        quantity: int.tryParse(_quantityController.text.trim()) ?? 0,
        unit: _selectedUnit,
        remarks: _remarksController.text.trim(),
      );

      await ProductService.instance.add(product);
      if (!mounted) return;

      // 1. Show notification banner
      NotificationBanner.show(
        context,
        'Product added successfully!',
        tone: NotificationTone.success,
      );

      // 2. Reset fields and category
      _resetForm();

      // 3. Trigger parent callback to refresh table behind dialog
      widget.onProductAdded?.call();
    } catch (e) {
      if (!mounted) return;
      NotificationBanner.show(
        context,
        'Failed to add product: $e',
        tone: NotificationTone.error,
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final dialogWidth = width > 600 ? 520.0 : width * 0.92;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: dialogWidth,
        constraints: const BoxConstraints(maxHeight: 620),
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
                      _buildField(
                        label: 'Product Name',
                        child: TextFormField(
                          controller: _nameController,
                          style: AppTextStyles.body
                              .copyWith(color: AppColors.textPrimary),
                          decoration: _inputDecoration('e.g. Portland Cement'),
                          validator: (v) =>
                              v == null || v.trim().isEmpty ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: _buildField(
                              label: 'Quantity',
                              child: TextFormField(
                                controller: _quantityController,
                                style: AppTextStyles.body
                                    .copyWith(color: AppColors.textPrimary),
                                decoration: _inputDecoration('0'),
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly
                                ],
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return 'Required';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildField(
                              label: 'Unit',
                              child: DropdownButtonFormField<String>(
                                initialValue: _selectedUnit,
                                decoration: _inputDecoration(''),
                                style: AppTextStyles.body
                                    .copyWith(color: AppColors.textPrimary),
                                borderRadius: BorderRadius.circular(12),
                                items: _units
                                    .map((u) => DropdownMenuItem(
                                        value: u, child: Text(u)))
                                    .toList(),
                                onChanged: (v) =>
                                    setState(() => _selectedUnit = v ?? 'pcs'),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      _buildField(
                        label: 'Remarks / Notes (Optional)',
                        child: TextFormField(
                          controller: _remarksController,
                          style: AppTextStyles.body
                              .copyWith(color: AppColors.textPrimary),
                          decoration: _inputDecoration(
                              'e.g. Supplier info, specs, or location'),
                        ),
                      ),
                      const SizedBox(height: 24),
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
            child: const Icon(Icons.add_box_rounded,
                color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Add New Product', style: AppTextStyles.h3),
                const SizedBox(height: 2),
                Text(
                    'Fill in product details. Dialog stays open to add multiple items.',
                    style: AppTextStyles.caption),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
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
                onPressed: _loading ? null : () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                  side: const BorderSide(color: AppColors.border),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('Done / Close', style: AppTextStyles.bodyMedium),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SizedBox(
              height: 46,
              child: ElevatedButton(
                onPressed: _loading ? null : _handleSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      AppColors.primary.withValues(alpha: 0.6),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text('Add Product',
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
