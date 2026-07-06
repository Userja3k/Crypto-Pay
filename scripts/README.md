Patch migration scripts

This folder contains helper scripts to apply the single-file SQL patch [supabase/migrations/20260705_patch_functions.sql](supabase/migrations/20260705_patch_functions.sql) without re-running the full initial migration.

Files:
- [apply_patch_psql.ps1](apply_patch_psql.ps1) - PowerShell script (Windows). Uses `psql` when `DATABASE_URL` is set, otherwise tries `supabase` CLI.
- [apply_patch_psql.sh](apply_patch_psql.sh) - Bash script (Linux/macOS). Use with `DATABASE_URL` environment variable or `supabase` CLI.
- [apply_supabase_migration.ps1](apply_supabase_migration.ps1) and [apply_supabase_migration.sh](apply_supabase_migration.sh) - older RPC-based scripts that post encoded SQL to an RPC endpoint. Prefer psql scripts when possible.

Examples

PowerShell (with env var):

`$env:DATABASE_URL = 'postgres://user:pass@host:5432/db'`
`./apply_patch_psql.ps1 -SqlFile '..\supabase\migrations\20260705_patch_functions.sql'`

PowerShell (explicit):

`./apply_patch_psql.ps1 -SqlFile '..\supabase\migrations\20260705_patch_functions.sql' -DatabaseUrl 'postgres://user:pass@host:5432/db'`

Bash:

`export DATABASE_URL='postgres://user:pass@host:5432/db'`
`./apply_patch_psql.sh supabase/migrations/20260705_patch_functions.sql`

Notes
- `psql` must be installed and accessible in PATH for direct DB application.
- Alternatively install `supabase` CLI and run `supabase db query --file <sql>` (must be logged to the project).
- Ensure you run these scripts in a secure environment and that the connection string has appropriate permissions (prefer a service role key for migrations).

If you prefer to run the SQL manually, open [supabase/migrations/20260705_patch_functions.sql](supabase/migrations/20260705_patch_functions.sql) and paste into the Supabase SQL editor.
