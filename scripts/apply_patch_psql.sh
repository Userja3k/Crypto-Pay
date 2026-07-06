#!/usr/bin/env bash
# apply_patch_psql.sh
# Apply a single SQL patch using psql or supabase CLI.
# Usage: DATABASE_URL="postgres://user:pass@host:5432/db" ./apply_patch_psql.sh supabase/migrations/20260705_patch_functions.sql

set -euo pipefail
SQL_FILE=${1:-"supabase/migrations/20260705_patch_functions.sql"}
DB_URL=${DATABASE_URL:-}

if [ ! -f "$SQL_FILE" ]; then
  echo "SQL file not found: $SQL_FILE" >&2
  exit 1
fi

if [ -n "$DB_URL" ]; then
  if command -v psql >/dev/null 2>&1; then
    echo "Applying patch with psql..."
    psql "$DB_URL" -v ON_ERROR_STOP=1 -f "$SQL_FILE"
    echo "Patch applied successfully with psql."
    exit 0
  fi
fi

if command -v supabase >/dev/null 2>&1; then
  echo "Applying patch with supabase CLI..."
  supabase db query --file "$SQL_FILE"
  echo "Patch applied successfully with supabase CLI."
  exit 0
fi

echo "Error: No method available to apply the patch. Install psql or supabase CLI, or set DATABASE_URL." >&2
exit 2
