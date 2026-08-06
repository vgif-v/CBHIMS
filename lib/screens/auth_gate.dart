import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_screen.dart';
import 'main_layout_screen.dart';

/// Listens to the Supabase auth state and routes to either
/// [LoginScreen] or [MainLayoutScreen] accordingly.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        // While the stream hasn't emitted yet, check the current session.
        if (!snapshot.hasData) {
          final session = Supabase.instance.client.auth.currentSession;
          if (session != null) {
            return const MainLayoutScreen();
          }
          return const LoginScreen();
        }

        final session = snapshot.data!.session;
        if (session != null) {
          return const MainLayoutScreen();
        }

        return const LoginScreen();
      },
    );
  }
}
