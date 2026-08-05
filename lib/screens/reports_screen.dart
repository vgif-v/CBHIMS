import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/buttons.dart';
import '../widgets/section_card.dart';

class ReportTemplate {
  const ReportTemplate({required this.title, required this.description, required this.icon, required this.onDownload});

  final String title;
  final String description;
  final String icon;
  final Function() onDownload;
}

final List<ReportTemplate> reportTemplates = [
    const ReportTemplate(title: 'Inventory Valuation Report', description: 'Current stock value by category and location.', icon: '💰', onDownload: downloadInventoryReport),
    const ReportTemplate(title: 'Low Stock Summary', description: 'Items at or below their reorder point.', icon: '⚠️', onDownload: downloadLowStockSummary),
    const ReportTemplate(title: 'Dead Stock Analysis', description: 'Products with no movement in 90+ days.', icon: '📉', onDownload: downloadDeadStockAnalysis),
];

void downloadInventoryReport() {
  // Implement the logic to download the inventory report
  print('Downloading Inventory Valuation Report...');
}

void downloadLowStockSummary() {
  // Implement the logic to download the low stock summary
  print('Downloading Low Stock Summary...');
}

void downloadDeadStockAnalysis() {
  // Implement the logic to download the dead stock analysis
  print('Downloading Dead Stock Analysis...');
}

void onDownloadReport(ReportTemplate report) {
  report.onDownload();
}

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(32, 28, 32, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ScreenHeader(
            title: 'Reports',
            subtitle: 'Generate and export reports from your inventory data.',
          ),
          const SizedBox(height: AppSpacing.lg),
          _buildDateRangeBar(),
          const SizedBox(height: AppSpacing.lg),
          Text('Report Templates', style: AppTextStyles.h3),
          const SizedBox(height: AppSpacing.md),
          LayoutBuilder(
            builder: (context, constraints) {
              int cols = 1;
              if (constraints.maxWidth > 1100) {
                cols = 3;
              } else if (constraints.maxWidth > 700) {
                cols = 2;
              }
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: reportTemplates.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: cols,
                  crossAxisSpacing: AppSpacing.md,
                  mainAxisSpacing: AppSpacing.md,
                  childAspectRatio: 1.75,
                ),
                itemBuilder: (context, i) => _ReportCard(report: reportTemplates[i]),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDateRangeBar() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return constraints.maxWidth > 700 // Use the max width from constraints
          ? SectionCard(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          child: Row(
            children: [
              const Icon(Icons.date_range_rounded, size: 18, color: AppColors.textSecondary),
              const SizedBox(width: 10),
              Text('Date range:', style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
              const SizedBox(width: 8),
              _datePill('Jul 01, 2026'),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_rounded, size: 14, color: AppColors.textMuted),
              const SizedBox(width: 8),
              _datePill('Jul 25, 2026'),
              const Spacer(),
              SecondaryButton(label: 'Export CSV', icon: Icons.table_chart_outlined, onPressed: () {}),
              const SizedBox(width: AppSpacing.sm),
              PrimaryButton(label: 'Export PDF', icon: Icons.picture_as_pdf_outlined, onPressed: () {}),
            ],
          ),
        )
        :
        SectionCard(
          padding: const EdgeInsets.fromLTRB(12, AppSpacing.md, 16, AppSpacing.md),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.date_range_rounded, size: 18, color: AppColors.textSecondary),
                  const SizedBox(width: 10),
                  Text('Date range:', style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
                  const SizedBox(width: 8),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _datePill('Jul 01, 2026'),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded, size: 14, color: AppColors.textMuted),
                  const SizedBox(width: 8),
                  _datePill('Jul 25, 2026'),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SecondaryButton(label: 'Export CSV', icon: Icons.table_chart_outlined, onPressed: () {}),
                  const SizedBox(width: AppSpacing.sm),
                  PrimaryButton(label: 'Export PDF', icon: Icons.picture_as_pdf_outlined, onPressed: () {}),
                ]
              ),
            ],
          ),
        );
      }
    );
  }

  Widget _datePill(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(label, style: AppTextStyles.bodyMedium),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final ReportTemplate report;
  
  const _ReportCard({required this.report});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(AppRadius.sm)),
            child: Text(report.icon, style: const TextStyle(fontSize: 18)),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(report.title, style: AppTextStyles.bodyMedium),
          const SizedBox(height: 4),
          Expanded(
            child: Text(
              report.description,
              style: AppTextStyles.caption,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          GestureDetector(
            onTap: report.onDownload,
            child: Row(
              children: [
                const Icon(Icons.download_rounded, size: 15, color: Color.fromARGB(255, 88, 73, 255)),
                const SizedBox(width: 6),
                Text('Download', style: AppTextStyles.caption.copyWith(color: const Color.fromARGB(255, 88, 73, 255), fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
