import 'package:flutter/material.dart';
import '../../models/mock_data.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/buttons.dart';
import '../../widgets/section_card.dart';
import '../../widgets/status_badge.dart';

class TransactionsScreen extends StatelessWidget {
  const TransactionsScreen({super.key});

  BadgeTone _tone(String status) {
    switch (status) {
      case 'Received':
        return BadgeTone.success;
      case 'In-Transit':
        return BadgeTone.info;
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
            subtitle: 'View and manage all stock transactions',
            actions: [PrimaryButton(label: 'Add Stock', icon: Icons.add_rounded, onPressed: () {})],
          ),
          const SizedBox(height: AppSpacing.lg),
          SectionCard(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.sm),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 820),
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(Colors.transparent),
                  dividerThickness: 0.6,
                  columnSpacing: 32,
                  horizontalMargin: 4,
                  headingTextStyle: AppTextStyles.label,
                  dataTextStyle: AppTextStyles.body,
                  columns: const [
                    DataColumn(label: Text('BILL NO.')),
                    DataColumn(label: Text('NAME')),
                    DataColumn(label: Text('TOTAL ITEMS'), numeric: true),
                    DataColumn(label: Text('STATUS')),
                    DataColumn(label: Text('')),
                  ],
                  rows: MockData.purchaseOrders.map((po) {
                    return DataRow(cells: [
                      DataCell(Text(po.poNumber, style: AppTextStyles.mono.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600))),
                      DataCell(Text(po.supplier, style: AppTextStyles.bodyMedium)),
                      DataCell(Text('${po.totalItems}', style: AppTextStyles.bodyMedium)),
                      DataCell(StatusBadge(label: po.status, tone: _tone(po.status))),
                      DataCell(IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.more_horiz_rounded, size: 19, color: AppColors.textMuted),
                        splashRadius: 18,
                      )),
                    ]);
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
