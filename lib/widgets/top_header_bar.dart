import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class TopHeaderBar extends StatelessWidget {
  final String title;
  final String subtitle;

  const TopHeaderBar({super.key, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.h1),
              const SizedBox(height: 4),
              Text(subtitle, style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.lg),
        const _SearchField(),
        const SizedBox(width: AppSpacing.md),
        const _NotificationBell(),
        const SizedBox(width: AppSpacing.md),
        const CircleAvatar(
          radius: 19,
          backgroundColor: AppColors.primary,
          child: Text('AT', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, size: 18, color: AppColors.textMuted),
          const SizedBox(width: 8),
          Expanded(
            child: Text('Search products, SKUs...', style: AppTextStyles.body.copyWith(color: AppColors.textMuted)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(5),
              border: Border.all(color: AppColors.border),
            ),
            child: Text('⌘K', style: AppTextStyles.caption.copyWith(fontSize: 11, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _NotificationBell extends StatelessWidget {
  const _NotificationBell();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.border),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Icon(Icons.notifications_none_rounded, size: 20, color: AppColors.textSecondary),
          Positioned(
            top: 10,
            right: 11,
            child: Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(color: AppColors.danger, shape: BoxShape.circle),
            ),
          ),
        ],
      ),
    );
  }
}
