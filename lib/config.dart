// Set SUPABASE_URL, SUPABASE_ANON_KEY and Breez variables at build time using --dart-define
// Example:
// flutter run --dart-define=SUPABASE_URL=https://... \
//   --dart-define=SUPABASE_ANON_KEY=eyJ... \
//   --dart-define=BREEZ_API_KEY=your_api_key

const String kSupabaseUrl = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: 'https://zfrmcnmvhezninmeacak.supabase.co',
);
const String kSupabaseAnonKey = String.fromEnvironment(
  'SUPABASE_ANON_KEY',
  defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inpmcm1jbm12aGV6bmlubWVhY2FrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODExNjQ0ODAsImV4cCI6MjA5Njc0MDQ4MH0.7mN0hq5pMcOemFf3rWSYlrhe9rCppRu93teKNhbYf6A',
);

const String kBreezApiKey = String.fromEnvironment(
  'BREEZ_API_KEY', 
  defaultValue: 'MIIBcDCCASKgAwIBAgIHP1KlxtngKzAFBgMrZXAwEDEOMAwGA1UEAxMFQnJlZXowHhcNMjYwNjI1MDkyNTQ5WhcNMzYwNjIyMDkyNTQ5WjAqMREwDwYDVQQKEwhVc2VyamEzazEVMBMGA1UEAxMMSXNyYWVsIEphY29iMCowBQYDK2VwAyEA0IP1y98gPByiIMoph1P0G6cctLb864rNXw1LRLOpXXejgYAwfjAOBgNVHQ8BAf8EBAMCBaAwDAYDVR0TAQH/BAIwADAdBgNVHQ4EFgQU2jmj7l5rSw0yVb/vlWAYkK/YBwkwHwYDVR0jBBgwFoAU3qrWklbzjed0khb8TLYgsmsomGswHgYDVR0RBBcwFYETamEza2phY29iQGdtYWlsLmNvbTAFBgMrZXADQQATLLrLmoAPPduu3UFmRdWldQFur/X3yT5I0+dQUgqOYzdVGXkKs3fdiiB4rEjEoQu91NO3uyPWQhtRNf9Y1/gB'
  );
const String kBreezServer = String.fromEnvironment(
  'BREEZ_SERVER',
  defaultValue: 'https://breez.technology',
);
const String kBreezChainnotifierUrl = String.fromEnvironment(
  'BREEZ_CHAINNOTIFIER_URL',
  defaultValue: 'https://mempool.space/api',
);
