import 'package:flutter/material.dart';
import 'auth_screen/login_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_screen/pending_approval_screen.dart';
import 'main_layout_screen.dart';
import '../services/auth_service.dart';

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
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
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

  Widget _resolveHome() {
    if (AuthService.instance.isPending) {
      return const PendingApprovalScreen();
    }
    return const MainLayoutScreen();
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
        if (!snapshot.hasData) {
          return _hasSession ? _resolveHome() : const LoginScreen();
        }

        final event = snapshot.data!.event;
        final session = snapshot.data!.session;

        if (event == AuthChangeEvent.signedOut) {
          return const LoginScreen();
        }

        if (session != null) {
          return FutureBuilder<String?>(
            future: AuthService.instance.fetchUserRole(),
            builder: (context, roleSnapshot) {
              if (roleSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              return _resolveHome();
            },
          );
        }

        return _hasSession ? _resolveHome() : const LoginScreen();
      },
    );
  }
}