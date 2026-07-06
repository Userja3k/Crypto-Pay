-- CRYPTO-PAY FULL INITIAL SCHEMA
-- Version: 1.5.0
-- Date: 2026-06-01

-- Création du schéma principal
CREATE SCHEMA IF NOT EXISTS cryptopay;

SET search_path TO cryptopay, public;

-------------------------------------------------
-- ENUM TYPES
-------------------------------------------------
DO $$ BEGIN
    CREATE TYPE cryptopay.kyc_level_enum AS ENUM ('none', 'basic', 'verified', 'premium');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE cryptopay.transaction_status_enum AS ENUM ('pending', 'completed', 'failed', 'refunded');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE cryptopay.transaction_type_enum AS ENUM ('send', 'receive', 'conversion', 'referral_bonus');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE cryptopay.user_role_enum AS ENUM ('adult', 'child', 'parent');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE cryptopay.device_type_enum AS ENUM ('ios', 'android', 'web');
EXCEPTION WHEN duplicate_object THEN null; END $$;

-------------------------------------------------
-- TABLES
-------------------------------------------------

-- TABLE: users
CREATE TABLE IF NOT EXISTS cryptopay.users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    phone VARCHAR(50) UNIQUE NOT NULL,
    full_name VARCHAR(255) NOT NULL,
    birth_date DATE NOT NULL,
    user_role cryptopay.user_role_enum DEFAULT 'adult',
    parent_id UUID REFERENCES cryptopay.users(id) ON DELETE SET NULL,

    -- Vérification
    kyc_level cryptopay.kyc_level_enum DEFAULT 'none',
    identity_document_url TEXT,
    identity_verified_at TIMESTAMPTZ,
    identity_verification_refused_at TIMESTAMPTZ,
    identity_verification_refused_reason TEXT,

    -- Parrainage
    referral_code VARCHAR(20) UNIQUE,
    referred_by UUID REFERENCES cryptopay.users(id),

    -- Sécurité
    encrypted_pin_hash TEXT NOT NULL,
    pin_salt TEXT,
    two_factor_enabled BOOLEAN DEFAULT FALSE,
    two_factor_secret TEXT,

    -- Préférences
    preferred_currency VARCHAR(3) DEFAULT 'USD',
    language VARCHAR(10) DEFAULT 'fr',
    theme VARCHAR(10) DEFAULT 'dark',
    liquid_glass_intensity INT DEFAULT 1,
    animations_enabled BOOLEAN DEFAULT TRUE,

    -- Stats
    total_sent_usd DECIMAL(15,2) DEFAULT 0,
    total_received_usd DECIMAL(15,2) DEFAULT 0,
    total_referral_bonus_usd DECIMAL(15,2) DEFAULT 0,

    -- Métadonnées
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    last_login_at TIMESTAMPTZ,
    deleted_at TIMESTAMPTZ,
    is_active BOOLEAN DEFAULT TRUE,

    -- Contraintes
    CONSTRAINT valid_birth_date CHECK (birth_date <= CURRENT_DATE - INTERVAL '1 year'),
    CONSTRAINT child_has_parent CHECK (
        (user_role = 'child' AND parent_id IS NOT NULL) OR
        (user_role != 'child')
    ),
    CONSTRAINT adult_age CHECK (
        (user_role = 'adult' AND birth_date <= CURRENT_DATE - INTERVAL '18 years') OR
        (user_role != 'adult')
    )
);

-- TABLE: accounts
CREATE TABLE IF NOT EXISTS cryptopay.accounts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES cryptopay.users(id) ON DELETE CASCADE,

    -- Soldes
    balance_usd DECIMAL(15,8) DEFAULT 0 CHECK (balance_usd >= 0),
    balance_sats BIGINT DEFAULT 0 CHECK (balance_sats >= 0),
    balance_cdf DECIMAL(15,2) DEFAULT 0 CHECK (balance_cdf >= 0),

    -- Limites
    monthly_sent_usd DECIMAL(15,2) DEFAULT 0,
    monthly_received_usd DECIMAL(15,2) DEFAULT 0,
    monthly_reset_at TIMESTAMPTZ DEFAULT NOW(),

    -- Lightning
    lightning_node_pubkey VARCHAR(66),
    last_lightning_sync_at TIMESTAMPTZ,

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    UNIQUE(user_id)
);

-- TABLE: transactions
CREATE TABLE IF NOT EXISTS cryptopay.transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    account_id UUID NOT NULL REFERENCES cryptopay.accounts(id),

    -- Type et montants
    transaction_type cryptopay.transaction_type_enum NOT NULL,
    amount_usd DECIMAL(15,8) NOT NULL,
    amount_sats BIGINT,
    fee_usd DECIMAL(15,8) DEFAULT 0,

    -- Destinataire / Expéditeur
    counterparty_user_id UUID REFERENCES cryptopay.users(id),
    counterparty_account_id UUID REFERENCES cryptopay.accounts(id),
    external_lightning_address TEXT,
    external_lightning_invoice TEXT,

    -- Lightning
    lightning_payment_hash VARCHAR(64),
    lightning_preimage VARCHAR(64),
    lightning_bolt11 TEXT,

    -- Statut
    status cryptopay.transaction_status_enum DEFAULT 'pending',
    status_reason TEXT,

    -- Métadonnées
    note TEXT,
    reference_number VARCHAR(50) UNIQUE,
    completed_at TIMESTAMPTZ,
    failed_at TIMESTAMPTZ,

    created_at TIMESTAMPTZ DEFAULT NOW(),

    CONSTRAINT valid_counterparty CHECK (
        (counterparty_user_id IS NOT NULL) OR
        (external_lightning_address IS NOT NULL) OR
        (transaction_type = 'conversion') OR
        (transaction_type = 'referral_bonus')
    )
);

-- TABLE: sessions
CREATE TABLE IF NOT EXISTS cryptopay.sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES cryptopay.users(id) ON DELETE CASCADE,
    jwt_token TEXT NOT NULL,
    refresh_token TEXT NOT NULL,
    device_name VARCHAR(255),
    device_type cryptopay.device_type_enum,
    device_fcm_token TEXT,
    ip_address INET,
    user_agent TEXT,
    expires_at TIMESTAMPTZ NOT NULL,
    revoked_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(refresh_token)
);

-- TABLE: limits
CREATE TABLE IF NOT EXISTS cryptopay.limits (
    kyc_level cryptopay.kyc_level_enum PRIMARY KEY,
    monthly_send_max_usd DECIMAL(15,2) NOT NULL,
    monthly_receive_max_usd DECIMAL(15,2) NOT NULL,
    max_per_transaction_usd DECIMAL(15,2) NOT NULL,
    fee_percentage DECIMAL(5,4) NOT NULL,
    fee_min_usd DECIMAL(15,2) DEFAULT 0.01
);

INSERT INTO cryptopay.limits (kyc_level, monthly_send_max_usd, monthly_receive_max_usd, max_per_transaction_usd, fee_percentage, fee_min_usd)
VALUES
    ('none', 100.00, 100.00, 50.00, 0.0100, 0.01),
    ('basic', 500.00, 500.00, 250.00, 0.0075, 0.01),
    ('verified', 2000.00, 5000.00, 1000.00, 0.0050, 0.01),
    ('premium', 50000.00, 100000.00, 10000.00, 0.0030, 0.01)
ON CONFLICT (kyc_level) DO NOTHING;

