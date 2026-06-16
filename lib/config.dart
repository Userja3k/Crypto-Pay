// Set SUPABASE_URL and SUPABASE_ANON_KEY at build time using --dart-define
// Example: flutter run --dart-define=SUPABASE_URL=https://... --dart-define=SUPABASE_ANON_KEY=eyJ...

const String kSupabaseUrl = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: 'https://zfrmcnmvhezninmeacak.supabase.co',
);
const String kSupabaseAnonKey = String.fromEnvironment(
  'SUPABASE_ANON_KEY',
  defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inpmcm1jbm12aGV6bmlubWVhY2FrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODExNjQ0ODAsImV4cCI6MjA5Njc0MDQ4MH0.7mN0hq5pMcOemFf3rWSYlrhe9rCppRu93teKNhbYf6A',
);
