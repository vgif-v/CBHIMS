import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/main_layout_screen.dart';

void main() {
  runApp(const InventoryApp());
}

class InventoryApp extends StatelessWidget {
  const InventoryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stockpile — Inventory Management',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const MainLayoutScreen(),
    );
  }
}
