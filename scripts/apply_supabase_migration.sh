#!/usr/bin/env bash
# apply_supabase_migration.sh
# Usage: ./apply_supabase_migration.sh <SUPABASE_URL> <SERVICE_ROLE_KEY> <MIGRATION_FILE>
set -euo pipefail

SUPABASE_URL="$1"
SERVICE_ROLE_KEY="$2"
MIGRATION_FILE="$3"

if [ ! -f "$MIGRATION_FILE" ]; then
  echo "Migration file not found: $MIGRATION_FILE" >&2
  exit 1
fi

SQL=$(cat "$MIGRATION_FILE")
ENCODED=$(printf "%s" "$SQL" | base64 | tr -d '\n')

BODY=$(jq -n --arg sql "$ENCODED" '{sql: $sql}')

ENDPOINT="$SUPABASE_URL/rest/v1/rpc/apply_migration"

RESP=$(curl -sS -X POST "$ENDPOINT" \
  -H "apikey: $SERVICE_ROLE_KEY" \
  -H "Authorization: Bearer $SERVICE_ROLE_KEY" \
  -H "Content-Type: application/json" \
  -d "$BODY")

echo "Response: $RESP"

echo "Done."