-- TABLE: child_limits
CREATE TABLE IF NOT EXISTS cryptopay.child_limits (
    child_user_id UUID PRIMARY KEY REFERENCES cryptopay.users(id) ON DELETE CASCADE,
    parent_user_id UUID NOT NULL REFERENCES cryptopay.users(id),
    max_per_transaction_usd DECIMAL(15,2) NOT NULL,
    max_per_day_usd DECIMAL(15,2) NOT NULL,
    max_per_month_usd DECIMAL(15,2) NOT NULL,
    requires_approval BOOLEAN DEFAULT TRUE,
    daily_spent_usd DECIMAL(15,2) DEFAULT 0,
    monthly_spent_usd DECIMAL(15,2) DEFAULT 0,
    last_reset_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- TABLE: pending_approvals
CREATE TABLE IF NOT EXISTS cryptopay.pending_approvals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    child_transaction_id UUID NOT NULL REFERENCES cryptopay.transactions(id),
    parent_user_id UUID NOT NULL REFERENCES cryptopay.users(id),
    status VARCHAR(20) DEFAULT 'pending', -- pending, approved, rejected
    approved_at TIMESTAMPTZ,
    rejected_at TIMESTAMPTZ,
    rejection_reason TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- TABLE: referrals
CREATE TABLE IF NOT EXISTS cryptopay.referrals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    referrer_user_id UUID NOT NULL REFERENCES cryptopay.users(id),
    referred_user_id UUID NOT NULL REFERENCES cryptopay.users(id),
    bonus_paid_to_referrer DECIMAL(15,2) DEFAULT 0,
    bonus_paid_to_referred DECIMAL(15,2) DEFAULT 0,
    status VARCHAR(20) DEFAULT 'pending', -- pending, completed
    completed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(referred_user_id)
);

-- TABLE: notifications
CREATE TABLE IF NOT EXISTS cryptopay.notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES cryptopay.users(id),
    title VARCHAR(255) NOT NULL,
    body TEXT NOT NULL,
    type VARCHAR(50) NOT NULL,
    metadata JSONB,
    is_read BOOLEAN DEFAULT FALSE,
    read_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- TABLE: kyc_documents
CREATE TABLE IF NOT EXISTS cryptopay.kyc_documents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES cryptopay.users(id),
    document_type VARCHAR(50) NOT NULL,
    document_url TEXT NOT NULL,
    status VARCHAR(20) DEFAULT 'pending',
    reviewed_by UUID REFERENCES cryptopay.users(id),
    reviewed_at TIMESTAMPTZ,
    rejection_reason TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- TABLE: exchange_rates
CREATE TABLE IF NOT EXISTS cryptopay.exchange_rates (
    id SERIAL PRIMARY KEY,
    from_currency VARCHAR(3) NOT NULL,
    to_currency VARCHAR(3) NOT NULL,
    rate DECIMAL(15,8) NOT NULL,
    source VARCHAR(50) DEFAULT 'coingecko',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(from_currency, to_currency)
);

INSERT INTO cryptopay.exchange_rates (from_currency, to_currency, rate) VALUES
    ('BTC', 'USD', 70000),
    ('USD', 'BTC', 0.00001428),
    ('USD', 'CDF', 2800),
    ('CDF', 'USD', 0.000357)
ON CONFLICT (from_currency, to_currency) DO NOTHING;

-------------------------------------------------
-- FUNCTIONS & TRIGGERS
-------------------------------------------------

CREATE OR REPLACE FUNCTION cryptopay.update_updated_at_column()
RETURNS TRIGGER AS $$ BEGIN NEW.updated_at = NOW(); RETURN NEW; END; $$ LANGUAGE plpgsql;

CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON cryptopay.users FOR EACH ROW EXECUTE FUNCTION cryptopay.update_updated_at_column();
CREATE TRIGGER update_accounts_updated_at BEFORE UPDATE ON cryptopay.accounts FOR EACH ROW EXECUTE FUNCTION cryptopay.update_updated_at_column();
CREATE TRIGGER update_child_limits_updated_at BEFORE UPDATE ON cryptopay.child_limits FOR EACH ROW EXECUTE FUNCTION cryptopay.update_updated_at_column();

-- 1. register_user
CREATE OR REPLACE FUNCTION cryptopay.register_user(
    p_email VARCHAR(255),
    p_phone VARCHAR(50),
    p_full_name VARCHAR(255),
    p_birth_date DATE,
    p_pin_hash TEXT,
    p_pin_salt TEXT DEFAULT NULL,
    p_referral_code VARCHAR(20) DEFAULT NULL,
    p_user_role cryptopay.user_role_enum DEFAULT 'adult',
    p_parent_id UUID DEFAULT NULL
)
RETURNS TABLE(user_id UUID, account_id UUID, referral_code VARCHAR(20), message TEXT) AS $$
DECLARE v_user_id UUID; v_account_id UUID; v_referral_code VARCHAR(20); v_referrer_id UUID;
BEGIN
    IF EXISTS (SELECT 1 FROM cryptopay.users WHERE email = p_email AND deleted_at IS NULL) THEN
        RETURN QUERY SELECT NULL::UUID, NULL::UUID, NULL::VARCHAR, 'Email déjà utilisé'::TEXT; RETURN;
    END IF;
    IF EXISTS (SELECT 1 FROM cryptopay.users WHERE phone = p_phone AND deleted_at IS NULL) THEN
        RETURN QUERY SELECT NULL::UUID, NULL::UUID, NULL::VARCHAR, 'Téléphone déjà utilisé'::TEXT; RETURN;
    END IF;
    IF p_user_role = 'adult' AND p_birth_date > CURRENT_DATE - INTERVAL '18 years' THEN
        RETURN QUERY SELECT NULL::UUID, NULL::UUID, NULL::VARCHAR, 'Vous devez avoir 18 ans ou plus'::TEXT; RETURN;
    END IF;

    v_referral_code := UPPER(SUBSTRING(MD5(RANDOM()::TEXT) FROM 1 FOR 8));
    IF p_referral_code IS NOT NULL THEN
        SELECT id INTO v_referrer_id FROM cryptopay.users WHERE referral_code = p_referral_code AND deleted_at IS NULL;
    END IF;

    INSERT INTO cryptopay.users (email, phone, full_name, birth_date, encrypted_pin_hash, pin_salt, referral_code, referred_by, user_role, parent_id)
    VALUES (p_email, p_phone, p_full_name, p_birth_date, p_pin_hash, p_pin_salt, v_referral_code, v_referrer_id, p_user_role, p_parent_id)
    RETURNING id INTO v_user_id;

    INSERT INTO cryptopay.accounts (user_id) VALUES (v_user_id) RETURNING id INTO v_account_id;

    IF v_referrer_id IS NOT NULL THEN
        INSERT INTO cryptopay.referrals (referrer_user_id, referred_user_id, status) VALUES (v_referrer_id, v_user_id, 'pending');
    END IF;

    RETURN QUERY SELECT v_user_id, v_account_id, v_referral_code, 'Compte créé avec succès'::TEXT;
END; $$ LANGUAGE plpgsql SECURITY DEFINER;

-- 1.5 get_user_salt
CREATE OR REPLACE FUNCTION cryptopay.get_user_salt(p_identifier VARCHAR(255))
RETURNS TEXT AS $$
BEGIN
    RETURN (SELECT pin_salt FROM cryptopay.users WHERE (email = p_identifier OR phone = p_identifier) AND deleted_at IS NULL);
