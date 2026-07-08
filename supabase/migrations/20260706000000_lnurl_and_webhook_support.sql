-- Patch: LNURL, settings and webhook support
SET search_path TO cryptopay, public;

CREATE TABLE IF NOT EXISTS cryptopay.settings (
    key VARCHAR(100) PRIMARY KEY,
    value TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

INSERT INTO cryptopay.settings (key, value)
VALUES ('app_domain', 'https://crypto-pay.app')
ON CONFLICT (key) DO NOTHING;

CREATE OR REPLACE FUNCTION cryptopay.generate_lnurl_secret()
RETURNS VARCHAR(64) AS $$
BEGIN
    RETURN encode(gen_random_bytes(32), 'hex');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION cryptopay.create_lnurl_withdraw(
    p_user_id UUID,
    p_amount_sats BIGINT DEFAULT NULL,
    p_description TEXT DEFAULT NULL,
    p_expires_in_days INT DEFAULT 365
)
RETURNS TABLE(lnurl_secret VARCHAR(64), lnurl_url TEXT, expires_at TIMESTAMPTZ) AS $$
DECLARE
    v_secret VARCHAR(64);
    v_expires TIMESTAMPTZ;
    v_domain TEXT;
BEGIN
    SELECT value INTO v_domain FROM cryptopay.settings WHERE key = 'app_domain';
    IF v_domain IS NULL THEN
        v_domain := 'https://crypto-pay.app';
    END IF;

    v_secret := cryptopay.generate_lnurl_secret();
    v_expires := NOW() + (p_expires_in_days || ' days')::INTERVAL;

    INSERT INTO cryptopay.lnurl_withdraw (user_id, lnurl_secret, amount_sats, description, expires_at)
    VALUES (p_user_id, v_secret, p_amount_sats, p_description, v_expires);

    RETURN QUERY SELECT v_secret, v_domain || '/.well-known/lnurl/withdraw/' || v_secret, v_expires;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION cryptopay.get_lnurl_withdraw_info(p_lnurl_secret VARCHAR(64))
RETURNS TABLE(
    user_id UUID,
    amount_sats BIGINT,
    description TEXT,
    expires_at TIMESTAMPTZ,
    is_valid BOOLEAN
) AS $$
DECLARE v_withdraw cryptopay.lnurl_withdraw%ROWTYPE;
BEGIN
    SELECT * INTO v_withdraw FROM cryptopay.lnurl_withdraw WHERE lnurl_secret = p_lnurl_secret AND expires_at > NOW();

    IF NOT FOUND THEN
        RETURN QUERY SELECT NULL::UUID, NULL::BIGINT, NULL::TEXT, NULL::TIMESTAMPTZ, FALSE;
        RETURN;
    END IF;

    RETURN QUERY SELECT v_withdraw.user_id, v_withdraw.amount_sats, v_withdraw.description, v_withdraw.expires_at, TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION cryptopay.redeem_lnurl_withdraw(
    p_lnurl_secret VARCHAR(64),
    p_amount_sats BIGINT
)
RETURNS TABLE(success BOOLEAN, message TEXT) AS $$
DECLARE
    v_withdraw cryptopay.lnurl_withdraw%ROWTYPE;
    v_account cryptopay.accounts%ROWTYPE;
    v_rate DECIMAL(15,8);
    v_amount_usd DECIMAL(15,8);
    v_tx_id UUID;
BEGIN
    SELECT * INTO v_withdraw FROM cryptopay.lnurl_withdraw WHERE lnurl_secret = p_lnurl_secret AND expires_at > NOW();

    IF NOT FOUND THEN
        RETURN QUERY SELECT FALSE, 'LNURL invalide ou expiré'::TEXT;
        RETURN;
    END IF;

    SELECT * INTO v_account FROM cryptopay.accounts WHERE user_id = v_withdraw.user_id;
    IF NOT FOUND THEN
        RETURN QUERY SELECT FALSE, 'Compte utilisateur introuvable'::TEXT;
        RETURN;
    END IF;

    IF v_withdraw.amount_sats IS NOT NULL AND v_withdraw.amount_sats <> p_amount_sats THEN
        RETURN QUERY SELECT FALSE, 'Montant incorrect'::TEXT;
        RETURN;
    END IF;

    IF v_account.balance_sats < p_amount_sats THEN
        RETURN QUERY SELECT FALSE, 'Solde insuffisant'::TEXT;
        RETURN;
    END IF;

    SELECT rate INTO v_rate FROM cryptopay.exchange_rates WHERE from_currency = 'BTC' AND to_currency = 'USD';
    IF v_rate IS NULL THEN
        v_rate := 0;
    END IF;

    v_amount_usd := (p_amount_sats / 100000000.0) * v_rate;

    UPDATE cryptopay.accounts
    SET balance_sats = balance_sats - p_amount_sats,
        balance_usd = GREATEST(0, balance_usd - v_amount_usd)
    WHERE id = v_account.id;

    UPDATE cryptopay.lnurl_withdraw SET expires_at = NOW() WHERE id = v_withdraw.id;

    INSERT INTO cryptopay.transactions (
        account_id,
        transaction_type,
        amount_usd,
        amount_sats,
        status,
        note,
        created_at,
        completed_at
    ) VALUES (
        v_account.id,
        'send',
        v_amount_usd,
        p_amount_sats,
        'completed',
        COALESCE(v_withdraw.description, 'Retrait LNURL'),
        NOW(),
        NOW()
    ) RETURNING id INTO v_tx_id;

    RETURN QUERY SELECT TRUE, 'Retrait traité'::TEXT;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION cryptopay.refund_failed_payment(p_payment_hash VARCHAR(64))
RETURNS BOOLEAN AS $$
DECLARE
    v_tx cryptopay.transactions%ROWTYPE;
BEGIN
    SELECT * INTO v_tx
    FROM cryptopay.transactions
    WHERE lightning_payment_hash = p_payment_hash AND status = 'failed';

    IF NOT FOUND THEN
        RETURN FALSE;
    END IF;

    UPDATE cryptopay.accounts
    SET balance_usd = balance_usd + v_tx.amount_usd
    WHERE id = v_tx.account_id;

    UPDATE cryptopay.transactions
    SET status = 'refunded', completed_at = NOW(), status_reason = 'Remboursé après échec'
    WHERE id = v_tx.id;

    RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION cryptopay.send_child_invitation(
    p_parent_user_id UUID,
    p_child_user_id UUID,
    p_invitation_code VARCHAR(8)
)
RETURNS BOOLEAN AS $$
BEGIN
    PERFORM cryptopay.create_notification(
        p_parent_user_id,
        'Invitation enfant envoyée',
        'Votre enfant a été invité. Code: ' || p_invitation_code,
        'child_invitation',
        jsonb_build_object('child_user_id', p_child_user_id, 'invitation_code', p_invitation_code)
    );

    UPDATE cryptopay.users
    SET is_active = TRUE
    WHERE id = p_child_user_id;

    RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION cryptopay.activate_child_with_code(
    p_child_user_id UUID,
    p_invitation_code VARCHAR(8),
    p_email VARCHAR(255),
    p_phone VARCHAR(50),
    p_pin_hash TEXT,
    p_pin_salt TEXT
)
RETURNS TABLE(success BOOLEAN, message TEXT) AS $$
DECLARE
    v_parent_id UUID;
BEGIN
    SELECT parent_id INTO v_parent_id
    FROM cryptopay.users
    WHERE id = p_child_user_id
      AND is_active = FALSE
      AND email LIKE 'pending_%'
      AND email LIKE '%' || p_invitation_code || '%';

    IF NOT FOUND THEN
        RETURN QUERY SELECT FALSE, 'Code d''invitation invalide'::TEXT;
        RETURN;
    END IF;

    UPDATE cryptopay.users
    SET email = p_email,
        phone = p_phone,
        encrypted_pin_hash = p_pin_hash,
        pin_salt = p_pin_salt,
        is_active = TRUE,
        updated_at = NOW()
    WHERE id = p_child_user_id;

    PERFORM cryptopay.create_notification(
        v_parent_id,
        'Enfant activé 🎉',
        'Votre enfant a activé son compte Crypto-Pay.',
        'child_activated',
        jsonb_build_object('child_user_id', p_child_user_id)
    );

    RETURN QUERY SELECT TRUE, 'Compte activé avec succès'::TEXT;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
