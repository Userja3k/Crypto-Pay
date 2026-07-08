import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.38.0';
import { crypto } from 'https://deno.land/std@0.177.0/crypto/mod.ts';

const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
const supabaseServiceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
const webhookSecret = Deno.env.get('BREEZ_WEBHOOK_SECRET') ?? '';
const supabase = createClient(supabaseUrl, supabaseServiceRoleKey);

serve(async (req) => {
  if (req.method !== 'POST') {
    return new Response('Method not allowed', { status: 405 });
  }

  const signature = req.headers.get('x-webhook-signature') ?? '';
  const body = await req.text();
  const isValid = await verifySignature(body, signature);

  if (!isValid) {
    return new Response('Invalid signature', { status: 401 });
  }

  try {
    const payload = JSON.parse(body);
    const eventType = payload.event;

    switch (eventType) {
      case 'payment_received':
        await handlePaymentReceived(payload.data);
        break;
      case 'payment_sent':
        await handlePaymentSent(payload.data);
        break;
      case 'payment_failed':
        await handlePaymentFailed(payload.data);
        break;
      default:
        break;
    }

    return new Response('OK', { status: 200 });
  } catch (error) {
    console.error(error);
    return new Response('Error', { status: 500 });
  }
});

async function verifySignature(body: string, signature: string): Promise<boolean> {
  if (!webhookSecret) return true;
  try {
    const encoder = new TextEncoder();
    const key = await crypto.subtle.importKey(
      'raw',
      encoder.encode(webhookSecret),
      { name: 'HMAC', hash: 'SHA-256' },
      false,
      ['verify'],
    );

    const signatureBytes = Uint8Array.from(
      signature.match(/.{1,2}/g)?.map((byte) => parseInt(byte, 16)) ?? []
    );

    return await crypto.subtle.verify('HMAC', key, signatureBytes, encoder.encode(body));
  } catch {
    return false;
  }
}

async function handlePaymentReceived(data: any) {
  const { payment_hash, preimage, amount_msat } = data;
  const amountSats = Math.round(parseInt(amount_msat, 10) / 1000);

  await supabase.from('transactions').update({
    status: 'completed',
    lightning_preimage: preimage,
    completed_at: new Date().toISOString(),
    amount_sats: amountSats,
  }).eq('lightning_payment_hash', payment_hash);

  await supabase.rpc('confirm_lightning_payment', {
    p_payment_hash: payment_hash,
    p_preimage: preimage,
  });
}

async function handlePaymentSent(data: any) {
  const { payment_hash, status, error_message } = data;
  if (status === 'failed') {
    await supabase.from('transactions').update({
      status: 'failed',
      status_reason: error_message || 'Paiement échoué',
      failed_at: new Date().toISOString(),
    }).eq('lightning_payment_hash', payment_hash);
  }
}

async function handlePaymentFailed(data: any) {
  const { payment_hash, error_message } = data;
  await supabase.from('transactions').update({
    status: 'failed',
    status_reason: error_message || 'Paiement échoué',
    failed_at: new Date().toISOString(),
  }).eq('lightning_payment_hash', payment_hash);

  await supabase.rpc('refund_failed_payment', {
    p_payment_hash: payment_hash,
  });
}