END; $$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. verify_login
CREATE OR REPLACE FUNCTION cryptopay.verify_login(p_identifier VARCHAR(255), p_pin_hash TEXT)
RETURNS TABLE(user_id UUID, full_name VARCHAR(255), user_role cryptopay.user_role_enum, kyc_level cryptopay.kyc_level_enum, is_valid BOOLEAN, message TEXT) AS $$
DECLARE v_user cryptopay.users%ROWTYPE;
BEGIN
    SELECT * INTO v_user FROM cryptopay.users WHERE (email = p_identifier OR phone = p_identifier) AND deleted_at IS NULL AND is_active = TRUE;
    IF NOT FOUND THEN
        RETURN QUERY SELECT NULL::UUID, NULL::VARCHAR, NULL::cryptopay.user_role_enum, NULL::cryptopay.kyc_level_enum, FALSE, 'Utilisateur non trouvé'::TEXT; RETURN;
    END IF;
    IF v_user.encrypted_pin_hash != p_pin_hash THEN
        RETURN QUERY SELECT NULL::UUID, NULL::VARCHAR, NULL::cryptopay.user_role_enum, NULL::cryptopay.kyc_level_enum, FALSE, 'PIN incorrect'::TEXT; RETURN;
    END IF;
    UPDATE cryptopay.users SET last_login_at = NOW() WHERE id = v_user.id;
    RETURN QUERY SELECT v_user.id, v_user.full_name, v_user.user_role, v_user.kyc_level, TRUE, 'Connexion réussie'::TEXT;
END; $$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. create_session
CREATE OR REPLACE FUNCTION cryptopay.create_session(p_user_id UUID, p_device_name VARCHAR(255), p_device_type cryptopay.device_type_enum, p_device_fcm_token TEXT, p_ip_address INET, p_user_agent TEXT)
RETURNS TABLE(session_id UUID, jwt_token TEXT, refresh_token TEXT, expires_at TIMESTAMPTZ) AS $$
DECLARE v_session_id UUID; v_refresh_token TEXT; v_expires_at TIMESTAMPTZ; v_jwt_token TEXT;
BEGIN
    v_session_id := gen_random_uuid();
    v_refresh_token := encode(gen_random_bytes(32), 'base64');
    v_expires_at := NOW() + INTERVAL '7 days';
    v_jwt_token := 'simulated_jwt_' || v_session_id; -- Normalement généré par Supabase Auth ou un service de token

    INSERT INTO cryptopay.sessions (id, user_id, jwt_token, refresh_token, device_name, device_type, device_fcm_token, ip_address, user_agent, expires_at)
    VALUES (v_session_id, p_user_id, v_jwt_token, v_refresh_token, p_device_name, p_device_type, p_device_fcm_token, p_ip_address, p_user_agent, v_expires_at);

    RETURN QUERY SELECT v_session_id, v_jwt_token, v_refresh_token, v_expires_at;
END; $$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. validate_session
CREATE OR REPLACE FUNCTION cryptopay.validate_session(p_jwt_token TEXT)
RETURNS TABLE(user_id UUID, is_valid BOOLEAN) AS $$
BEGIN
    RETURN QUERY SELECT s.user_id, (s.expires_at > NOW() AND s.revoked_at IS NULL) FROM cryptopay.sessions s WHERE s.jwt_token = p_jwt_token;
END; $$ LANGUAGE plpgsql SECURITY DEFINER;

-- 5. revoke_session
CREATE OR REPLACE FUNCTION cryptopay.revoke_session(p_jwt_token TEXT) RETURNS BOOLEAN AS $$
BEGIN
    UPDATE cryptopay.sessions SET revoked_at = NOW() WHERE jwt_token = p_jwt_token;
    RETURN FOUND;
END; $$ LANGUAGE plpgsql SECURITY DEFINER;

-- 6. change_pin
CREATE OR REPLACE FUNCTION cryptopay.change_pin(p_user_id UUID, p_old_pin_hash TEXT, p_new_pin_hash TEXT) RETURNS BOOLEAN AS $$
BEGIN
    UPDATE cryptopay.users SET encrypted_pin_hash = p_new_pin_hash WHERE id = p_user_id AND encrypted_pin_hash = p_old_pin_hash;
    RETURN FOUND;
END; $$ LANGUAGE plpgsql SECURITY DEFINER;

-- 7. delete_account
CREATE OR REPLACE FUNCTION cryptopay.delete_account(p_user_id UUID) RETURNS BOOLEAN AS $$
BEGIN
    UPDATE cryptopay.users SET deleted_at = NOW(), is_active = FALSE WHERE id = p_user_id;
    RETURN FOUND;
END; $$ LANGUAGE plpgsql SECURITY DEFINER;

-- 8. update_profile
CREATE OR REPLACE FUNCTION cryptopay.update_profile(p_user_id UUID, p_full_name VARCHAR(255) DEFAULT NULL, p_email VARCHAR(255) DEFAULT NULL, p_phone VARCHAR(50) DEFAULT NULL, p_preferred_currency VARCHAR(3) DEFAULT NULL, p_language VARCHAR(10) DEFAULT NULL, p_theme VARCHAR(10) DEFAULT NULL)
RETURNS BOOLEAN AS $$
BEGIN
    UPDATE cryptopay.users SET
        full_name = COALESCE(p_full_name, full_name),
        email = COALESCE(p_email, email),
        phone = COALESCE(p_phone, phone),
        preferred_currency = COALESCE(p_preferred_currency, preferred_currency),
        language = COALESCE(p_language, language),
        theme = COALESCE(p_theme, theme)
    WHERE id = p_user_id;
    RETURN FOUND;
END; $$ LANGUAGE plpgsql SECURITY DEFINER;

-- 9. send_payment
CREATE OR REPLACE FUNCTION cryptopay.send_payment(
    p_sender_user_id UUID,
    p_amount_usd DECIMAL(15,8),
    p_destination_type VARCHAR(20),
    p_destination_identifier VARCHAR(500),
    p_note TEXT DEFAULT NULL,
    p_requires_approval BOOLEAN DEFAULT FALSE
)
RETURNS TABLE(transaction_id UUID, status VARCHAR(20), lightning_preimage TEXT, message TEXT) AS $$
DECLARE
    v_sender_account_id UUID;
    v_sender_balance DECIMAL(15,8);
    v_fee_usd DECIMAL(15,8);
    v_total_usd DECIMAL(15,8);
    v_limit cryptopay.limits%ROWTYPE;
    v_receiver_user_id UUID;
    v_receiver_account_id UUID;
    v_tx_id UUID;
    v_child_limit cryptopay.child_limits%ROWTYPE;
