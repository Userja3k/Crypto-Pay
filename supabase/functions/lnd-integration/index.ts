import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

/**
 * Cette Edge Function permet de faire le pont entre Supabase et ton nœud LND.
 * Elle est appelée quand un utilisateur veut envoyer ou recevoir des fonds.
 */

serve(async (req) => {
  const { action, amount_sats, invoice, memo } = await req.json()

  // TODO: Récupère ces variables dans tes "Secrets" Supabase
  const LND_HOST = Deno.env.get('LND_HOST')
  const LND_MACAROON = Deno.env.get('LND_MACAROON') // admin.macaroon en base64

  if (action === 'create_invoice') {
    // Appel à LND pour générer une facture (Exemple simplifié)
    // const response = await fetch(`${LND_HOST}/v1/invoices`, { ... })
    return new Response(JSON.stringify({ bolt11: 'lnbc...', payment_hash: '...' }), { headers: { "Content-Type": "application/json" } })
  }

  if (action === 'send_payment') {
    // Appel à LND pour payer une facture
    return new Response(JSON.stringify({ success: true, preimage: '...' }), { headers: { "Content-Type": "application/json" } })
  }

  return new Response("Action non reconnue", { status: 400 })
})
