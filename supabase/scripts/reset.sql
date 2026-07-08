-- Reset script for Crypto-Pay Supabase schema
-- WARNING: This will DROP the `cryptopay` schema and all its objects.
-- Back up your data before running this.

SET client_min_messages TO WARNING;

-- Ensure required extensions for migrations
CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Drop the schema and recreate an empty one
DROP SCHEMA IF EXISTS cryptopay CASCADE;
CREATE SCHEMA cryptopay;

-- Ensure search_path
SET search_path TO cryptopay, public;

-- Minimal placeholder: migrations will create types/tables/functions

-- End of reset.sql
