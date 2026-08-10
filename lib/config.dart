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
    defaultValue: 'your_api_key_if_any');

const String kGreenlightCert = '''
MIICrjCCAlSgAwIBAgIUX/gag+5zw7f3SV5VYzzpEEcQf8IwCgYIKoZIzj0EAwIw
gYMxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpDYWxpZm9ybmlhMRYwFAYDVQQHEw1T
YW4gRnJhbmNpc2NvMRQwEgYDVQQKEwtCbG9ja3N0cmVhbTEdMBsGA1UECxMUQ2Vy
dGlmaWNhdGVBdXRob3JpdHkxEjAQBgNVBAMTCUdMIC91c2VyczAeFw0yNjA4MDcx
MDExMDBaFw0zNjA4MDQxMDExMDBaMIGoMQswCQYDVQQGEwJVUzETMBEGA1UECBMK
Q2FsaWZvcm5pYTEWMBQGA1UEBxMNU2FuIEZyYW5jaXNjbzEUMBIGA1UEChMLQmxv
Y2tzdHJlYW0xHTAbBgNVBAsTFENlcnRpZmljYXRlQXV0aG9yaXR5MTcwNQYDVQQD
Ey5HTCAvdXNlcnMvOGMxMDE2OTUtN2MzYS00MWY2LWIxMzgtMzU5NjIzZDZkNGIy
MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAE+NeG13e4JNrGZdLB5X3UIva9N5xQ
TAZDXxYYvZu/QurhoblUoOf9n2fybXOiNUpxXtWOCoFsggqFyNmHXzYOMKN/MH0w
DgYDVR0PAQH/BAQDAgGmMB0GA1UdJQQWMBQGCCsGAQUFBwMBBggrBgEFBQcDAjAM
BgNVHRMBAf8EAjAAMB0GA1UdDgQWBBSfTlinftf3D9POsy8ZcZ5EGmzUKjAfBgNV
HSMEGDAWgBRNDvcXUwxuk6LEG10+ig8mBsMllDAKBggqhkjOPQQDAgNIADBFAiAk
TrSE2W+zUa8cj4jSc7JaSEFSJ68qs87+1o+uqkKfuQIhAJ+DLEMb56aXI4pQHTvI
Mq9V6NLcem992/X9lnwXKNlK
''';

const String kGreenlightKey = '''
MIGHAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBG0wawIBAQQgXzkgwiHBNDP1qUWN
fxn6c3iWu679OWV7cd0s+EOUqBChRANCAAT414bXd7gk2sZl0sHlfdQi9r03nFBM
BkNfFhi9m79C6uGhuVSg5/2fZ/Jtc6I1SnFe1Y4KgWyCCoXI2YdfNg4w
''';


const String kBreezServer = String.fromEnvironment(
  'BREEZ_SERVER',
  defaultValue: 'https://bs1-testnet.breez.technology',
);

const String kBreezChainnotifierUrl = String.fromEnvironment(
  'BREEZ_CHAINNOTIFIER_URL',
  defaultValue: 'https://mempool.space/testnet/api',
);

const String kBreezWebhookUrl = String.fromEnvironment(
  'BREEZ_WEBHOOK_URL',
  defaultValue: 'https://oclsoevlkizzkpjdamff.supabase.co/functions/v1/breez-webhook',
);

const String kPriceOracleUrl = String.fromEnvironment(
  'PRICE_ORACLE_URL',
  defaultValue: 'https://oclsoevlkizzkpjdamff.supabase.co/functions/v1/price-oracle',
);

const String kLnurlPayUrl = String.fromEnvironment(
  'LNURL_PAY_URL',
  defaultValue: 'https://oclsoevlkizzkpjdamff.supabase.co/functions/v1/lnurl-pay',
);

const String kLndIntegrationUrl = String.fromEnvironment(
  'LND_INTEGRATION_URL',
  defaultValue: 'https://oclsoevlkizzkpjdamff.supabase.co/functions/v1/lnd-integration',
);
