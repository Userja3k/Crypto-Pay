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


-- ALTER TYPE cryptopay.kyc_level_enum SET SCHEMA public;
-- ALTER TYPE cryptopay.transaction_status_enum SET SCHEMA public;
-- ALTER TYPE cryptopay.transaction_type_enum SET SCHEMA public;
-- ALTER TYPE cryptopay.user_role_enum SET SCHEMA public;
-- ALTER TYPE cryptopay.device_type_enum SET SCHEMA public;

-- ALTER TABLE cryptopay.users SET SCHEMA public;
-- ALTER TABLE cryptopay.accounts SET SCHEMA public;
-- ALTER TABLE cryptopay.transactions SET SCHEMA public;
-- ALTER TABLE cryptopay.sessions SET SCHEMA public;
-- ALTER TABLE cryptopay.notifications SET SCHEMA public;
-- ALTER TABLE cryptopay.kyc_documents SET SCHEMA public;
-- ALTER TABLE cryptopay.child_limits SET SCHEMA public;
-- ALTER TABLE cryptopay.pending_approvals SET SCHEMA public;
-- ALTER TABLE cryptopay.exchange_rates SET SCHEMA public;
-- ALTER TABLE cryptopay.limits SET SCHEMA public;
-- ALTER TABLE cryptopay.lnurl_pay SET SCHEMA public;
-- ALTER TABLE cryptopay.lnurl_withdraw SET SCHEMA public;
-- ALTER TABLE cryptopay.settings SET SCHEMA public;

-- 3. Rafraîchir le cache de l'API
NOTIFY pgrst, 'reload schema';


-- 1. Réparer la récupération du Salt
CREATE OR REPLACE FUNCTION public.get_user_salt(p_identifier VARCHAR(255))
RETURNS TEXT AS $$
BEGIN
    RETURN (SELECT pin_salt FROM public.users WHERE (email = p_identifier OR phone = p_identifier) AND deleted_at IS NULL);
END; $$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. Réparer la vérification de connexion
CREATE OR REPLACE FUNCTION public.verify_login(p_identifier VARCHAR(255), p_pin_hash TEXT)
RETURNS TABLE(user_id UUID, full_name VARCHAR(255), user_role user_role_enum, kyc_level kyc_level_enum, is_valid BOOLEAN, message TEXT) AS $$
DECLARE v_user public.users%ROWTYPE;
BEGIN
    SELECT * INTO v_user FROM public.users WHERE (email = p_identifier OR phone = p_identifier) AND deleted_at IS NULL AND is_active = TRUE;
    IF NOT FOUND THEN
        RETURN QUERY SELECT NULL::UUID, NULL::VARCHAR, NULL::user_role_enum, NULL::kyc_level_enum, FALSE, 'Utilisateur non trouvé'::TEXT; RETURN;
    END IF;
    IF v_user.encrypted_pin_hash != p_pin_hash THEN
        RETURN QUERY SELECT NULL::UUID, NULL::VARCHAR, NULL::user_role_enum, NULL::kyc_level_enum, FALSE, 'Identifiants incorrects'::TEXT; RETURN;
    END IF;
    UPDATE public.users SET last_login_at = NOW() WHERE id = v_user.id;
    RETURN QUERY SELECT v_user.id, v_user.full_name, v_user.user_role, v_user.kyc_level, TRUE, 'Connexion réussie'::TEXT;
END; $$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. Réparer l'inscription
CREATE OR REPLACE FUNCTION public.register_user(
    p_email VARCHAR(255),
    p_phone VARCHAR(50),
    p_full_name VARCHAR(255),
    p_birth_date DATE,
    p_pin_hash TEXT,
    p_pin_salt TEXT DEFAULT NULL,
    p_referral_code VARCHAR(20) DEFAULT NULL,
    p_user_role user_role_enum DEFAULT 'adult',
    p_parent_id UUID DEFAULT NULL
)
RETURNS TABLE(user_id UUID, account_id UUID, referral_code VARCHAR(20), message TEXT) AS $$
DECLARE
    v_user_id UUID;
    v_account_id UUID;
    v_referral_code VARCHAR(20);
BEGIN
    IF EXISTS (SELECT 1 FROM public.users WHERE email = p_email AND deleted_at IS NULL) THEN
        RETURN QUERY SELECT NULL::UUID, NULL::UUID, NULL::VARCHAR, 'Email déjà utilisé'::TEXT; RETURN;
    END IF;

    v_referral_code := UPPER(SUBSTRING(MD5(RANDOM()::TEXT) FROM 1 FOR 8));

    INSERT INTO public.users (
        email, phone, full_name, birth_date, encrypted_pin_hash, pin_salt,
        referral_code, user_role, parent_id, is_active
    )
    VALUES (
        p_email, p_phone, p_full_name, p_birth_date, p_pin_hash, p_pin_salt,
        v_referral_code, p_user_role, p_parent_id, TRUE
    )
    RETURNING id INTO v_user_id;

    INSERT INTO public.accounts (user_id) VALUES (v_user_id) RETURNING id INTO v_account_id;
    RETURN QUERY SELECT v_user_id, v_account_id, v_referral_code, 'Compte créé avec succès'::TEXT;
END; $$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. Accorder à nouveau les droits
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO anon, authenticated;
