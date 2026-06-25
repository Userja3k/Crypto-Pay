// supabase/functions/lnd-integration/index.ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

// Configuration LNbits (au lieu de LND)
const LNBITS_URL = Deno.env.get('LNBITS_URL') ?? 'https://legend.lnbits.com'
const LNBITS_INVOICE_KEY = Deno.env.get('LNBITS_INVOICE_KEY') ?? ''
const LNBITS_ADMIN_KEY = Deno.env.get('LNBITS_ADMIN_KEY') ?? ''
const SUPABASE_URL = Deno.env.get('SUPABASE_URL') ?? ''
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''

serve(async (req) => {
  try {
    const { action, amount_sats, invoice, memo, user_id } = await req.json()

    // Initialiser Supabase pour les mises à jour DB
    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)

    // ACTION 1: CRÉER UNE FACTURE (Recevoir)
    if (action === 'create_invoice') {
      // 1. Créer la facture sur LNbits
      const response = await fetch(`${LNBITS_URL}/api/v1/payments`, {
        method: "POST",
        headers: {
          "X-Api-Key": LNBITS_INVOICE_KEY,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          out: false,
          amount: amount_sats,
          memo: memo || `Paiement de ${amount_sats} sats`,
        }),
      })

      if (!response.ok) {
        const error = await response.text()
        throw new Error(`LNbits error: ${error}`)
      }

      const data = await response.json()

      // 2. Créer une entrée dans ta table transactions
      const { error: dbError } = await supabase
        .from('transactions')
        .insert({
          user_id: user_id,
          type: 'receive',
          amount: amount_sats,
          status: 'pending',
          payment_hash: data.payment_hash,
          invoice: data.payment_request,
          created_at: new Date().toISOString()
        })

      if (dbError) throw dbError

      // 3. Retourner la facture à Flutter
      return new Response(JSON.stringify({
        success: true,
        invoice: data.payment_request,
        payment_hash: data.payment_hash,
        // Pour le QR Code dans Flutter
        qr_data: data.payment_request
      }), {
        headers: { "Content-Type": "application/json" }
      })
    }

    // ACTION 2: ENVOYER UN PAIEMENT (Payer)
    if (action === 'send_payment') {
      // 1. Payer la facture sur LNbits
      const response = await fetch(`${LNBITS_URL}/api/v1/payments`, {
        method: "POST",
        headers: {
          "X-Api-Key": LNBITS_ADMIN_KEY,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          out: true,
          bolt11: invoice,
        }),
      })

      if (!response.ok) {
        const error = await response.text()
        throw new Error(`LNbits payment error: ${error}`)
      }

      const data = await response.json()

      // 2. Mettre à jour la transaction
      const { error: dbError } = await supabase
        .from('transactions')
        .insert({
          user_id: user_id,
          type: 'send',
          amount: amount_sats,
          status: 'completed',
          payment_hash: data.payment_hash,
          checking_id: data.checking_id,
          created_at: new Date().toISOString()
        })

      if (dbError) throw dbError

      return new Response(JSON.stringify({
        success: true,
        checking_id: data.checking_id,
        payment_hash: data.payment_hash
      }), {
        headers: { "Content-Type": "application/json" }
      })
    }

    // ACTION 3: VÉRIFIER LE STATUT D'UNE FACTURE
    if (action === 'check_invoice') {
      const { payment_hash } = await req.json()

      const response = await fetch(`${LNBITS_URL}/api/v1/payments/${payment_hash}`, {
        headers: { "X-Api-Key": LNBITS_INVOICE_KEY }
      })

      const data = await response.json()

      // Mettre à jour le statut dans ta DB si payé
      if (data.paid) {
        await supabase
          .from('transactions')
          .update({
            status: 'completed',
            paid_at: new Date().toISOString()
          })
          .eq('payment_hash', payment_hash)

        // Appeler ta RPC pour mettre à jour le solde
        await supabase.rpc('update_user_balance', {
          p_user_id: user_id,
          p_amount: data.amount
        })
      }

      return new Response(JSON.stringify({
        paid: data.paid,
        amount: data.amount,
        status: data.paid ? 'completed' : 'pending'
      }), {
        headers: { "Content-Type": "application/json" }
      })
    }

    // ACTION 4: WEBHOOK (pour les notifications de LNbits)
    if (action === 'webhook') {
      const webhookData = await req.json()
      // webhookData contient: { payment_hash, status, amount }

      // Mettre à jour la transaction
      await supabase
        .from('transactions')
        .update({
          status: webhookData.status === 'success' ? 'completed' : 'failed',
          settled_at: new Date().toISOString()
        })
        .eq('payment_hash', webhookData.payment_hash)

      return new Response("OK", { status: 200 })
    }

    return new Response(JSON.stringify({ error: "Action non reconnue" }), {
      status: 400,
      headers: { "Content-Type": "application/json" }
    })

  } catch (error) {
    console.error('Error:', error)
    return new Response(JSON.stringify({
      error: error.message || "Erreur interne"
    }), {
      status: 500,
      headers: { "Content-Type": "application/json" }
    })
  }
})