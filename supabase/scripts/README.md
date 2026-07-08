Migration runner for Crypto-Pay Supabase

Overview
- `reset.sql`: drops and recreates the `cryptopay` schema (dangerous, destructive).
- `run_migrations.ps1`: PowerShell script to run `reset.sql` (optional) then all *.sql files in `../migrations` in filename order.

Prerequisites
- `psql` (Postgres client) installed and on PATH. On Windows, install PostgreSQL or psql tools.
- A Supabase database connection string. You can find it in the Supabase project Settings -> Database -> Connection string (provide the full `postgres://user:pass@host:port/dbname`).

Usage (recommended)
1. Back up your database (important!).
2. From this repo, run:

```powershell
cd supabase/scripts
Set-ExecutionPolicy -Scope Process -ExecutionPolicy RemoteSigned -Force
./run_migrations.ps1 -DbUrl "postgres://user:pass@host:5432/postgres"
```

Notes & caveats
- Running `reset.sql` will remove all objects in the `cryptopay` schema and data. Only run it if you understand the consequences.
- The runner executes migration files by lexical filename order. Make sure your migration filenames are numbered/timestamped in the intended order.
- I cannot guarantee zero errors when reapplying migrations: common failure sources include
  - Missing required extensions (the reset script creates `pgcrypto` and `uuid-ossp`, but other extensions may be required).
  - Manual edits in the live database that create objects not covered by migrations (these may cause conflicts when creating objects with the same name).
  - Permission or role differences between environments.
  - If any migration depends on state created by a previous migration, ensure ordering and completeness.

If you see an error
- Inspect the failing SQL file and line reported by `psql`.
- Fix the migration (or fix environment issues like missing extensions) and re-run the runner; it stops at first failure so you can correct ordered errors.

Want me to run a dry-check?
- I can add a script that parses all SQL files for `CREATE`/`DROP`/`ALTER` statements and reports potential conflicts locally, or generate a plan of objects to be created/dropped in order. Ask and I'll add it.
