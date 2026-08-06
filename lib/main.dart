import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/auth_gate.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: ".env");

    await Supabase.initialize(
      url: (dotenv.env['SUPABASE_URL'] ?? '').trim(),
      anonKey: (dotenv.env['SUPABASE_ANON_KEY'] ?? '').trim(),
    );

    runApp(const InventoryApp());
  } catch (e) {
    // If init fails, show an error screen instead of a blank white page.
    runApp(MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text(
              'Failed to initialize:\n$e',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red, fontSize: 16),
            ),
          ),
        ),
      ),
    ));
  }
}

class InventoryApp extends StatelessWidget {
  const InventoryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CBHIMS — Inventory Management',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const AuthGate(),
    );
  }
}

