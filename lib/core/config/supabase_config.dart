class SupabaseConfig {
  // Replace these with your actual Supabase project credentials:
  // You can find them in: Supabase Dashboard -> Project Settings -> API
  static const String supabaseUrl = 'https://rsstclayecebpvqcjgsk.supabase.co';
  static const String supabaseAnonKey = 'sb_publishable_lVxrwEp8KNd7YGQX-Eq5Ug_rojLOE0M';

  // Storage Bucket Names
  static const String productImagesBucket = 'product-images';
  static const String avatarsBucket = 'user-avatars';

  static bool get isConfigured =>
      supabaseUrl != 'https://YOUR_PROJECT_ID.supabase.co' &&
      supabaseAnonKey != 'YOUR_SUPABASE_ANON_KEY' &&
      supabaseUrl.isNotEmpty &&
      supabaseAnonKey.isNotEmpty;
}
