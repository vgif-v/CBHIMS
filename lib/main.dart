import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/auth_gate.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'services/connectivity_service.dart';
import 'services/offline_queue_service.dart';
import 'services/settings_service.dart';
import 'services/sync_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  String loadedUrl = '(not loaded yet)';
  String loadedKeyPreview = '(not loaded yet)';

  try {
    await dotenv.load(fileName: ".env");

    loadedUrl = dotenv.env['SUPABASE_URL'] ?? '(NULL - key not found)';
    final key = dotenv.env['SUPABASE_ANON_KEY'] ?? '';
    loadedKeyPreview = key.isEmpty
        ? '(NULL - key not found)'
        : '${key.substring(0, key.length > 12 ? 12 : key.length)}...';

    debugPrint('LOADED URL: [$loadedUrl]');

    await Supabase.initialize(
      url: (dotenv.env['SUPABASE_URL'] ?? '').trim(),
      publishableKey: (dotenv.env['SUPABASE_ANON_KEY'] ?? '').trim(),
    );

    await SettingsService.instance.init();

    await Hive.initFlutter();
    await OfflineQueueService.instance.init();
    await ConnectivityService.instance.init();

    if (ConnectivityService.instance.lastKnownOnline) {
      SyncService.instance.syncPendingTransactions();
    }

    ConnectivityService.instance.onOnlineStatusChanged.listen((isOnline) {
      if (isOnline) {
        SyncService.instance.syncPendingTransactions();
      }
    });

    runApp(const InventoryApp());
  } catch (e) {
    runApp(MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Failed to initialize:\n$e',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red, fontSize: 16),
                ),
                const SizedBox(height: 24),
                Text(
                  'DEBUG INFO\nURL: $loadedUrl\nKey starts with: $loadedKeyPreview',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.black87, fontSize: 13),
                ),
              ],
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