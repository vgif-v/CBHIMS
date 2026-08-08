import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/sidebar.dart';
import 'tabs/dashboard_screen.dart';
import 'tabs/inventory_screen.dart';
import 'tabs/transactions_screen.dart';
import 'tabs/reports_screen.dart';
import 'tabs/settings_screen.dart';
import 'tabs/account_screen.dart';

/// The persistent app shell: a fixed sidebar on the left and a main
/// content area on the right that swaps screens based on the active
/// navigation item.
class MainLayoutScreen extends StatefulWidget {
  const MainLayoutScreen({super.key});

  @override
  State<MainLayoutScreen> createState() => _MainLayoutScreenState();
}

class _MainLayoutScreenState extends State<MainLayoutScreen> {
  int _selectedIndex = 0;

  void setTab(int index) {
    if (index >= 0 && index < _screens.length) {
      setState(() => _selectedIndex = index);
    }
  }

  late final List<Widget> _screens = [
    DashboardScreen(onNavigateToTab: setTab),
    const InventoryScreen(),
    const TransactionsScreen(),
    const ReportsScreen(),
    const SettingsScreen(),
    const AccountScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final bool showSidebarInline = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: showSidebarInline
          ? null
          : Drawer(
              child: Sidebar(
                selectedIndex: _selectedIndex,
                onSelect: (i) {
                  setState(() => _selectedIndex = i);
                  Navigator.of(context).pop();
                },
              ),
            ),
      appBar: showSidebarInline
          ? null
          : AppBar(
              backgroundColor: AppColors.surface,
              elevation: 0,
              foregroundColor: AppColors.textPrimary,
              title: Text(kNavItems[_selectedIndex].label,
                  style: AppTextStyles.h3),
            ),
      body: Row(
        children: [
          if (showSidebarInline)
            Sidebar(
              selectedIndex: _selectedIndex,
              onSelect: (i) => setState(() => _selectedIndex = i),
            ),
          if (showSidebarInline)
            const VerticalDivider(
                width: 1, thickness: 1, color: AppColors.border),
          Expanded(
            child: Container(
              color: AppColors.background,
              child: _screens[_selectedIndex],
            ),
          ),
        ],
      ),
    );
  }
}
