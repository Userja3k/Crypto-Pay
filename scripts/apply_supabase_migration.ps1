# apply_supabase_migration.ps1
# Usage: .\apply_supabase_migration.ps1 -SupabaseUrl <url> -ServiceRoleKey <key> -MigrationFile <path>
param(
  [Parameter(Mandatory=$true)] [string]$SupabaseUrl,
  [Parameter(Mandatory=$true)] [string]$ServiceRoleKey,
  [Parameter(Mandatory=$true)] [string]$MigrationFile
)

if (-not (Test-Path $MigrationFile)) {
  Write-Error "Migration file not found: $MigrationFile"
  exit 1
}

$script = Get-Content -Raw -Path $MigrationFile
$encoded = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($script))

$body = @{ sql = $encoded } | ConvertTo-Json

$headers = @{
  "apikey" = $ServiceRoleKey
  "Authorization" = "Bearer $ServiceRoleKey"
  "Content-Type" = "application/json"
}

$endpoint = "$SupabaseUrl/rest/v1/rpc/apply_migration"

Write-Host "Posting migration to Supabase RPC endpoint..."
try {
  $res = Invoke-RestMethod -Method Post -Uri $endpoint -Headers $headers -Body $body -ErrorAction Stop
  Write-Host "Migration response:`n$res"
} catch {
  Write-Error "Failed to apply migration: $_"
  exit 2
}

Write-Host "Done."