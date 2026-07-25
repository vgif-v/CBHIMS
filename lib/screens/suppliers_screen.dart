import 'package:flutter/material.dart';
import '../models/mock_data.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/buttons.dart';
import '../widgets/section_card.dart';

class SuppliersScreen extends StatelessWidget {
  const SuppliersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(32, 28, 32, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ScreenHeader(
            title: 'Suppliers',
            subtitle: '${MockData.suppliers.length} suppliers on file.',
            actions: [PrimaryButton(label: 'Add Supplier', icon: Icons.add_rounded, onPressed: () {})],
          ),
          const SizedBox(height: AppSpacing.lg),
          LayoutBuilder(
            builder: (context, constraints) {
              int cols = 1;
              if (constraints.maxWidth > 1200) {
                cols = 3;
              } else if (constraints.maxWidth > 760) {
                cols = 2;
              }
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: MockData.suppliers.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: cols,
                  crossAxisSpacing: AppSpacing.md,
                  mainAxisSpacing: AppSpacing.md,
                  childAspectRatio: 2.1,
                ),
                itemBuilder: (context, i) => _SupplierCard(supplier: MockData.suppliers[i]),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SupplierCard extends StatelessWidget {
  final Supplier supplier;
  const _SupplierCard({required this.supplier});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 21,
                backgroundColor: AppColors.primarySoft,
                child: Text(supplier.initials, style: const TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(supplier.companyName, style: AppTextStyles.bodyMedium, overflow: TextOverflow.ellipsis),
                    Text(supplier.contactPerson, style: AppTextStyles.caption),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _infoRow(Icons.mail_outline_rounded, supplier.email),
          const SizedBox(height: 6),
          _infoRow(Icons.call_outlined, supplier.phone),
          const Spacer(),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: AppColors.neutralSoft, borderRadius: BorderRadius.circular(AppRadius.pill)),
                child: Text('${supplier.activeOrders} active orders', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600)),
              ),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(foregroundColor: AppColors.primary, padding: EdgeInsets.zero),
                child: Text('View Details', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primary)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textMuted),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: AppTextStyles.body.copyWith(color: AppColors.textSecondary), overflow: TextOverflow.ellipsis)),
      ],
    );
  }
}
