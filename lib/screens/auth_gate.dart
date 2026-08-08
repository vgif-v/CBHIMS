import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_screen.dart';
import 'main_layout_screen.dart';
import '../services/auth_service.dart';

/// Listens to the Supabase auth state and routes to either
/// [LoginScreen] or [MainLayoutScreen] accordingly.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _initializing = true;
  bool _hasSession = false;

  @override
  void initState() {
    super.initState();
    _checkExistingSession();
  }

  Future<void> _checkExistingSession() async {
    // Check if there's already a persisted session
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      // Preload user role
      await AuthService.instance.fetchUserRole();
      if (!mounted) return;
      setState(() {
        _hasSession = true;
        _initializing = false;
      });
    } else {
      if (!mounted) return;
      setState(() {
        _hasSession = false;
        _initializing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_initializing) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        // Use the initial check result if the stream hasn't emitted yet
        if (!snapshot.hasData) {
          return _hasSession
              ? const MainLayoutScreen()
              : const LoginScreen();
        }

        final event = snapshot.data!.event;
        final session = snapshot.data!.session;

        // Only navigate to login on explicit sign-out, not on token refresh
        if (event == AuthChangeEvent.signedOut) {
          return const LoginScreen();
        }

        if (session != null) {
          return const MainLayoutScreen();
        }

        return _hasSession
            ? const MainLayoutScreen()
            : const LoginScreen();
      },
    );
  }
}
