import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.38.0';

const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
const supabaseAnonKey = Deno.env.get('SUPABASE_ANON_KEY')!;
const cronSecret = Deno.env.get('CRON_SECRET') ?? '';
const supabase = createClient(supabaseUrl, supabaseAnonKey);

serve(async (req) => {
  const authHeader = req.headers.get('Authorization') ?? '';
  if (cronSecret && authHeader !== `Bearer ${cronSecret}`) {
    return new Response('Unauthorized', { status: 401 });
  }

  try {
    const now = new Date();
    await supabase.from('child_limits').update({
      daily_spent_usd: 0,
      last_reset_at: now.toISOString(),
    }).lt('last_reset_at', new Date(now.getFullYear(), now.getMonth(), now.getDate()).toISOString());

    await supabase.from('accounts').update({
      monthly_sent_usd: 0,
      monthly_received_usd: 0,
      monthly_reset_at: now.toISOString(),
    }).lt('monthly_reset_at', new Date(now.getFullYear(), now.getMonth(), 1).toISOString());

    return new Response(JSON.stringify({ success: true }), {
      headers: { 'Content-Type': 'application/json' },
    });
  } catch (error) {
    return new Response(JSON.stringify({ success: false, error: String(error) }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    });
  }
});
