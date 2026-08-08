import 'package:flutter/material.dart';
import '../../models/product.dart';
import '../../models/category.dart';
import '../../services/product_service.dart';
import '../../services/category_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/buttons.dart';
import '../../widgets/notification_banner.dart';
import '../../widgets/section_card.dart';
import '../../widgets/status_badge.dart';
import '../dialogs/add_product_dialog.dart';
import '../dialogs/edit_product_dialog.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Product> _products = [];
  List<Category> _categories = [];
  String _selectedCategory = 'All Categories';
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final productsFuture = ProductService.instance.getAll();
      final categoriesFuture = CategoryService.instance.getAll();

      final results = await Future.wait([productsFuture, categoriesFuture]);

      if (!mounted) return;
      setState(() {
        _products = results[0] as List<Product>;
        _categories = results[1] as List<Category>;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _onAddProduct() {
    AddProductDialog.show(
      context,
      onProductAdded: () {
        _loadData();
      },
    );
  }

  Future<void> _onEditProduct(Product p) async {
    final updated = await EditProductDialog.show(context, p);
    if (updated == true) {
      _loadData();
    }
  }

  Future<void> _onDeleteProduct(Product p) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete Product', style: AppTextStyles.h3),
        content: Text(
          'Are you sure you want to delete "${p.productName}"?',
          style: AppTextStyles.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancel', style: AppTextStyles.bodyMedium),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && p.id != null) {
      try {
        await ProductService.instance.delete(p.id!);
        if (!mounted) return;
        NotificationBanner.show(
          context,
          'Product "${p.productName}" deleted.',
          tone: NotificationTone.success,
        );
        _loadData();
      } catch (e) {
        if (!mounted) return;
        NotificationBanner.show(
          context,
          'Failed to delete product: $e',
          tone: NotificationTone.error,
        );
      }
    }
  }

  List<Product> get _filteredProducts {
    final query = _searchController.text.trim().toLowerCase();
    return _products.where((p) {
      final matchesCategory = _selectedCategory == 'All Categories' ||
          p.categoryName == _selectedCategory;
      final matchesQuery = query.isEmpty ||
          p.productName.toLowerCase().contains(query);
      return matchesCategory && matchesQuery;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredProducts;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(32, 28, 32, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ScreenHeader(
            title: 'Inventory',
            subtitle: _loading
                ? 'Loading products...'
                : '${_products.length} products in stock',
            actions: [
              PrimaryButton(
                label: 'Add New Product',
                icon: Icons.add_rounded,
                onPressed: _onAddProduct,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _buildFilterBar(),
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
                              Text('Failed to load products',
                                  style: AppTextStyles.h3),
                              const SizedBox(height: 8),
                              Text(_error!,
                                  style: AppTextStyles.caption
                                      .copyWith(color: AppColors.danger)),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _loadData,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : filtered.isEmpty
                        ? SizedBox(
                            height: 200,
                            child: Center(
                              child: Text(
                                _products.isEmpty
                                    ? 'No products added yet. Click "Add New Product" to create one.'
                                    : 'No products match your filter criteria.',
                                style: AppTextStyles.body
                                    .copyWith(color: AppColors.textSecondary),
                              ),
                            ),
                          )
                        : _ProductTable(
                            products: filtered,
                            onEdit: _onEditProduct,
                            onDelete: _onDeleteProduct,
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    final categoryOptions = [
      'All Categories',
      ..._categories.map((c) => c.name),
    ];

    return Row(
      children: [
        Expanded(
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.search_rounded,
                    size: 18, color: AppColors.textMuted),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration.collapsed(
                      hintText: 'Search product name...',
                      hintStyle: AppTextStyles.body
                          .copyWith(color: AppColors.textMuted),
                    ),
                    style: AppTextStyles.body,
                  ),
                ),
                if (_searchController.text.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      _searchController.clear();
                      setState(() {});
                    },
                    child: const Icon(Icons.close_rounded,
                        size: 18, color: AppColors.textMuted),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(color: AppColors.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: categoryOptions.contains(_selectedCategory)
                  ? _selectedCategory
                  : 'All Categories',
              icon: const Icon(Icons.expand_more_rounded,
                  size: 18, color: AppColors.textSecondary),
              style: AppTextStyles.body,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              items: categoryOptions
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) =>
                  setState(() => _selectedCategory = v ?? 'All Categories'),
            ),
          ),
        ),
      ],
    );
  }
}

class _ProductTable extends StatelessWidget {
  final List<Product> products;
  final Function(Product) onEdit;
  final Function(Product) onDelete;

  const _ProductTable({
    required this.products,
    required this.onEdit,
    required this.onDelete,
  });

  StatusBadge _statusBadge(Product p) {
    if (p.quantity <= 0) {
      return const StatusBadge(label: 'Out of stock', tone: BadgeTone.danger);
    } else if (p.quantity <= 10) {
      return const StatusBadge(label: 'Low stock', tone: BadgeTone.warning);
    } else {
      return const StatusBadge(label: 'Healthy', tone: BadgeTone.success);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 680),
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(Colors.transparent),
          dividerThickness: 1,
          dataRowMaxHeight: double.infinity,
          columnSpacing: 28,
          horizontalMargin: 4,
          headingTextStyle: AppTextStyles.label,
          dataTextStyle: AppTextStyles.body,
          columns: const [
            DataColumn(label: Text('PRODUCT NAME')),
            DataColumn(label: Text('CATEGORY')),
            DataColumn(label: Text('IN STOCK'), numeric: true),
            DataColumn(label: Text('STATUS')),
            DataColumn(label: Text('ACTIONS')),
          ],
          rows: products.map((p) {
            return DataRow(cells: [
              DataCell(
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: SizedBox(
                    width: 240,
                    child: Text(p.productName, style: AppTextStyles.bodyMedium),
                  ),
                ),
              ),
              DataCell(Text(p.categoryName ?? 'Uncategorized',
                  style: AppTextStyles.body
                      .copyWith(color: AppColors.textSecondary))),
              DataCell(
                  Text('${p.quantity} ${p.unit}', style: AppTextStyles.bodyMedium)),
              DataCell(_statusBadge(p)),
              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () => onEdit(p),
                      icon: const Icon(Icons.edit_outlined,
                          size: 18, color: AppColors.primary),
                      splashRadius: 18,
                      tooltip: 'Edit',
                    ),
                    IconButton(
                      onPressed: () => onDelete(p),
                      icon: const Icon(Icons.delete_outline_rounded,
                          size: 18, color: AppColors.danger),
                      splashRadius: 18,
                      tooltip: 'Delete',
                    ),
                  ],
                ),
              ),
            ]);
          }).toList(),
        ),
      ),
    );
  }
}
