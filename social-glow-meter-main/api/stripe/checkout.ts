import type { NextApiRequest, NextApiResponse } from 'next';
import Stripe from 'stripe';

// Remplace par ta clé secrète Stripe
const stripe = new Stripe('sk_test_xxxxxxxxxxxxxxxxxxxxx', {
  apiVersion: '2023-10-16',
});

export default async function handler(req: NextApiRequest, res: NextApiResponse) {
  if (req.method !== 'POST') return res.status(405).end();
  const { itemId } = req.body;
  // Récupère l'item dans ta base (à adapter selon ton ORM ou requête SQL)
  // Ici, exemple statique :
  const item = {
    id: itemId,
    name: 'Personnalisation',
    price: 500, // en centimes
    description: 'Un super objet',
  };
  try {
    const session = await stripe.checkout.sessions.create({
      payment_method_types: ['card'],
      line_items: [
        {
          price_data: {
            currency: 'eur',
            product_data: {
              name: item.name,
              description: item.description,
            },
            unit_amount: item.price,
          },
          quantity: 1,
        },
      ],
      mode: 'payment',
      success_url: `${req.headers.origin}/boutique?success=1`,
      cancel_url: `${req.headers.origin}/boutique?canceled=1`,
    });
    res.status(200).json({ sessionId: session.id, url: session.url });
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
}
