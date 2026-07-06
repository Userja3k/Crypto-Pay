-- Patch migration: apply only updated functions and deposit_funds
-- Date: 2026-07-05
-- This patch contains CREATE OR REPLACE FUNCTION statements for:
--  - cryptopay.send_payment
--  - cryptopay.approve_child_transaction
--  - cryptopay.deposit_funds

SET search_path TO cryptopay, public;

-- 9. send_payment (patched)
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

-- 19. approve_child_transaction (patched to execute approved transactions)
CREATE OR REPLACE FUNCTION cryptopay.approve_child_transaction(p_parent_user_id UUID, p_pending_approval_id UUID, p_approve BOOLEAN, p_rejection_reason TEXT DEFAULT NULL)
RETURNS BOOLEAN AS $$
DECLARE 
    v_app cryptopay.pending_approvals%ROWTYPE;
    v_tx cryptopay.transactions%ROWTYPE;
    v_sender_account_id UUID;
    v_receiver_account_id UUID;
    v_fee_usd DECIMAL(15,8);
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
            UPDATE cryptopay.accounts SET balance_usd = balance_usd - (v_tx.amount_usd + v_fee_usd) WHERE id = v_tx.account_id;
            UPDATE cryptopay.accounts SET balance_usd = balance_usd + v_tx.amount_usd WHERE id = v_receiver_account_id;
            UPDATE cryptopay.transactions SET status = 'completed', completed_at = NOW() WHERE id = v_tx.id;
            UPDATE cryptopay.child_limits SET daily_spent_usd = daily_spent_usd + v_tx.amount_usd, monthly_spent_usd = monthly_spent_usd + v_tx.amount_usd WHERE child_user_id = v_child_user_id;
        ELSE
            -- For other types (e.g. lightning) just mark completed and deduct balance
            UPDATE cryptopay.transactions SET status = 'completed', completed_at = NOW() WHERE id = v_tx.id;
            UPDATE cryptopay.accounts SET balance_usd = balance_usd - (v_tx.amount_usd + v_fee_usd) WHERE id = v_tx.account_id;
            UPDATE cryptopay.child_limits SET daily_spent_usd = daily_spent_usd + v_tx.amount_usd, monthly_spent_usd = monthly_spent_usd + v_tx.amount_usd WHERE child_user_id = v_child_user_id;
        END IF;
    ELSE
        UPDATE cryptopay.pending_approvals SET status = 'rejected', rejected_at = NOW(), rejection_reason = p_rejection_reason WHERE id = p_pending_approval_id;
        UPDATE cryptopay.transactions SET status = 'failed', status_reason = 'Rejetée par le parent' WHERE id = v_app.child_transaction_id;
    END IF;

    RETURN TRUE;
END; $$ LANGUAGE plpgsql SECURITY DEFINER;

-- 11. deposit_funds (new)
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

-- End of patch
