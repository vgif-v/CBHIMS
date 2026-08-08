import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Thin wrapper around Supabase Auth that every screen can import
/// without coupling directly to the Supabase SDK.
class AuthService extends ChangeNotifier {
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

  /// Convenience — the current user's UUID.
  String? get userId => currentUser?.id;

  String? _cachedRole;
  bool _isRoleLoading = false;

  /// Cached user role ('Admin', 'Manager', 'Staff'), or null if not yet loaded.
  String? get userRole => _cachedRole;

  /// True while a role fetch is in flight — screens can use this to avoid
  /// flashing an incorrect Admin/Staff button before the real role arrives.
  bool get isRoleLoading => _isRoleLoading;

  /// Clears the cached role. Call this on sign-out and at the start of
  /// sign-in so no screen can ever read a previous user's role.
  void _resetRole() {
    _cachedRole = null;
    _isRoleLoading = false;
    notifyListeners();
  }

  /// Fetch user role from the `users` table in Supabase.
  Future<String> fetchUserRole() async {
    final uid = userId;
    if (uid == null) {
      _resetRole();
      return 'Staff';
    }

    _isRoleLoading = true;
    notifyListeners();

    try {
      final res = await _client
          .from('users')
          .select('role, full_name, email')
          .eq('id', uid)
          .maybeSingle();

      if (res != null && res['role'] != null) {
        final r = res['role'].toString().trim();
        if (r.isNotEmpty) {
          _cachedRole = r[0].toUpperCase() + r.substring(1).toLowerCase();
        } else {
          _cachedRole = 'Staff';
        }
      } else {
        // User not yet in public.users table — auto-insert with a safe
        // default. NOTE: defaults to 'Staff', not 'Admin' — a brand new
        // row should never grant elevated access by default.
        final userEmail = email;
        final userFullName = displayName;
        _cachedRole = 'Staff';
        debugPrint('[AuthService] fetchUserRole raw result for uid=$uid: $res');

        try {
          await _client.from('users').upsert({
            'id': uid,
            'full_name': userFullName.isNotEmpty ? userFullName : 'New User',
            'email': userEmail,
            'role': 'staff',
          });
        } catch (e) {
          debugPrint('[AuthService] Could not auto-create user row: $e');
        }
      }
    } catch (e) {
      debugPrint('[AuthService] Could not fetch user role: $e');
      _cachedRole ??= 'Staff';
    }

    _isRoleLoading = false;
    notifyListeners();
    return _cachedRole!;
  }

  /// Check if the logged in user is an Admin.
  bool get isAdmin => (_cachedRole ?? '').toLowerCase() == 'admin';

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  /// Update user's role in the `users` table (Admin action).
  Future<void> updateUserRole(String targetUserId, String newRole) async {
    final formattedRole = newRole.toLowerCase();
    await _client
        .from('users')
        .update({'role': formattedRole})
        .eq('id', targetUserId);
    if (targetUserId == userId) {
      _cachedRole = formattedRole[0].toUpperCase() + formattedRole.substring(1);
      notifyListeners();
    }
  }

  /// Update display name / profile info.
  Future<void> updateProfile({required String fullName}) async {
    final uid = userId;
    if (uid != null) {
      // 1. Update user metadata in auth
      await _client.auth.updateUser(UserAttributes(data: {'full_name': fullName}));
      // 2. Update users table
      await _client.from('users').upsert({
        'id': uid,
        'full_name': fullName,
        'email': email,
        'role': (_cachedRole ?? 'Staff').toLowerCase(),
      });
      notifyListeners();
    }
  }

  /// Update user password.
  Future<void> updatePassword(String newPassword) async {
    await _client.auth.updateUser(UserAttributes(password: newPassword));
  }

  /// Create a new account with email, password and a display name.
  /// Also inserts a row into the `public.users` table.
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    // Make sure no stale role from a previous session leaks into this flow.
    _resetRole();

    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName},
    );

    // If signup succeeded and we have a user, insert into public.users
    final user = response.user;
    if (user != null) {
      try {
        await _client.from('users').upsert({
          'id': user.id,
          'full_name': fullName,
          'email': email,
          'role': 'staff',
        });
      } catch (e) {
        // Log but don't block signup — the trigger may already handle this
        debugPrint('[AuthService] Failed to insert into users table: $e');
      }
    }

    return response;
  }

  /// Sign in with email & password.
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    // Clear any previous user's cached role before establishing the new
    // session, then fetch this user's real role immediately.
    _resetRole();

    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );

    if (response.user != null) {
      await fetchUserRole();
    }

    return response;
  }

  /// End the current session.
  Future<void> signOut() async {
    await _client.auth.signOut();
    _resetRole();
  }
}