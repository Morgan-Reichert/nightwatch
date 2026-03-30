import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import Stripe from "https://esm.sh/stripe@14.21.0?target=deno";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

const ITEMS: Record<string, { name: string; price_cents: number; description: string }> = {
  flame_restore:   { name: "Flamme de Résurrection", price_cents: 299, description: "Restaure ta flamme si tu as raté une semaine" },
  frame_gold:      { name: "Aura Dorée",              price_cents: 199, description: "Anneau doré lumineux autour de ta photo" },
  frame_neon:      { name: "Neon Arc",                price_cents: 299, description: "Arc-en-ciel néon animé" },
  frame_fire:      { name: "Flamme Éternelle",        price_cents: 299, description: "Anneau de feu autour de ta photo" },
  frame_ice:       { name: "Glace Royale",            price_cents: 199, description: "Cristaux de glace scintillants" },
  frame_vip:       { name: "VIP Crown",               price_cents: 399, description: "Couronne violette pour les élus" },
  frame_galaxy:    { name: "Galaxy",                  price_cents: 299, description: "Anneau galactique étoilé" },
  banner_sunset:   { name: "Sunset",                  price_cents: 149, description: "Dégradé coucher de soleil" },
  banner_ocean:    { name: "Ocean Deep",              price_cents: 149, description: "Les profondeurs de l'océan" },
  banner_purple:   { name: "Purple Haze",             price_cents: 149, description: "Brume violette mystérieuse" },
  banner_forest:   { name: "Forest Night",            price_cents: 149, description: "Nuit en forêt" },
  banner_cosmic:   { name: "Cosmic",                  price_cents: 199, description: "Voyage dans l'espace" },
  banner_cherry:   { name: "Cherry Blossom",          price_cents: 149, description: "Douceur rose cerisier" },
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  try {
    const STRIPE_SECRET_KEY = Deno.env.get("STRIPE_SECRET_KEY");
    if (!STRIPE_SECRET_KEY) throw new Error("STRIPE_SECRET_KEY non configuré");

    const { item_id, user_id, origin } = await req.json();
    const item = ITEMS[item_id];
    if (!item) throw new Error("Article inconnu");

    const stripe = new Stripe(STRIPE_SECRET_KEY, { apiVersion: "2023-10-16" });

    const session = await stripe.checkout.sessions.create({
      payment_method_types: ["card"],
      line_items: [{
        price_data: {
          currency: "eur",
          product_data: { name: item.name, description: item.description },
          unit_amount: item.price_cents,
        },
        quantity: 1,
      }],
      mode: "payment",
      success_url: `${origin}/?tab=shop&success=1&item_id=${item_id}&session_id={CHECKOUT_SESSION_ID}`,
      cancel_url:  `${origin}/?tab=shop&canceled=1`,
      metadata: { user_id, item_id },
    });

    return new Response(JSON.stringify({ url: session.url, session_id: session.id }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (err: any) {
    return new Response(JSON.stringify({ error: err.message }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
