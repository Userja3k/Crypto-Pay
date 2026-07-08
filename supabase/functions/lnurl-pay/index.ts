import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.38.0';

const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
const supabaseServiceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
const supabase = createClient(supabaseUrl, supabaseServiceRoleKey);

serve(async (req) => {
  const url = new URL(req.url);
  const path = url.pathname;

  if (path.startsWith('/.well-known/lnurl/pay/')) {
    const secret = path.split('/').pop() ?? '';
    return handlePayRequest(secret, url);
  }

  if (path === '/callback' && (req.method === 'GET' || req.method === 'POST')) {
    return handlePayCallback(req);
  }

  return new Response('Not Found', { status: 404 });
});

async function handlePayRequest(secret: string, url: URL): Promise<Response> {
  try {
    const { data, error } = await supabase.rpc('get_lnurl_pay_info', {
      p_lnurl_secret: secret,
    });

    const info = Array.isArray(data) && data.length > 0 ? data[0] : null;
    if (error || !info || !info.is_valid) {
      return new Response(JSON.stringify({ status: 'ERROR', reason: 'Invalid LNURL' }), {
        headers: { 'Content-Type': 'application/json' },
        status: 404,
      });
    }

    const response = {
      tag: 'payRequest',
      callback: `${url.origin}/callback?secret=${secret}`,
      minSendable: 1000,
      maxSendable: info.fixed_amount_sats ? info.fixed_amount_sats * 1000 : 1000000000,
      metadata: JSON.stringify([
        ['text/plain', info.description || 'Paiement Crypto-Pay'],
        ['text/identifier', `pay@${url.hostname}`],
      ]),
      commentAllowed: info.requires_comment ? 140 : 0,
    };

    return new Response(JSON.stringify(response), {
      headers: { 'Content-Type': 'application/json' },
    });
  } catch {
    return new Response(JSON.stringify({ status: 'ERROR', reason: 'Internal error' }), {
      headers: { 'Content-Type': 'application/json' },
      status: 500,
    });
  }
}

async function handlePayCallback(req: Request): Promise<Response> {
  try {
    const url = new URL(req.url);
    const secret = url.searchParams.get('secret');
    const amount = url.searchParams.get('amount');
    const paymentHash = url.searchParams.get('payment_hash');
    const comment = url.searchParams.get('comment');

    if (!secret || !amount || !paymentHash) {
      return new Response(JSON.stringify({ status: 'ERROR', reason: 'Missing parameters' }), {
        headers: { 'Content-Type': 'application/json' },
        status: 400,
      });
    }

    const amountSats = Math.round(parseInt(amount, 10) / 1000);
    const { data, error } = await supabase.rpc('record_lnurl_pay_payment', {
      p_lnurl_secret: secret,
      p_amount_sats: amountSats,
      p_payment_hash: paymentHash,
      p_comment: comment || null,
    });

    if (error) throw error;

    return new Response(JSON.stringify({ status: 'OK', data }), {
      headers: { 'Content-Type': 'application/json' },
    });
  } catch {
    return new Response(JSON.stringify({ status: 'ERROR', reason: 'Internal error' }), {
      headers: { 'Content-Type': 'application/json' },
      status: 500,
    });
  }
}
