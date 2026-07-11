-- =========================================================
-- FIX: Schema permissions for cryptopay
-- Error: permission denied for schema cryptopay (code 42501)
-- Date: 2026-07-08
-- =========================================================
-- Le problème : le schéma cryptopay et ses fonctions n'ont pas
-- de GRANT pour les rôles Supabase (anon, authenticated).
-- Les fonctions doivent être appelables par le rôle anon pour
-- l'inscription (register_user) et la connexion (get_user_salt,
-- verify_login), et authenticated pour toutes les autres.
-- =========================================================

-- 1. Donner l'accès au schéma
GRANT USAGE ON SCHEMA cryptopay TO anon;
GRANT USAGE ON SCHEMA cryptopay TO authenticated;
GRANT USAGE ON SCHEMA cryptopay TO service_role;

-- 2. Fonctions accessibles par les non-authentifiés (inscription / login)
GRANT EXECUTE ON FUNCTION cryptopay.register_user(
    VARCHAR, VARCHAR, VARCHAR, DATE, TEXT, TEXT, VARCHAR, cryptopay.user_role_enum, UUID
) TO anon;

GRANT EXECUTE ON FUNCTION cryptopay.get_user_salt(VARCHAR) TO anon;

GRANT EXECUTE ON FUNCTION cryptopay.verify_login(VARCHAR, TEXT) TO anon;

-- 3. Toutes les fonctions accessibles par les utilisateurs authentifiés
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA cryptopay TO authenticated;

-- 4. Assurer que les nouvelles fonctions futures héritent aussi des droits
ALTER DEFAULT PRIVILEGES IN SCHEMA cryptopay
    GRANT EXECUTE ON FUNCTIONS TO authenticated;

ALTER DEFAULT PRIVILEGES IN SCHEMA cryptopay
    GRANT EXECUTE ON FUNCTIONS TO service_role;

-- 5. Accès aux tables pour service_role (pour les Edge Functions / webhooks)
GRANT ALL ON ALL TABLES IN SCHEMA cryptopay TO service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA cryptopay TO service_role;

-- 6. Les fonctions register_user, get_user_salt et verify_login doivent être
-- SECURITY DEFINER pour accéder aux tables sans que anon y ait accès directement.
-- On s'assure qu'elles tournent avec les droits du owner (postgres).
-- Note: Ces ALTER FUNCTION ne changeront rien si elles sont déjà SECURITY DEFINER,
-- mais corrigent si elles ne l'étaient pas.
ALTER FUNCTION cryptopay.register_user(
    VARCHAR, VARCHAR, VARCHAR, DATE, TEXT, TEXT, VARCHAR, cryptopay.user_role_enum, UUID
) SECURITY DEFINER SET search_path = cryptopay, public;

ALTER FUNCTION cryptopay.get_user_salt(VARCHAR)
    SECURITY DEFINER SET search_path = cryptopay, public;

ALTER FUNCTION cryptopay.verify_login(VARCHAR, TEXT)
    SECURITY DEFINER SET search_path = cryptopay, public;