BEGIN
    SELECT id, balance_usd INTO v_sender_account_id, v_sender_balance FROM cryptopay.accounts WHERE user_id = p_sender_user_id;
    SELECT l.* INTO v_limit FROM cryptopay.limits l JOIN cryptopay.users u ON u.kyc_level = l.kyc_level WHERE u.id = p_sender_user_id;
    v_fee_usd := GREATEST(p_amount_usd * v_limit.fee_percentage, v_limit.fee_min_usd);
    v_total_usd := p_amount_usd + v_fee_usd;

    IF v_sender_balance < v_total_usd THEN
        RETURN QUERY SELECT NULL::UUID, 'failed'::VARCHAR, NULL::TEXT, 'Solde insuffisant'::TEXT; RETURN;
    END IF;

    IF EXISTS (SELECT 1 FROM cryptopay.users WHERE id = p_sender_user_id AND user_role = 'child') THEN
        SELECT * INTO v_child_limit FROM cryptopay.child_limits WHERE child_user_id = p_sender_user_id;
        IF p_amount_usd > v_child_limit.max_per_transaction_usd THEN
            RETURN QUERY SELECT NULL::UUID, 'failed'::VARCHAR, NULL::TEXT, 'Limite par transaction dépassée'::TEXT; RETURN;
        END IF;
        IF v_child_limit.daily_spent_usd + p_amount_usd > v_child_limit.max_per_day_usd THEN
            RETURN QUERY SELECT NULL::UUID, 'failed'::VARCHAR, NULL::TEXT, 'Limite quotidienne dépassée'::TEXT; RETURN;
        END IF;
        IF v_child_limit.monthly_spent_usd + p_amount_usd > v_child_limit.max_per_month_usd THEN
            RETURN QUERY SELECT NULL::UUID, 'failed'::VARCHAR, NULL::TEXT, 'Limite mensuelle dépassée'::TEXT; RETURN;
        END IF;
    END IF;

    IF EXISTS (SELECT 1 FROM cryptopay.users WHERE id = p_sender_user_id AND user_role = 'child') AND v_child_limit.requires_approval AND NOT p_requires_approval THEN
        IF p_destination_type = 'internal' THEN
            SELECT id INTO v_receiver_user_id FROM cryptopay.users WHERE (email = p_destination_identifier OR phone = p_destination_identifier OR id::TEXT = p_destination_identifier) AND deleted_at IS NULL;
            IF NOT FOUND THEN
                RETURN QUERY SELECT NULL::UUID, 'failed'::VARCHAR, NULL::TEXT, 'Destinataire non trouvé'::TEXT; RETURN;
            END IF;
            SELECT id INTO v_receiver_account_id FROM cryptopay.accounts WHERE user_id = v_receiver_user_id;
            INSERT INTO cryptopay.transactions (account_id, transaction_type, amount_usd, fee_usd, counterparty_user_id, counterparty_account_id, note, status)
            VALUES (v_sender_account_id, 'send', p_amount_usd, v_fee_usd, v_receiver_user_id, v_receiver_account_id, p_note, 'pending') RETURNING id INTO v_tx_id;
        ELSIF p_destination_type = 'lightning' THEN
            INSERT INTO cryptopay.transactions (account_id, transaction_type, amount_usd, fee_usd, external_lightning_invoice, note, status)
            VALUES (v_sender_account_id, 'send', p_amount_usd, v_fee_usd, p_destination_identifier, p_note, 'pending') RETURNING id INTO v_tx_id;
        ELSE
            RETURN QUERY SELECT NULL::UUID, 'failed'::VARCHAR, NULL::TEXT, 'Destination non gérée'::TEXT; RETURN;
        END IF;

        INSERT INTO cryptopay.pending_approvals (child_transaction_id, parent_user_id)
        VALUES (v_tx_id, (SELECT parent_id FROM cryptopay.users WHERE id = p_sender_user_id));

        RETURN QUERY SELECT v_tx_id, 'pending_approval'::VARCHAR, NULL::TEXT, 'En attente d''approbation parentale'::TEXT;
    END IF;

    IF p_destination_type = 'internal' THEN
        SELECT id INTO v_receiver_user_id FROM cryptopay.users WHERE (email = p_destination_identifier OR phone = p_destination_identifier OR id::TEXT = p_destination_identifier) AND deleted_at IS NULL;
        IF NOT FOUND THEN
            RETURN QUERY SELECT NULL::UUID, 'failed'::VARCHAR, NULL::TEXT, 'Destinataire non trouvé'::TEXT; RETURN;
        END IF;
        SELECT id INTO v_receiver_account_id FROM cryptopay.accounts WHERE user_id = v_receiver_user_id;

        UPDATE cryptopay.accounts
        SET balance_usd = balance_usd - v_total_usd,
            monthly_sent_usd = monthly_sent_usd + p_amount_usd
        WHERE id = v_sender_account_id;

        UPDATE cryptopay.accounts
        SET balance_usd = balance_usd + p_amount_usd,
            monthly_received_usd = monthly_received_usd + p_amount_usd
        WHERE id = v_receiver_account_id;

        INSERT INTO cryptopay.transactions (account_id, transaction_type, amount_usd, fee_usd, counterparty_user_id, counterparty_account_id, note, status, completed_at)
        VALUES (v_sender_account_id, 'send', p_amount_usd, v_fee_usd, v_receiver_user_id, v_receiver_account_id, p_note, 'completed', NOW()) RETURNING id INTO v_tx_id;

        INSERT INTO cryptopay.transactions (account_id, transaction_type, amount_usd, fee_usd, counterparty_user_id, counterparty_account_id, note, status, completed_at)
        VALUES (v_receiver_account_id, 'receive', p_amount_usd, 0, p_sender_user_id, v_sender_account_id, p_note, 'completed', NOW());

        IF EXISTS (SELECT 1 FROM cryptopay.users WHERE id = p_sender_user_id AND user_role = 'child') THEN
            UPDATE cryptopay.child_limits
            SET daily_spent_usd = daily_spent_usd + p_amount_usd,
                monthly_spent_usd = monthly_spent_usd + p_amount_usd
            WHERE child_user_id = p_sender_user_id;
        END IF;

        RETURN QUERY SELECT v_tx_id, 'completed'::VARCHAR, NULL::TEXT, 'Paiement effectué'::TEXT;
    ELSIF p_destination_type = 'lightning' THEN
        UPDATE cryptopay.accounts
        SET balance_usd = balance_usd - v_total_usd,
            monthly_sent_usd = monthly_sent_usd + p_amount_usd
        WHERE id = v_sender_account_id;

        INSERT INTO cryptopay.transactions (account_id, transaction_type, amount_usd, fee_usd, external_lightning_invoice, note, status, completed_at)
        VALUES (v_sender_account_id, 'send', p_amount_usd, v_fee_usd, p_destination_identifier, p_note, 'completed', NOW()) RETURNING id INTO v_tx_id;

        IF EXISTS (SELECT 1 FROM cryptopay.users WHERE id = p_sender_user_id AND user_role = 'child') THEN
            UPDATE cryptopay.child_limits
            SET daily_spent_usd = daily_spent_usd + p_amount_usd,
                monthly_spent_usd = monthly_spent_usd + p_amount_usd
            WHERE child_user_id = p_sender_user_id;
        END IF;

        RETURN QUERY SELECT v_tx_id, 'completed'::VARCHAR, 'fake_preimage'::TEXT, 'Paiement Lightning effectué'::TEXT;
    ELSE
        RETURN QUERY SELECT NULL::UUID, 'failed'::VARCHAR, NULL::TEXT, 'Destination non gérée'::TEXT;
    END IF;
END; $$ LANGUAGE plpgsql SECURITY DEFINER;

