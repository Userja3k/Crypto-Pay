<#
apply_patch_psql.ps1
Apply a single SQL patch to your Supabase/Postgres database using `psql` or `supabase db query`.

Usage examples:
  # using env var
  $env:DATABASE_URL = 'postgres://user:pass@host:5432/db'
  .\apply_patch_psql.ps1 -SqlFile '..\supabase\migrations\20260705_patch_functions.sql'

  # passing explicit DB url
  .\apply_patch_psql.ps1 -SqlFile '..\supabase\migrations\20260705_patch_functions.sql' -DatabaseUrl 'postgres://user:pass@host:5432/db'

Requirements: `psql` in PATH or `supabase` CLI configured.
#>
param(
  [string]$SqlFile = "..\supabase\migrations\20260705_patch_functions.sql",
  [string]$DatabaseUrl = $env:DATABASE_URL
)

if (-not (Test-Path $SqlFile)) {
  Write-Error "SQL file not found: $SqlFile"
  exit 1
}

if ($DatabaseUrl -and $DatabaseUrl -ne "") {
  $psql = Get-Command psql -ErrorAction SilentlyContinue
  if ($psql) {
    Write-Host "Applying patch using psql..."
    & psql $DatabaseUrl -v ON_ERROR_STOP=1 -f $SqlFile
    if ($LASTEXITCODE -ne 0) { Write-Error "psql exited with code $LASTEXITCODE"; exit $LASTEXITCODE }
    Write-Host "Patch applied successfully with psql."
    exit 0
  }
}

# Fallback to supabase CLI
$supabase = Get-Command supabase -ErrorAction SilentlyContinue
if ($supabase) {
  Write-Host "Using supabase CLI to run SQL file..."
  & supabase db query --file $SqlFile
  if ($LASTEXITCODE -ne 0) { Write-Error "supabase CLI exited with code $LASTEXITCODE"; exit $LASTEXITCODE }
  Write-Host "Patch applied successfully with supabase CLI."
  exit 0
}

Write-Error "No method available to apply the patch. Install psql or supabase CLI, or provide DATABASE_URL environment variable pointing to your database.";
exit 2
