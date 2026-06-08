import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

/**
 * Cette fonction met à jour les taux de change automatiquement.
 * Elle peut être programmée pour s'exécuter toutes les 10 minutes.
 */

serve(async (req) => {
  const supabase = createClient(
    Deno.env.get('SUPABASE_URL') ?? '',
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
  )

  try {
    // 1. Récupérer le prix du Bitcoin sur CoinGecko
    const response = await fetch("https://api.coingecko.com/api/v3/simple/price?ids=bitcoin&vs_currencies=usd")
    const data = await response.json()
    const btcPrice = data.bitcoin.usd

    // 2. Mettre à jour la table exchange_rates
    const { error } = await supabase.rpc('admin_update_exchange_rate', {
      p_from_currency: 'BTC',
      p_to_currency: 'USD',
      p_rate: btcPrice
    })

    if (error) throw error

    return new Response(JSON.stringify({ success: true, price: btcPrice }), { headers: { "Content-Type": "application/json" } })
  } catch (err) {
    return new Response(JSON.stringify({ error: err.message }), { status: 500 })
  }
})
