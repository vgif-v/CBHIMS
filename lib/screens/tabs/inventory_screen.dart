import 'package:flutter/material.dart';
import '../../models/mock_data.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/buttons.dart';
import '../../widgets/section_card.dart';
import '../../widgets/status_badge.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  String _category = 'All Categories';

  static const _categories = [
    'All Categories',
    'Electronics',
    'Furniture',
    'Office Supplies',
    'Packaging'
  ];

  void _addProduct() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context){
        return const SizedBox(
          height: 400,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Text("Add New Product"),

            ]
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _category == 'All Categories'
        ? MockData.products
        : MockData.products.where((p) => p.category == _category).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(32, 28, 32, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ScreenHeader(
            title: 'Inventory',
            subtitle:
                '${MockData.products.length} products across all categories.',
            actions: [
              PrimaryButton(
                  label: 'Add New Product',
                  icon: Icons.add_rounded,
                  onPressed: _addProduct)
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _buildFilterBar(),
          const SizedBox(height: AppSpacing.lg),
          SectionCard(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.sm),
            child: _ProductTable(products: filtered),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
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
                    decoration: InputDecoration.collapsed(
                      hintText: 'Search by product name or SKU...',
                      hintStyle: AppTextStyles.body
                          .copyWith(color: AppColors.textMuted),
                    ),
                    style: AppTextStyles.body,
                  ),
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
              value: _category,
              icon: const Icon(Icons.expand_more_rounded,
                  size: 18, color: AppColors.textSecondary),
              style: AppTextStyles.body,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              items: _categories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _category = v ?? _category),
            ),
          ),
        ),
      ],
    );
  }
}

class _ProductTable extends StatelessWidget {
  final List<Product> products;
  const _ProductTable({required this.products});

  StatusBadge _statusBadge(Product p) {
    switch (p.status) {
      case StockStatus.out:
        return const StatusBadge(label: 'Out of stock', tone: BadgeTone.danger);
      case StockStatus.low:
        return const StatusBadge(label: 'Low stock', tone: BadgeTone.warning);
      case StockStatus.healthy:
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
            DataColumn(label: Text('PRODUCT')),
            DataColumn(label: Text('CATEGORY')),
            DataColumn(label: Text('IN STOCK'), numeric: true),
            DataColumn(label: Text('STATUS')),
            DataColumn(label: Text('')),
          ],
          rows: products.map((p) {
            return DataRow(cells: [
              DataCell(Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 4, bottom: 4),
                    child: SizedBox(
                      width: 200,
                      child: Text(p.name, style: AppTextStyles.bodyMedium),
                    ),
                  ),
                ],
              )),
              DataCell(Text(p.category,
                  style: AppTextStyles.body
                      .copyWith(color: AppColors.textSecondary))),
              DataCell(
                  Text('${p.quantity}', style: AppTextStyles.bodyMedium)),
              DataCell(_statusBadge(p)),
              DataCell(IconButton(
                onPressed: () {},
                icon: const Icon(Icons.more_horiz_rounded,
                    size: 19, color: AppColors.textMuted),
                splashRadius: 18,
              )),
            ]);
          }).toList(),
        ),
      ),
    );
  }
}
