class SupabaseConfig {
  // TODO: Replace these with your actual Supabase credentials
  // Get these from: https://app.supabase.com/project/YOUR_PROJECT/settings/api

  /// Your Supabase project URL
  /// Example: 'https://xyzcompany.supabase.co'
  static const String supabaseUrl = 'https://teedpuxqewddcfzwrydf.supabase.co';

  /// Your Supabase anon/public key (service_role key for backend only)
  /// This is safe to use in the client app
  /// Example: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...'
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRlZWRwdXhxZXdkZGNmendyeWRmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQxNzgyMjYsImV4cCI6MjA3OTc1NDIyNn0.Ksi21jFpG_w5J9YmKaPmX-MOVF6RIv_0lAYTOVJ-kMc';

  /// Service role key (bypasses RLS) - use for file uploads
  /// Get this from: Settings → API → service_role key (secret)
  /// Example: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...'
  static const String supabaseServiceRoleKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRlZWRwdXhxZXdkZGNmendyeWRmIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2NDE3ODIyNiwiZXhwIjoyMDc5NzU0MjI2fQ.hP6TWCyP0gGWOortZkJ6B1cUoLk8Mf1DscVCf7m4HO4';

  /// Storage bucket name for teacher documents
  /// You'll need to create this bucket in Supabase Storage
  static const String teacherDocumentsBucket = 'impartFiles';
}
