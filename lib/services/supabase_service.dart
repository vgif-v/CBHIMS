import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class SupabaseService {
  // ─── Auth ───────────────────────────────────────────
  Future<AuthResponse> signIn(String email, String password) async {
    return await supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await supabase.auth.signOut();
  }

  // Get current logged in user
  User? get currentUser => supabase.auth.currentUser;

  // ─── Products ───────────────────────────────────────
  Future<List<Map<String, dynamic>>> getProducts() async {
    final response = await supabase
        .from('products')
        .select('*, categories(name)')
        .eq('is_active', true)
        .order('product_name');
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> addProduct(Map<String, dynamic> product) async {
    await supabase.from('products').insert(product);
  }

  Future<void> updateProduct(int id, Map<String, dynamic> data) async {
    await supabase.from('products').update(data).eq('id', id);
  }

  // ─── Categories ─────────────────────────────────────
  Future<List<Map<String, dynamic>>> getCategories() async {
    final response = await supabase
        .from('categories')
        .select()
        .order('name');
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> addCategory(String name, String? description) async {
    await supabase.from('categories').insert({
      'name': name,
      'description': description,
    });
  }

  // ─── Transactions ────────────────────────────────────
  Future<List<Map<String, dynamic>>> getTransactions() async {
    final response = await supabase
        .from('transactions')
        .select('*, users(full_name)')
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> addTransaction(Map<String, dynamic> transaction) async {
    await supabase.from('transactions').insert(transaction);
  }
}