-- 10. create_lightning_invoice
CREATE OR REPLACE FUNCTION cryptopay.create_lightning_invoice(p_user_id UUID, p_amount_usd DECIMAL(15,8), p_memo TEXT DEFAULT NULL)
RETURNS TABLE(invoice_id UUID, bolt11 TEXT, amount_sats BIGINT) AS $$
DECLARE v_acc_id UUID; v_rate DECIMAL; v_sats BIGINT; v_bolt11 TEXT;
BEGIN
    SELECT id INTO v_acc_id FROM cryptopay.accounts WHERE user_id = p_user_id;
    SELECT rate INTO v_rate FROM cryptopay.exchange_rates WHERE from_currency = 'BTC' AND to_currency = 'USD';
    v_sats := (p_amount_usd / v_rate * 100000000)::BIGINT;
    v_bolt11 := 'lnbc' || encode(gen_random_bytes(32), 'hex');

    INSERT INTO cryptopay.transactions (account_id, transaction_type, amount_usd, amount_sats, lightning_bolt11, note, status)
    VALUES (v_acc_id, 'receive', p_amount_usd, v_sats, v_bolt11, p_memo, 'pending') RETURNING id INTO invoice_id;

    RETURN QUERY SELECT invoice_id, v_bolt11, v_sats;
END; $$ LANGUAGE plpgsql SECURITY DEFINER;

-- 11. deposit_funds
CREATE OR REPLACE FUNCTION cryptopay.deposit_funds(p_user_id UUID, p_amount_usd DECIMAL(15,8), p_source VARCHAR(100) DEFAULT 'partner', p_note TEXT DEFAULT NULL)
RETURNS TABLE(transaction_id UUID, status VARCHAR(20), message TEXT) AS $$
DECLARE v_acc_id UUID; v_tx_id UUID;
BEGIN
    SELECT id INTO v_acc_id FROM cryptopay.accounts WHERE user_id = p_user_id;
    UPDATE cryptopay.accounts
    SET balance_usd = balance_usd + p_amount_usd,
        monthly_received_usd = monthly_received_usd + p_amount_usd
    WHERE id = v_acc_id;

    INSERT INTO cryptopay.transactions (account_id, transaction_type, amount_usd, fee_usd, note, status, completed_at, external_lightning_address)
    VALUES (v_acc_id, 'receive', p_amount_usd, 0, COALESCE(p_note, 'Recharge via partenaire'), 'completed', NOW(), p_source)
    RETURNING id INTO v_tx_id;

    RETURN QUERY SELECT v_tx_id, 'completed'::VARCHAR, 'Compte alimenté avec succès'::TEXT;
END; $$ LANGUAGE plpgsql SECURITY DEFINER;

-- 12. confirm_lightning_payment
CREATE OR REPLACE FUNCTION cryptopay.confirm_lightning_payment(p_payment_hash VARCHAR(64), p_preimage VARCHAR(64)) RETURNS BOOLEAN AS $$
DECLARE v_amount DECIMAL; v_acc_id UUID;
BEGIN
    UPDATE cryptopay.transactions SET status = 'completed', lightning_preimage = p_preimage, completed_at = NOW()
    WHERE lightning_payment_hash = p_payment_hash AND status = 'pending'
    RETURNING amount_usd, account_id INTO v_amount, v_acc_id;

    IF FOUND THEN
        UPDATE cryptopay.accounts SET balance_usd = balance_usd + v_amount WHERE id = v_acc_id;
        RETURN TRUE;
    END IF;
    RETURN FALSE;
END; $$ LANGUAGE plpgsql SECURITY DEFINER;

-- 12. get_balance
CREATE OR REPLACE FUNCTION cryptopay.get_balance(p_user_id UUID)
RETURNS TABLE(balance_usd DECIMAL(15,8), balance_sats BIGINT, balance_cdf DECIMAL(15,2), monthly_sent_usd DECIMAL(15,2), monthly_received_usd DECIMAL(15,2), limit_remaining_usd DECIMAL(15,2)) AS $$
DECLARE v_kyc cryptopay.kyc_level_enum; v_lim DECIMAL; v_rate_cdf DECIMAL;
BEGIN
    SELECT u.kyc_level, a.balance_usd, a.balance_sats, a.balance_cdf, a.monthly_sent_usd, a.monthly_received_usd
    INTO v_kyc, balance_usd, balance_sats, balance_cdf, monthly_sent_usd, monthly_received_usd
    FROM cryptopay.accounts a JOIN cryptopay.users u ON u.id = a.user_id WHERE a.user_id = p_user_id;

    SELECT monthly_send_max_usd INTO v_lim FROM cryptopay.limits WHERE kyc_level = v_kyc;
    limit_remaining_usd := GREATEST(0, v_lim - monthly_sent_usd);

    SELECT rate INTO v_rate_cdf FROM cryptopay.exchange_rates WHERE from_currency = 'USD' AND to_currency = 'CDF';
    balance_cdf := balance_usd * v_rate_cdf;
    RETURN NEXT;
END; $$ LANGUAGE plpgsql SECURITY DEFINER;

-- 13. get_transaction_history
CREATE OR REPLACE FUNCTION cryptopay.get_transaction_history(p_user_id UUID, p_limit INT DEFAULT 20, p_offset INT DEFAULT 0, p_transaction_type cryptopay.transaction_type_enum DEFAULT NULL)
RETURNS TABLE(id UUID, amount_usd DECIMAL(15,8), fee_usd DECIMAL(15,8), counterparty_name VARCHAR(255), transaction_type VARCHAR(20), note TEXT, status VARCHAR(20), created_at TIMESTAMPTZ, is_incoming BOOLEAN) AS $$
BEGIN
    RETURN QUERY SELECT t.id, t.amount_usd, t.fee_usd, (SELECT u.full_name FROM cryptopay.users u WHERE u.id = t.counterparty_user_id) AS counterparty_name, t.transaction_type::VARCHAR, t.note, t.status::VARCHAR, t.created_at, (t.transaction_type = 'receive') AS is_incoming
    FROM cryptopay.transactions t JOIN cryptopay.accounts a ON a.id = t.account_id WHERE a.user_id = p_user_id AND (p_transaction_type IS NULL OR t.transaction_type = p_transaction_type) ORDER BY t.created_at DESC LIMIT p_limit OFFSET p_offset;
END; $$ LANGUAGE plpgsql SECURITY DEFINER;

-- 14. get_transaction_detail
CREATE OR REPLACE FUNCTION cryptopay.get_transaction_detail(p_transaction_id UUID)
RETURNS TABLE(id UUID, amount_usd DECIMAL(15,8), amount_sats BIGINT, fee_usd DECIMAL(15,8), transaction_type VARCHAR(20), counterparty_name VARCHAR(255), note TEXT, status VARCHAR(20), reference_number VARCHAR(50), created_at TIMESTAMPTZ, completed_at TIMESTAMPTZ) AS $$
BEGIN
    RETURN QUERY SELECT t.id, t.amount_usd, t.amount_sats, t.fee_usd, t.transaction_type::VARCHAR, (SELECT u.full_name FROM cryptopay.users u WHERE u.id = t.counterparty_user_id) AS counterparty_name, t.note, t.status::VARCHAR, t.reference_number, t.created_at, t.completed_at
    FROM cryptopay.transactions t WHERE t.id = p_transaction_id;
END; $$ LANGUAGE plpgsql SECURITY DEFINER;

-- 15. search_users
CREATE OR REPLACE FUNCTION cryptopay.search_users(p_search_term TEXT, p_limit INT DEFAULT 10)
RETURNS TABLE(id UUID, full_name VARCHAR(255), email VARCHAR(255), phone VARCHAR(50), referral_code VARCHAR(20), user_role VARCHAR(20), avatar_url TEXT) AS $$
BEGIN
    RETURN QUERY SELECT u.id, u.full_name, u.email, u.phone, u.referral_code, u.user_role::VARCHAR, NULL::TEXT FROM cryptopay.users u
    WHERE u.deleted_at IS NULL AND u.is_active = TRUE AND (u.full_name ILIKE '%' || p_search_term || '%' OR u.email ILIKE '%' || p_search_term || '%' OR u.phone ILIKE '%' || p_search_term || '%' OR u.referral_code ILIKE '%' || p_search_term || '%')
    ORDER BY u.full_name LIMIT p_limit;
