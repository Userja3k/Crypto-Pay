-- Patch: add lightning_address column to accounts
SET search_path TO cryptopay, public;

ALTER TABLE IF EXISTS cryptopay.accounts
  ADD COLUMN IF NOT EXISTS lightning_address TEXT;

CREATE UNIQUE INDEX IF NOT EXISTS accounts_lightning_address_idx
  ON cryptopay.accounts (lightning_address);
