import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/category.dart';

/// Service for all category-related Supabase operations.
class CategoryService {
  CategoryService._();
  static final CategoryService instance = CategoryService._();

  final SupabaseClient _client = Supabase.instance.client;

  /// Fetch all categories ordered by name.
  Future<List<Category>> getAll() async {
    final response = await _client
        .from('categories')
        .select()
        .order('name');
    return (response as List)
        .map((row) => Category.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  /// Insert a new category.
  Future<Category> add({
    required String name,
    String? description,
  }) async {
    final response = await _client
        .from('categories')
        .insert({
          'name': name,
          if (description != null) 'description': description,
        })
        .select()
        .single();
    return Category.fromJson(response);
  }
}