END; $$ LANGUAGE plpgsql SECURITY DEFINER;

-- 16. export_transactions_csv
CREATE OR REPLACE FUNCTION cryptopay.export_transactions_csv(p_user_id UUID) RETURNS TEXT AS $$
BEGIN
    RETURN 'date,amount,type' || E'\n' || (SELECT string_agg(created_at::text || ',' || amount_usd::text || ',' || transaction_type::text, E'\n') FROM cryptopay.transactions t JOIN cryptopay.accounts a ON a.id = t.account_id WHERE a.user_id = p_user_id);
END; $$ LANGUAGE plpgsql SECURITY DEFINER;

-- 17. create_child_account
CREATE OR REPLACE FUNCTION cryptopay.create_child_account(p_parent_user_id UUID, p_child_full_name VARCHAR(255), p_child_birth_date DATE, p_max_per_transaction_usd DECIMAL(15,2), p_max_per_day_usd DECIMAL(15,2), p_max_per_month_usd DECIMAL(15,2), p_requires_approval BOOLEAN DEFAULT TRUE)
RETURNS TABLE(child_user_id UUID, invitation_code VARCHAR(8), message TEXT) AS $$
DECLARE v_child_id UUID; v_code VARCHAR(8);
BEGIN
    IF NOT EXISTS (SELECT 1 FROM cryptopay.users WHERE id = p_parent_user_id AND user_role = 'adult') THEN
        RETURN QUERY SELECT NULL::UUID, NULL::VARCHAR, 'Parent non trouvé'::TEXT; RETURN;
    END IF;
    v_code := UPPER(SUBSTRING(MD5(RANDOM()::TEXT) FROM 1 FOR 8));
    INSERT INTO cryptopay.users (email, phone, full_name, birth_date, user_role, parent_id, encrypted_pin_hash, pin_salt, is_active)
    VALUES ('pending_' || v_code || '@crypto-pay.com', 'pending_' || v_code, p_child_full_name, p_child_birth_date, 'child', p_parent_user_id, 'pending', 'pending', FALSE)
    RETURNING id INTO v_child_id;

    INSERT INTO cryptopay.accounts (user_id) VALUES (v_child_id);
    INSERT INTO cryptopay.child_limits (child_user_id, parent_user_id, max_per_transaction_usd, max_per_day_usd, max_per_month_usd, requires_approval)
    VALUES (v_child_id, p_parent_user_id, p_max_per_transaction_usd, p_max_per_day_usd, p_max_per_month_usd, p_requires_approval);

    RETURN QUERY SELECT v_child_id, v_code, 'Compte enfant créé'::TEXT;
END; $$ LANGUAGE plpgsql SECURITY DEFINER;

-- 18. activate_child_account
CREATE OR REPLACE FUNCTION cryptopay.activate_child_account(p_child_id UUID, p_email VARCHAR, p_phone VARCHAR, p_pin_hash TEXT, p_pin_salt TEXT) RETURNS BOOLEAN AS $$
BEGIN
    UPDATE cryptopay.users SET email = p_email, phone = p_phone, encrypted_pin_hash = p_pin_hash, pin_salt = p_pin_salt, is_active = TRUE WHERE id = p_child_id;
    RETURN FOUND;
END; $$ LANGUAGE plpgsql SECURITY DEFINER;

-- 19. approve_child_transaction
CREATE OR REPLACE FUNCTION cryptopay.approve_child_transaction(p_parent_user_id UUID, p_pending_approval_id UUID, p_approve BOOLEAN, p_rejection_reason TEXT DEFAULT NULL)
RETURNS BOOLEAN AS $$
DECLARE 
    v_app cryptopay.pending_approvals%ROWTYPE;
    v_tx cryptopay.transactions%ROWTYPE;
    v_sender_account_id UUID;
    v_receiver_account_id UUID;
    v_fee_usd DECIMAL(15,8);
    v_total_usd DECIMAL(15,8);
    v_child_user_id UUID;
BEGIN
    SELECT * INTO v_app FROM cryptopay.pending_approvals WHERE id = p_pending_approval_id AND status = 'pending';
    IF NOT FOUND OR v_app.parent_user_id != p_parent_user_id THEN
        RETURN FALSE;
    END IF;

    SELECT * INTO v_tx FROM cryptopay.transactions WHERE id = v_app.child_transaction_id;
    IF NOT FOUND THEN
        RETURN FALSE;
    END IF;

    IF p_approve THEN
        UPDATE cryptopay.pending_approvals SET status = 'approved', approved_at = NOW() WHERE id = p_pending_approval_id;

        SELECT user_id INTO v_child_user_id FROM cryptopay.accounts WHERE id = v_tx.account_id;
        v_fee_usd := v_tx.fee_usd;

        IF v_tx.transaction_type = 'send' AND v_tx.external_lightning_invoice IS NULL THEN
            SELECT id INTO v_receiver_account_id FROM cryptopay.accounts WHERE user_id = v_tx.counterparty_user_id;
            UPDATE cryptopay.accounts SET balance_usd = balance_usd - (v_tx.amount_usd + v_fee_usd) WHERE id = v_sender_account_id;
            UPDATE cryptopay.accounts SET balance_usd = balance_usd + v_tx.amount_usd WHERE id = v_receiver_account_id;
            UPDATE cryptopay.transactions SET status = 'completed', completed_at = NOW() WHERE id = v_tx.id;
            UPDATE cryptopay.child_limits SET daily_spent_usd = daily_spent_usd + v_tx.amount_usd, monthly_spent_usd = monthly_spent_usd + v_tx.amount_usd WHERE child_user_id = v_child_user_id;
        ELSE
            UPDATE cryptopay.transactions SET status = 'completed', completed_at = NOW() WHERE id = v_tx.id;
            UPDATE cryptopay.accounts SET balance_usd = balance_usd - (v_tx.amount_usd + v_fee_usd) WHERE id = v_sender_account_id;
            UPDATE cryptopay.child_limits SET daily_spent_usd = daily_spent_usd + v_tx.amount_usd, monthly_spent_usd = monthly_spent_usd + v_tx.amount_usd WHERE child_user_id = v_child_user_id;
        END IF;
    ELSE
        UPDATE cryptopay.pending_approvals SET status = 'rejected', rejected_at = NOW(), rejection_reason = p_rejection_reason WHERE id = p_pending_approval_id;
        UPDATE cryptopay.transactions SET status = 'failed', status_reason = 'Rejetée par le parent' WHERE id = v_app.child_transaction_id;
    END IF;

    RETURN TRUE;
END; $$ LANGUAGE plpgsql SECURITY DEFINER;

-- 20. get_child_limits
CREATE OR REPLACE FUNCTION cryptopay.get_child_limits(p_child_id UUID) RETURNS TABLE(max_tx DECIMAL, max_day DECIMAL, max_month DECIMAL, daily_spent DECIMAL, monthly_spent DECIMAL, requires_approval BOOLEAN) AS $$
BEGIN
    RETURN QUERY SELECT max_per_transaction_usd, max_per_day_usd, max_per_month_usd, daily_spent_usd, monthly_spent_usd, requires_approval FROM cryptopay.child_limits WHERE child_user_id = p_child_id;
