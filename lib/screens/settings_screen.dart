import 'package:flutter/material.dart';
import '../models/mock_data.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/buttons.dart';
import '../widgets/section_card.dart';
import '../widgets/status_badge.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _tab = 0;
  bool _lowStockAlerts = true;
  bool _inboundNotices = true;
  bool _emailSummaries = false;

  static const _tabs = ['General', 'Notifications', 'User Management'];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(32, 28, 32, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ScreenHeader(title: 'Settings', subtitle: 'Manage your workspace preferences and team.'),
          const SizedBox(height: AppSpacing.lg),
          _buildTabBar(),
          const SizedBox(height: AppSpacing.lg),
          if (_tab == 0) _buildGeneral(),
          if (_tab == 1) _buildNotifications(),
          if (_tab == 2) _buildUserManagement(),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < _tabs.length; i++)
            GestureDetector(
              onTap: () => setState(() => _tab = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  color: _tab == i ? AppColors.primarySoft : Colors.transparent,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Text(
                  _tabs[i],
                  style: AppTextStyles.bodyMedium.copyWith(color: _tab == i ? AppColors.primary : AppColors.textSecondary),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGeneral() {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('General', style: AppTextStyles.h3),
          const SizedBox(height: 4),
          Text('Basic information about your workspace.', style: AppTextStyles.caption),
          const SizedBox(height: AppSpacing.lg),
          _labeledField('App Name', 'Stockpile Warehouse'),
          const SizedBox(height: AppSpacing.md),
          _labeledDropdown('Default Currency', 'USD — US Dollar', ['USD — US Dollar', 'EUR — Euro', 'GBP — British Pound', 'PHP — Philippine Peso']),
          const SizedBox(height: AppSpacing.md),
          _labeledDropdown('Timezone', 'Asia/Manila (GMT+8)', ['Asia/Manila (GMT+8)', 'America/New_York (GMT-4)', 'Europe/London (GMT+1)']),
          const SizedBox(height: AppSpacing.lg),
          Align(alignment: Alignment.centerLeft, child: PrimaryButton(label: 'Save Changes', onPressed: () {})),
        ],
      ),
    );
  }

  Widget _labeledField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.label),
        const SizedBox(height: 8),
        Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(children: [Expanded(child: Text(value, style: AppTextStyles.body))]),
        ),
      ],
    );
  }

  Widget _labeledDropdown(String label, String value, List<String> options) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.label),
        const SizedBox(height: 8),
        Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(color: AppColors.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              icon: const Icon(Icons.expand_more_rounded, size: 18, color: AppColors.textSecondary),
              style: AppTextStyles.body,
              items: options.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
              onChanged: (_) {},
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNotifications() {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Notifications', style: AppTextStyles.h3),
          const SizedBox(height: 4),
          Text('Choose what you want to be notified about.', style: AppTextStyles.caption),
          const SizedBox(height: AppSpacing.lg),
          _toggleRow(
            title: 'Low Stock Alerts',
            subtitle: 'Get notified when a product falls below its reorder point.',
            value: _lowStockAlerts,
            onChanged: (v) => setState(() => _lowStockAlerts = v),
          ),
          const Divider(height: AppSpacing.xl),
          _toggleRow(
            title: 'Inbound Arrival Notices',
            subtitle: 'Get notified when a purchase order is received.',
            value: _inboundNotices,
            onChanged: (v) => setState(() => _inboundNotices = v),
          ),
          const Divider(height: AppSpacing.xl),
          _toggleRow(
            title: 'Email Summaries',
            subtitle: 'Receive a daily digest of warehouse activity by email.',
            value: _emailSummaries,
            onChanged: (v) => setState(() => _emailSummaries = v),
          ),
        ],
      ),
    );
  }

  Widget _toggleRow({required String title, required String subtitle, required bool value, required ValueChanged<bool> onChanged}) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.bodyMedium),
              const SizedBox(height: 3),
              Text(subtitle, style: AppTextStyles.caption),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: Colors.white,
          activeTrackColor: AppColors.primary,
          inactiveThumbColor: Colors.white,
          inactiveTrackColor: AppColors.border,
        ),
      ],
    );
  }

  Widget _buildUserManagement() {
    return SectionCard(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('User Management', style: AppTextStyles.h3),
                  const SizedBox(height: 4),
                  Text('${MockData.team.length} team members.', style: AppTextStyles.caption),
                ],
              ),
              PrimaryButton(label: 'Invite Member', icon: Icons.person_add_alt_rounded, onPressed: () {}),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          ...MockData.team.map((m) => _TeamMemberRow(member: m)),
        ],
      ),
    );
  }
}

class _TeamMemberRow extends StatelessWidget {
  final TeamMember member;
  const _TeamMemberRow({required this.member});

  BadgeTone get _tone {
    switch (member.role) {
      case 'Admin':
        return BadgeTone.info;
      case 'Manager':
        return BadgeTone.success;
      default:
        return BadgeTone.neutral;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.neutralSoft,
            child: Text(member.initials, style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(member.name, style: AppTextStyles.bodyMedium),
                Text(member.email, style: AppTextStyles.caption),
              ],
            ),
          ),
          StatusBadge(label: member.role, tone: _tone),
          const SizedBox(width: 12),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.more_horiz_rounded, size: 19, color: AppColors.textMuted),
            splashRadius: 18,
          ),
        ],
      ),
    );
  }
}
