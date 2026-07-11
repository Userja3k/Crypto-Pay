-- migration: add RPCs to handle NFC and Bluetooth-initiated payments

create or replace function cryptopay.record_nfc_payment(
  p_user_id uuid,
  p_amount_sats integer,
  p_bolt11 text,
  p_payment_hash text default null,
  p_counterparty_id uuid default null,
  p_note text default null
) returns json as $$
declare
  v_account_id uuid;
  v_tx json;
begin
  select id into v_account_id from accounts where user_id = p_user_id limit 1;
  if v_account_id is null then
    return json_build_object('status','error','message','account_not_found');
  end if;

  insert into transactions(account_id, transaction_type, amount_sats, amount_usd, lightning_bolt11, lightning_payment_hash, note, status)
  values (v_account_id, 'receive', p_amount_sats, (p_amount_sats::numeric/100000000)::double precision, p_bolt11, p_payment_hash, p_note, 'pending')
  returning row_to_json(transactions.*) into v_tx;

  perform cryptopay.create_notification(v_account_id, 'payment_pending', json_build_object('amount_sats', p_amount_sats, 'source','nfc'));

  return json_build_object('status','ok','transaction', v_tx);
end;
$$ language plpgsql security definer;


create or replace function cryptopay.record_bluetooth_payment(
  p_user_id uuid,
  p_amount_sats integer,
  p_bolt11 text,
  p_payment_hash text default null,
  p_counterparty_id uuid default null,
  p_note text default null
) returns json as $$
declare
  v_account_id uuid;
  v_tx json;
begin
  select id into v_account_id from accounts where user_id = p_user_id limit 1;
  if v_account_id is null then
    return json_build_object('status','error','message','account_not_found');
  end if;

  insert into transactions(account_id, transaction_type, amount_sats, amount_usd, lightning_bolt11, lightning_payment_hash, note, status)
  values (v_account_id, 'receive', p_amount_sats, (p_amount_sats::numeric/100000000)::double precision, p_bolt11, p_payment_hash, p_note, 'pending')
  returning row_to_json(transactions.*) into v_tx;

  perform cryptopay.create_notification(v_account_id, 'payment_pending', json_build_object('amount_sats', p_amount_sats, 'source','bluetooth'));

  return json_build_object('status','ok','transaction', v_tx);
end;
$$ language plpgsql security definer;
