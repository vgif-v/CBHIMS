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

  try {
    await dotenv.load(fileName: ".env");

    await Supabase.initialize(
      url: (dotenv.env['SUPABASE_URL'] ?? '').trim(),
      publishableKey: (dotenv.env['SUPABASE_ANON_KEY'] ?? '').trim(),
    );

    await SettingsService.instance.init();

    await Hive.initFlutter();
    await OfflineQueueService.instance.init();
    await ConnectivityService.instance.init();

    // If the app launches already online and there's a backlog from a
    // previous offline session, sync it now rather than waiting for a
    // connectivity CHANGE event (which won't fire if we're already online).
    if (ConnectivityService.instance.lastKnownOnline) {
      // Don't await this — let the UI render immediately, sync in background.
      SyncService.instance.syncPendingTransactions();
    }

    // Sync whenever we transition from offline -> online.
    ConnectivityService.instance.onOnlineStatusChanged.listen((isOnline) {
      if (isOnline) {
        SyncService.instance.syncPendingTransactions();
      }
    });

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
