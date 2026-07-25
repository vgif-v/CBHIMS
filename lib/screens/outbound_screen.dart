import 'package:flutter/material.dart';
import '../models/mock_data.dart';
import '../theme/app_theme.dart';
import '../widgets/buttons.dart';
import '../widgets/section_card.dart';
import '../widgets/status_badge.dart';

class OutboundScreen extends StatelessWidget {
  const OutboundScreen({super.key});

  BadgeTone _tone(String status) {
    switch (status) {
      case 'Delivered':
        return BadgeTone.success;
      case 'Shipped':
        return BadgeTone.info;
      default:
        return BadgeTone.warning;
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
            title: 'Outbound',
            subtitle: 'Fulfillments dispatched or in progress.',
            actions: [PrimaryButton(label: 'Create Dispatch', icon: Icons.call_made_rounded, onPressed: () {})],
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
                    DataColumn(label: Text('ORDER ID')),
                    DataColumn(label: Text('DESTINATION')),
                    DataColumn(label: Text('ITEMS'), numeric: true),
                    DataColumn(label: Text('DISPATCH DATE')),
                    DataColumn(label: Text('STATUS')),
                    DataColumn(label: Text('')),
                  ],
                  rows: MockData.outboundOrders.map((o) {
                    return DataRow(cells: [
                      DataCell(Text(o.orderId, style: AppTextStyles.mono.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600))),
                      DataCell(Text(o.destination, style: AppTextStyles.bodyMedium)),
                      DataCell(Text('${o.itemsCount}', style: AppTextStyles.bodyMedium)),
                      DataCell(Text(o.dispatchDate, style: AppTextStyles.body.copyWith(color: AppColors.textSecondary))),
                      DataCell(StatusBadge(label: o.status, tone: _tone(o.status))),
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