END; $$ LANGUAGE plpgsql SECURITY DEFINER;

-- 21. update_child_limits
CREATE OR REPLACE FUNCTION cryptopay.update_child_limits(p_child_id UUID, p_max_tx DECIMAL, p_max_day DECIMAL, p_max_month DECIMAL, p_requires_approval BOOLEAN) RETURNS BOOLEAN AS $$
BEGIN
    UPDATE cryptopay.child_limits SET max_per_transaction_usd = p_max_tx, max_per_day_usd = p_max_day, max_per_month_usd = p_max_month, requires_approval = p_requires_approval WHERE child_user_id = p_child_id;
    RETURN FOUND;
END; $$ LANGUAGE plpgsql SECURITY DEFINER;

-- 22. get_referral_info
CREATE OR REPLACE FUNCTION cryptopay.get_referral_info(p_user_id UUID) RETURNS TABLE(code VARCHAR, total_referred INT, bonus_earned DECIMAL) AS $$
BEGIN
    RETURN QUERY SELECT referral_code, (SELECT count(*)::int FROM cryptopay.referrals WHERE referrer_user_id = p_user_id AND status = 'completed'), total_referral_bonus_usd FROM cryptopay.users WHERE id = p_user_id;
END; $$ LANGUAGE plpgsql SECURITY DEFINER;

-- 23. claim_referral_bonus
CREATE OR REPLACE FUNCTION cryptopay.claim_referral_bonus(p_referred_user_id UUID) RETURNS BOOLEAN AS $$
DECLARE v_ref cryptopay.referrals%ROWTYPE;
BEGIN
    SELECT * INTO v_ref FROM cryptopay.referrals WHERE referred_user_id = p_referred_user_id AND status = 'pending';
    IF NOT FOUND THEN RETURN FALSE; END IF;
    UPDATE cryptopay.referrals SET status = 'completed', completed_at = NOW() WHERE id = v_ref.id;
    -- Créditer les bonus
    UPDATE cryptopay.accounts SET balance_usd = balance_usd + 5 WHERE user_id = v_ref.referrer_user_id;
    UPDATE cryptopay.accounts SET balance_usd = balance_usd + 2 WHERE user_id = v_ref.referred_user_id;
    RETURN TRUE;
END; $$ LANGUAGE plpgsql SECURITY DEFINER;

-- 24. list_referred_users
CREATE OR REPLACE FUNCTION cryptopay.list_referred_users(p_user_id UUID) RETURNS TABLE(full_name VARCHAR, joined_at TIMESTAMPTZ, status VARCHAR) AS $$
BEGIN
    RETURN QUERY SELECT u.full_name, r.created_at, r.status FROM cryptopay.referrals r JOIN cryptopay.users u ON u.id = r.referred_user_id WHERE r.referrer_user_id = p_user_id;
END; $$ LANGUAGE plpgsql SECURITY DEFINER;

-- 25. submit_kyc_document
CREATE OR REPLACE FUNCTION cryptopay.submit_kyc_document(p_user_id UUID, p_type VARCHAR, p_url TEXT) RETURNS UUID AS $$
DECLARE v_id UUID;
BEGIN
    INSERT INTO cryptopay.kyc_documents (user_id, document_type, document_url) VALUES (p_user_id, p_type, p_url) RETURNING id INTO v_id;
    UPDATE cryptopay.users SET kyc_level = 'basic' WHERE id = p_user_id AND kyc_level = 'none';
    RETURN v_id;
END; $$ LANGUAGE plpgsql SECURITY DEFINER;

-- 26. verify_kyc_document
CREATE OR REPLACE FUNCTION cryptopay.verify_kyc_document(p_doc_id UUID, p_approve BOOLEAN, p_reason TEXT DEFAULT NULL) RETURNS BOOLEAN AS $$
DECLARE v_uid UUID;
BEGIN
    UPDATE cryptopay.kyc_documents SET status = CASE WHEN p_approve THEN 'approved' ELSE 'rejected' END, rejection_reason = p_reason, reviewed_at = NOW() WHERE id = p_doc_id RETURNING user_id INTO v_uid;
    IF p_approve THEN
        UPDATE cryptopay.users SET kyc_level = 'verified', identity_verified_at = NOW() WHERE id = v_uid;
    END IF;
    RETURN FOUND;
END; $$ LANGUAGE plpgsql SECURITY DEFINER;

-- 27. get_kyc_status
CREATE OR REPLACE FUNCTION cryptopay.get_kyc_status(p_user_id UUID) RETURNS TABLE(level cryptopay.kyc_level_enum, documents_submitted INT, documents_approved INT) AS $$
BEGIN
    RETURN QUERY SELECT u.kyc_level, (SELECT count(*)::int FROM cryptopay.kyc_documents WHERE user_id = p_user_id), (SELECT count(*)::int FROM cryptopay.kyc_documents WHERE user_id = p_user_id AND status = 'approved') FROM cryptopay.users u WHERE u.id = p_user_id;
END; $$ LANGUAGE plpgsql SECURITY DEFINER;

-- 28. check_kyc_upgrade
CREATE OR REPLACE FUNCTION cryptopay.check_kyc_upgrade(p_user_id UUID) RETURNS BOOLEAN AS $$
BEGIN
    IF (SELECT count(*) FROM cryptopay.kyc_documents WHERE user_id = p_user_id AND status = 'approved') >= 1 THEN
        UPDATE cryptopay.users SET kyc_level = 'verified' WHERE id = p_user_id; RETURN TRUE;
    END IF;
    RETURN FALSE;
END; $$ LANGUAGE plpgsql SECURITY DEFINER;

-- 29. create_notification
CREATE OR REPLACE FUNCTION cryptopay.create_notification(p_user_id UUID, p_title VARCHAR, p_body TEXT, p_type VARCHAR, p_metadata JSONB DEFAULT NULL) RETURNS UUID AS $$
DECLARE v_id UUID;
BEGIN
    INSERT INTO cryptopay.notifications (user_id, title, body, type, metadata) VALUES (p_user_id, p_title, p_body, p_type, p_metadata) RETURNING id INTO v_id;
    RETURN v_id;
END; $$ LANGUAGE plpgsql SECURITY DEFINER;

-- 30. get_notifications
CREATE OR REPLACE FUNCTION cryptopay.get_notifications(p_user_id UUID, p_limit INT DEFAULT 20) RETURNS TABLE(id UUID, title VARCHAR, body TEXT, type VARCHAR, is_read BOOLEAN, created_at TIMESTAMPTZ) AS $$
BEGIN
    RETURN QUERY SELECT n.id, n.title, n.body, n.type, n.is_read, n.created_at FROM cryptopay.notifications n WHERE n.user_id = p_user_id ORDER BY created_at DESC LIMIT p_limit;
END; $$ LANGUAGE plpgsql SECURITY DEFINER;

-- 31. mark_notification_read
CREATE OR REPLACE FUNCTION cryptopay.mark_notification_read(p_notif_id UUID) RETURNS BOOLEAN AS $$
BEGIN
    UPDATE cryptopay.notifications SET is_read = TRUE, read_at = NOW() WHERE id = p_notif_id;
    RETURN FOUND;
END; $$ LANGUAGE plpgsql SECURITY DEFINER;

