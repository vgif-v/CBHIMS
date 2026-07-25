import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/sidebar.dart';
import 'dashboard_screen.dart';
import 'inventory_screen.dart';
import 'inbound_screen.dart';
import 'outbound_screen.dart';
import 'suppliers_screen.dart';
import 'reports_screen.dart';
import 'settings_screen.dart';

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

  static const List<Widget> _screens = [
    DashboardScreen(),
    InventoryScreen(),
    InboundScreen(),
    OutboundScreen(),
    SuppliersScreen(),
    ReportsScreen(),
    SettingsScreen(),
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
              title: Text(kNavItems[_selectedIndex].label, style: AppTextStyles.h3),
            ),
      body: Row(
        children: [
          if (showSidebarInline)
            Sidebar(
              selectedIndex: _selectedIndex,
              onSelect: (i) => setState(() => _selectedIndex = i),
            ),
          if (showSidebarInline)
            const VerticalDivider(width: 1, thickness: 1, color: AppColors.border),
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
