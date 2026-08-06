import 'package:supabase_flutter/supabase_flutter.dart';

/// Thin wrapper around Supabase Auth that every screen can import
/// without coupling directly to the Supabase SDK.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final SupabaseClient _client = Supabase.instance.client;

  // ---------------------------------------------------------------------------
  // Reactive session stream
  // ---------------------------------------------------------------------------

  /// Emits whenever the auth state changes (sign-in, sign-out, token refresh).
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  // ---------------------------------------------------------------------------
  // Getters
  // ---------------------------------------------------------------------------

  /// The currently authenticated user, or `null` if signed out.
  User? get currentUser => _client.auth.currentUser;

  /// Convenience — the user's display name stored in metadata.
  String get displayName =>
      currentUser?.userMetadata?['full_name'] as String? ?? 'User';

  /// Convenience — the user's email.
  String get email => currentUser?.email ?? '';

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  /// Create a new account with email, password and a display name.
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    return await _client.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName},
    );
  }

  /// Sign in with email & password.
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// End the current session.
  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}
