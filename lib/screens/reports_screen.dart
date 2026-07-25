import 'package:flutter/material.dart';
import '../models/mock_data.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/buttons.dart';
import '../widgets/section_card.dart';

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
                itemCount: MockData.reportTemplates.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: cols,
                  crossAxisSpacing: AppSpacing.md,
                  mainAxisSpacing: AppSpacing.md,
                  childAspectRatio: 1.75,
                ),
                itemBuilder: (context, i) => _ReportCard(report: MockData.reportTemplates[i]),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDateRangeBar() {
    return SectionCard(
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
          Row(
            children: [
              Icon(Icons.download_rounded, size: 15, color: AppColors.primary),
              const SizedBox(width: 6),
              Text('Download', style: AppTextStyles.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }
}
