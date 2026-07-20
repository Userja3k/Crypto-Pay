// Set SUPABASE_URL, SUPABASE_ANON_KEY and Breez variables at build time using --dart-define
// Example:
// flutter run --dart-define=SUPABASE_URL=https://... \
//   --dart-define=SUPABASE_ANON_KEY=eyJ... \
//   --dart-define=BREEZ_API_KEY=your_api_key

// lib/config.dart
// Variables de configuration avec valeurs par défaut

const String kSupabaseUrl = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: 'https://oclsoevlkizzkpjdamff.supabase.co',
);

const String kSupabaseAnonKey = String.fromEnvironment(
  'SUPABASE_ANON_KEY',
  defaultValue:
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9jbHNvZXZsa2l6emtwamRhbWZmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODM0OTEyNjgsImV4cCI6MjA5OTA2NzI2OH0.rsAWhBPQXUkf8MEMf51RYOffzgzmyLeuwF2EgS90Qag',
);

const String kBreezApiKey = String.fromEnvironment('BREEZ_API_KEY',
    defaultValue:
        'MIIBcDCCASKgAwIBAgIHP1KlxtngKzAFBgMrZXAwEDEOMAwGA1UEAxMFQnJlZXowHhcNMjYwNjI1MDkyNTQ5WhcNMzYwNjIyMDkyNTQ5WjAqMREwDwYDVQQKEwhVc2VyamEzazEVMBMGA1UEAxMMSXNyYWVsIEphY29iMCowBQYDK2VwAyEA0IP1y98gPByiIMoph1P0G6cctLb864rNXw1LRLOpXXejgYAwfjAOBgNVHQ8BAf8EBAMCBaAwDAYDVR0TAQH/BAIwADAdBgNVHQ4EFgQU2jmj7l5rSw0yVb/vlWAYkK/YBwkwHwYDVR0jBBgwFoAU3qrWklbzjed0khb8TLYgsmsomGswHgYDVR0RBBcwFYETamEza2phY29iQGdtYWlsLmNvbTAFBgMrZXADQQATLLrLmoAPPduu3UFmRdWldQFur/X3yT5I0+dQUgqOYzdVGXkKs3fdiiB4rEjEoQu91NO3uyPWQhtRNf9Y1/gB');

const String kBreezServer = String.fromEnvironment(
  'BREEZ_SERVER',
  defaultValue: 'https://api.breez.xyz',
);

const String kBreezChainnotifierUrl = String.fromEnvironment(
  'BREEZ_CHAINNOTIFIER_URL',
  defaultValue: 'https://mempool.space/testnet/api',
);

const String kBreezWebhookUrl = String.fromEnvironment(
  'BREEZ_WEBHOOK_URL',
  defaultValue: '',
);
