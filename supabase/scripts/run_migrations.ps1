<#
PowerShell migration runner for Supabase (Crypto-Pay)
Prerequisites:
 - `psql` (Postgres client) available in PATH
 - A Supabase DB connection string (e.g. postgres://user:pass@host:port/database)

Usage:
  # interactive (will prompt if not set)
  ./run_migrations.ps1

  # pass DB URL explicitly
  ./run_migrations.ps1 -DbUrl "postgres://user:pass@host:5432/postgres"

Notes:
 - This script runs `reset.sql` first (if present) then all SQL files from ../migrations sorted by filename.
 - It stops on the first error and returns the psql exit code.
 - Back up your database before using the reset script.
#>

param(
    [string]$DbUrl = $env:SUPABASE_DB_URL
)

if (-not $DbUrl) {
    $DbUrl = Read-Host "Enter Supabase DB connection string (postgres://... )"
}

$psql = "psql"
if (-not (Get-Command $psql -ErrorAction SilentlyContinue)) {
    Write-Error "psql not found in PATH. Install PostgreSQL client tools or add psql to PATH."; exit 1
}

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$migrationsDir = Join-Path $scriptDir "..\migrations"
$resetFile = Join-Path $scriptDir "reset.sql"

function Run-SqlFile($filePath) {
    Write-Host "\n--- Running: $filePath ---"
    & $psql $DbUrl -v ON_ERROR_STOP=1 -f $filePath
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Execution failed for $filePath with code $LASTEXITCODE"
        exit $LASTEXITCODE
    }
}

# Run reset if present
if (Test-Path $resetFile) {
    Write-Host "Running reset script: $resetFile"
    Run-SqlFile $resetFile
} else {
    Write-Host "No reset.sql found; skipping reset step."
}

# Run migrations in order
if (-not (Test-Path $migrationsDir)) {
    Write-Error "Migrations folder not found: $migrationsDir"; exit 1
}

$migrations = Get-ChildItem -Path $migrationsDir -Filter "*.sql" | Sort-Object Name
if ($migrations.Count -eq 0) { Write-Host "No migration files found in $migrationsDir"; exit 0 }

foreach ($m in $migrations) {
    Run-SqlFile $m.FullName
}

Write-Host "\nAll migrations applied successfully."; exit 0