-- 32. admin_get_user_stats
CREATE OR REPLACE FUNCTION cryptopay.admin_get_user_stats() RETURNS TABLE(total_users BIGINT, active_users BIGINT, total_volume DECIMAL) AS $$
BEGIN
    RETURN QUERY SELECT count(*), count(*) FILTER (WHERE is_active), (SELECT sum(amount_usd) FROM cryptopay.transactions WHERE status = 'completed') FROM cryptopay.users;
END; $$ LANGUAGE plpgsql SECURITY DEFINER;

-- 33. admin_list_users
CREATE OR REPLACE FUNCTION cryptopay.admin_list_users() RETURNS TABLE(id UUID, full_name VARCHAR, email VARCHAR, kyc_level VARCHAR) AS $$
BEGIN
    RETURN QUERY SELECT u.id, u.full_name, u.email, u.kyc_level::VARCHAR FROM cryptopay.users u;
END; $$ LANGUAGE plpgsql SECURITY DEFINER;

-- 34. admin_force_reset_limits
CREATE OR REPLACE FUNCTION cryptopay.admin_force_reset_limits() RETURNS BOOLEAN AS $$
BEGIN
    UPDATE cryptopay.accounts SET monthly_sent_usd = 0, monthly_received_usd = 0, monthly_reset_at = NOW();
    RETURN TRUE;
END; $$ LANGUAGE plpgsql SECURITY DEFINER;

-- 35. admin_update_exchange_rate
CREATE OR REPLACE FUNCTION cryptopay.admin_update_exchange_rate(p_from VARCHAR, p_to VARCHAR, p_rate DECIMAL) RETURNS BOOLEAN AS $$
BEGIN
    INSERT INTO cryptopay.exchange_rates (from_currency, to_currency, rate) VALUES (p_from, p_to, p_rate)
    ON CONFLICT (from_currency, to_currency) DO UPDATE SET rate = p_rate, created_at = NOW();
    RETURN TRUE;
END; $$ LANGUAGE plpgsql SECURITY DEFINER;

-- 36. admin_get_daily_volume
CREATE OR REPLACE FUNCTION cryptopay.admin_get_daily_volume() RETURNS TABLE(day DATE, volume DECIMAL) AS $$
BEGIN
    RETURN QUERY SELECT created_at::date, sum(amount_usd) FROM cryptopay.transactions WHERE status = 'completed' GROUP BY 1 ORDER BY 1 DESC;
END; $$ LANGUAGE plpgsql SECURITY DEFINER;

-- 37. trigger_update_monthly_limits
CREATE OR REPLACE FUNCTION cryptopay.trigger_update_monthly_limits() RETURNS TRIGGER AS $$
BEGIN
    IF NEW.monthly_reset_at < date_trunc('month', now()) THEN
        NEW.monthly_sent_usd = 0; NEW.monthly_received_usd = 0; NEW.monthly_reset_at = now();
    END IF;
    RETURN NEW;
END; $$ LANGUAGE plpgsql;

-- 38. trigger_reset_child_daily_limits
CREATE OR REPLACE FUNCTION cryptopay.trigger_reset_child_daily_limits() RETURNS TRIGGER AS $$
BEGIN
    IF NEW.last_reset_at < date_trunc('day', now()) THEN
        NEW.daily_spent_usd = 0; NEW.last_reset_at = now();
    END IF;
    RETURN NEW;
END; $$ LANGUAGE plpgsql;

-- 39. trigger_generate_reference_number
CREATE OR REPLACE FUNCTION cryptopay.trigger_generate_reference_number() RETURNS TRIGGER AS $$
BEGIN
    IF NEW.reference_number IS NULL THEN
        NEW.reference_number = 'TX-' || to_char(now(), 'YYYYMMDD') || '-' || upper(substring(md5(random()::text) from 1 for 8));
    END IF;
    RETURN NEW;
END; $$ LANGUAGE plpgsql;

-- 40. trigger_notify_on_transaction
CREATE OR REPLACE FUNCTION cryptopay.trigger_notify_on_transaction() RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status = 'completed' AND (OLD.status IS DISTINCT FROM NEW.status) THEN
        PERFORM cryptopay.create_notification(
            (SELECT user_id FROM cryptopay.accounts WHERE id = NEW.account_id),
            'Transaction confirmée',
            'Votre paiement de ' || NEW.amount_usd || ' USD est confirmé.',
            'payment',
            jsonb_build_object('transaction_id', NEW.id)
        );
    END IF;
    RETURN NEW;
END; $$ LANGUAGE plpgsql;

-- 41. health_check
CREATE OR REPLACE FUNCTION cryptopay.health_check() RETURNS TEXT AS $$
BEGIN
    RETURN 'healthy';
END; $$ LANGUAGE plpgsql;

-- 42. cleanup_old_sessions
CREATE OR REPLACE FUNCTION cryptopay.cleanup_old_sessions() RETURNS INT AS $$
DECLARE v_count INT;
BEGIN
    DELETE FROM cryptopay.sessions WHERE expires_at < NOW(); GET DIAGNOSTICS v_count = ROW_COUNT; RETURN v_count;
END; $$ LANGUAGE plpgsql;

-- 43. get_db_version
CREATE OR REPLACE FUNCTION cryptopay.get_db_version() RETURNS TEXT AS $$
BEGIN
    RETURN 'Crypto-Pay DB v1.5.0';
END; $$ LANGUAGE plpgsql;

-- 44. get_pending_approvals
CREATE OR REPLACE FUNCTION cryptopay.get_pending_approvals(p_parent_user_id UUID)
RETURNS TABLE(id UUID, child_transaction_id UUID, amount_usd DECIMAL(15,8), note TEXT, created_at TIMESTAMPTZ) AS $$
BEGIN
    RETURN QUERY SELECT pa.id, pa.child_transaction_id, t.amount_usd, t.note, pa.created_at
    FROM cryptopay.pending_approvals pa
    JOIN cryptopay.transactions t ON t.id = pa.child_transaction_id
    WHERE pa.parent_user_id = p_parent_user_id AND pa.status = 'pending';
END; $$ LANGUAGE plpgsql SECURITY DEFINER;

-------------------------------------------------
-- SECURITY: ROW LEVEL SECURITY (RLS)
-------------------------------------------------

ALTER TABLE cryptopay.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE cryptopay.accounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE cryptopay.transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE cryptopay.sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE cryptopay.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE cryptopay.kyc_documents ENABLE ROW LEVEL SECURITY;

CREATE POLICY self_select ON cryptopay.users FOR SELECT USING (id = auth.uid());
CREATE POLICY self_update ON cryptopay.users FOR UPDATE USING (id = auth.uid());
CREATE POLICY parent_see_children ON cryptopay.users FOR SELECT USING (parent_id = auth.uid());

CREATE POLICY self_account ON cryptopay.accounts FOR ALL USING (user_id = auth.uid());

CREATE POLICY self_transactions ON cryptopay.transactions FOR SELECT USING (
    account_id IN (SELECT id FROM cryptopay.accounts WHERE user_id = auth.uid())
);

CREATE POLICY self_notifications ON cryptopay.notifications FOR ALL USING (user_id = auth.uid());

CREATE POLICY self_kyc ON cryptopay.kyc_documents FOR SELECT USING (user_id = auth.uid());
CREATE POLICY self_submit_kyc ON cryptopay.kyc_documents FOR INSERT WITH CHECK (user_id = auth.uid());
