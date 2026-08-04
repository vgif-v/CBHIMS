import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/mock_data.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/section_card.dart';
import '../widgets/stat_card.dart';
import '../widgets/status_badge.dart';
import '../widgets/top_header_bar.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _rangeIndex = 1; // 0=7D, 1=30D, 2=90D

  static const List<List<double>> _rangeData = [
    [40, 55, 48, 62, 58, 70, 65],
    [30, 42, 38, 55, 48, 60, 52, 65, 58, 70, 66, 78],
    [20, 35, 28, 45, 38, 52, 44, 58, 50, 64, 56, 70, 62, 75],
  ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final horizontalPadding = width < 520 ? 16.0 : 32.0;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(horizontalPadding, 28, horizontalPadding, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TopHeaderBar(
            title: 'Dashboard',
            subtitle: 'Welcome back — here\'s what\'s happening in your warehouse.',
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
          const StatCard(
            label: 'Total Products',
            value: '12,450',
            icon: Icons.inventory_2_rounded,
            iconColor: AppColors.primary,
            iconBg: AppColors.primarySoft,
          ),
          const StatCard(
            label: 'Low Stock Alert',
            value: '14',
            icon: Icons.warning_rounded,
            iconColor: AppColors.warning,
            iconBg: AppColors.warningSoft,
            badgeText: 'Needs review',
            badgeTone: BadgeTone.warning,
          ),
          const StatCard(
            label: 'Total Inventory Value',
            value: '\$284,500.00',
            icon: Icons.payments_rounded,
            iconColor: AppColors.success,
            iconBg: AppColors.successSoft,
          ),
          const StatCard(
            label: 'Pending Inbound',
            value: '3',
            icon: Icons.call_received_rounded,
            iconColor: AppColors.textSecondary,
            iconBg: AppColors.neutralSoft,
            badgeText: 'In progress',
            badgeTone: BadgeTone.neutral,
          ),
        ];

        if (constraints.maxWidth <= 520) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (int i = 0; i < cards.length; i++) ...[
                cards[i],
                if (i != cards.length - 1) const SizedBox(height: AppSpacing.md),
              ],
            ],
          );
        }

        if (constraints.maxWidth <= 900) {
          final itemWidth = (constraints.maxWidth - AppSpacing.md) / 2;
          return Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: cards.map((c) => SizedBox(width: itemWidth, child: c)).toList(),
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
        final bool wide = constraints.maxWidth > 900;
        //final chart = _buildStockMovementChart();
        final actions = _buildQuickActions();

        if (!wide) {
          return Column(
            children: [const SizedBox(height: AppSpacing.xs), actions],
          );
        }

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              //Expanded(flex: 2, child: chart),
              const SizedBox(width: AppSpacing.md),
              Expanded(flex: 1, child: actions),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStockMovementChart() {
    final data = _rangeData[_rangeIndex];
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(builder: (context, constraints) {
            final compact = constraints.maxWidth < 360;
            return compact
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Stock Movement', style: AppTextStyles.h3),
                      const SizedBox(height: AppSpacing.sm),
                      _buildRangeToggle(),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text('Stock Movement', style: AppTextStyles.h3),
                      _buildRangeToggle(),
                    ],
                  );
          }),
          const SizedBox(height: 4),
          Text('Units moved in and out of the warehouse.', style: AppTextStyles.caption),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            height: 220,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 20,
                  getDrawingHorizontalLine: (value) => const FlLine(color: AppColors.divider, strokeWidth: 1),
                ),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineTouchData: LineTouchData(
                  handleBuiltInTouches: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => AppColors.textPrimary,
                    tooltipRoundedRadius: 8,
                    getTooltipItems: (spots) => spots
                        .map((s) => LineTooltipItem('${s.y.toInt()} units', const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)))
                        .toList(),
                  ),
                ),
                minY: 0,
                maxY: 90,
                lineBarsData: [
                  LineChartBarData(
                    spots: [for (int i = 0; i < data.length; i++) FlSpot(i.toDouble(), data[i])],
                    isCurved: true,
                    curveSmoothness: 0.3,
                    color: AppColors.primary,
                    barWidth: 2.5,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.primary.withValues(alpha: 0.14),
                          AppColors.primary.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              _legendDot(AppColors.primary, 'Units moved'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: AppTextStyles.caption),
      ],
    );
  }

  Widget _buildRangeToggle() {
    const labels = ['7D', '30D', '90D'];
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < labels.length; i++)
            GestureDetector(
              onTap: () => setState(() => _rangeIndex = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _rangeIndex == i ? AppColors.surface : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: _rangeIndex == i
                      ? [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 4, offset: const Offset(0, 1))]
                      : null,
                ),
                child: Text(
                  labels[i],
                  style: AppTextStyles.caption.copyWith(
                    color: _rangeIndex == i ? AppColors.textPrimary : AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
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
          const _QuickActionButton(
            icon: Icons.add_circle_rounded,
            label: 'Add Stock',
            iconColor: AppColors.primary,
            iconBg: AppColors.primarySoft,
          ),
          const SizedBox(height: AppSpacing.sm),
          const _QuickActionButton(
            icon: Icons.sync_alt_rounded,
            label: 'Stock Transfer',
            iconColor: AppColors.success,
            iconBg: AppColors.successSoft,
          ),
          const SizedBox(height: AppSpacing.sm),
          const _QuickActionButton(
            icon: Icons.assignment_outlined,
            label: 'Export Audit',
            iconColor: AppColors.warning,
            iconBg: AppColors.warningSoft,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTransactions(BuildContext context) {
    return SectionCard(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(builder: (context, constraints) {
            final compact = constraints.maxWidth < 420;
            return compact
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Recent Transactions', style: AppTextStyles.h3),
                      const SizedBox(height: AppSpacing.sm),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: () {},
                          style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                          child: Text('View all', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primary)),
                        ),
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Recent Transactions', style: AppTextStyles.h3),
                      TextButton(
                        onPressed: () {},
                        style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                        child: Text('View all', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primary)),
                      ),
                    ],
                  );
          }),
          const SizedBox(height: AppSpacing.sm),
          const _TransactionsTable(transactions: MockData.transactions),
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

  const _QuickActionButton({required this.icon, required this.label, required this.iconColor, required this.iconBg});

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
        onTap: () {},
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
                decoration: BoxDecoration(color: widget.iconBg, borderRadius: BorderRadius.circular(8)),
                child: Icon(widget.icon, size: 17, color: widget.iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(widget.label, style: AppTextStyles.bodyMedium)),
              const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textMuted),
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
      child: LayoutBuilder(builder: (context, constraints) {
        final minW = constraints.maxWidth < 700 ? constraints.maxWidth : 700.0;
        return ConstrainedBox(
          constraints: BoxConstraints(minWidth: minW),
          child: DataTable(
          headingRowColor: WidgetStateProperty.all(Colors.transparent),
          dividerThickness: 0.6,
          columnSpacing: 32,
          horizontalMargin: 4,
          headingTextStyle: AppTextStyles.label,
          dataTextStyle: AppTextStyles.body,
          columns: const [
            DataColumn(label: Text('ITEM NAME')),
            DataColumn(label: Text('SKU')),
            DataColumn(label: Text('TYPE')),
            DataColumn(label: Text('DATE')),
            DataColumn(label: Text('STATUS')),
          ],
          rows: transactions.map((t) {
            final inbound = t.type == TxnType.inbound;
            return DataRow(cells: [
              DataCell(Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(8)),
                    child: Text(t.emoji, style: const TextStyle(fontSize: 15)),
                  ),
                  const SizedBox(width: 10),
                  Text(t.itemName, style: AppTextStyles.bodyMedium),
                ],
              )),
              DataCell(Text(t.sku, style: AppTextStyles.mono)),
              DataCell(StatusBadge(
                label: inbound ? '+ Inbound' : '- Outbound',
                tone: inbound ? BadgeTone.success : BadgeTone.info,
              )),
              DataCell(Text(t.date, style: AppTextStyles.body.copyWith(color: AppColors.textSecondary))),
              DataCell(StatusBadge(
                label: t.status,
                tone: t.status == 'Completed' ? BadgeTone.success : BadgeTone.neutral,
              )),
            ]);
          }).toList(),
          ),
        );
      }),
    );
  }
}
