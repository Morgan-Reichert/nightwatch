export type ShopCategory = 'flame' | 'frame' | 'banner';

export interface ShopItem {
  id: string;
  name: string;
  description: string;
  price_cents: number;
  category: ShopCategory;
  paymentLink?: string; // Stripe Payment Link URL
  // Visual config used both in shop preview and on profile
  visual: FrameVisual | BannerVisual | FlameVisual;
}

export interface FrameVisual {
  type: 'frame';
  gradient: string;      // CSS gradient string
  glow: string;          // box-shadow color
  animated?: boolean;
}

export interface BannerVisual {
  type: 'banner';
  gradient: string;      // Tailwind gradient classes
  cssGradient: string;   // actual CSS for rendering
}

export interface FlameVisual {
  type: 'flame';
}

const LINK = 'https://buy.stripe.com/test_eVq6oH6IscP1cr0gDngjC01';

export const SHOP_ITEMS: ShopItem[] = [
  // ── Flamme ──────────────────────────────────────────────────────
  {
    id: 'flame_restore',
    name: 'Flamme de Résurrection',
    description: 'Restaure ta flamme si tu as raté une semaine. Reviens dans la course !',
    price_cents: 299,
    category: 'flame',
    paymentLink: LINK,
    visual: { type: 'flame' },
  },

  // ── Cadres ──────────────────────────────────────────────────────
  {
    id: 'frame_gold',
    name: 'Aura Dorée',
    description: 'Un anneau doré qui brille sur ton profil',
    price_cents: 199,
    category: 'frame',
    paymentLink: 'https://buy.stripe.com/test_eVq6oH6IscP1cr0gDngjC01',
    visual: {
      type: 'frame',
      gradient: 'linear-gradient(135deg, #f59e0b, #fde68a, #d97706, #fbbf24)',
      glow: 'rgba(251,191,36,0.7)',
    },
  },
  {
    id: 'frame_neon',
    name: 'Neon Arc',
    description: 'Arc-en-ciel néon animé tout autour',
    price_cents: 299,
    category: 'frame',
    paymentLink: LINK,
    visual: {
      type: 'frame',
      gradient: 'linear-gradient(135deg, #ec4899, #8b5cf6, #3b82f6, #10b981, #f59e0b, #ec4899)',
      glow: 'rgba(139,92,246,0.6)',
      animated: true,
    },
  },
  {
    id: 'frame_fire',
    name: 'Flamme Éternelle',
    description: 'Anneau de feu incandescent',
    price_cents: 299,
    category: 'frame',
    paymentLink: LINK,
    visual: {
      type: 'frame',
      gradient: 'linear-gradient(135deg, #f97316, #ef4444, #fbbf24, #f97316)',
      glow: 'rgba(249,115,22,0.7)',
    },
  },
  {
    id: 'frame_ice',
    name: 'Glace Royale',
    description: 'Cristaux de glace scintillants',
    price_cents: 199,
    category: 'frame',
    paymentLink: LINK,
    visual: {
      type: 'frame',
      gradient: 'linear-gradient(135deg, #67e8f9, #a5f3fc, #6366f1, #bae6fd)',
      glow: 'rgba(103,232,249,0.6)',
    },
  },
  {
    id: 'frame_vip',
    name: 'VIP Crown',
    description: 'Couronne violette pour les élus',
    price_cents: 399,
    category: 'frame',
    paymentLink: LINK,
    visual: {
      type: 'frame',
      gradient: 'linear-gradient(135deg, #8b5cf6, #d946ef, #7c3aed, #c026d3)',
      glow: 'rgba(139,92,246,0.75)',
      animated: true,
    },
  },
  {
    id: 'frame_galaxy',
    name: 'Galaxy',
    description: 'Anneau galactique étoilé',
    price_cents: 299,
    category: 'frame',
    paymentLink: LINK,
    visual: {
      type: 'frame',
      gradient: 'linear-gradient(135deg, #1e1b4b, #7c3aed, #0ea5e9, #4c1d95)',
      glow: 'rgba(124,58,237,0.5)',
    },
  },

  // ── Bannières ───────────────────────────────────────────────────
  {
    id: 'banner_sunset',
    name: 'Sunset',
    description: 'Coucher de soleil orange et rose',
    price_cents: 149,
    category: 'banner',
    paymentLink: LINK,
    visual: {
      type: 'banner',
      gradient: 'from-orange-400 via-rose-400 to-pink-500',
      cssGradient: 'linear-gradient(135deg, #fb923c, #fb7185, #ec4899)',
    },
  },
  {
    id: 'banner_ocean',
    name: 'Ocean Deep',
    description: 'Les profondeurs de l\'océan',
    price_cents: 149,
    category: 'banner',
    paymentLink: LINK,
    visual: {
      type: 'banner',
      gradient: 'from-cyan-500 via-blue-500 to-indigo-600',
      cssGradient: 'linear-gradient(135deg, #06b6d4, #3b82f6, #4f46e5)',
    },
  },
  {
    id: 'banner_purple',
    name: 'Purple Haze',
    description: 'Brume violette mystérieuse',
    price_cents: 149,
    category: 'banner',
    paymentLink: LINK,
    visual: {
      type: 'banner',
      gradient: 'from-violet-500 via-purple-600 to-indigo-700',
      cssGradient: 'linear-gradient(135deg, #8b5cf6, #9333ea, #4338ca)',
    },
  },
  {
    id: 'banner_forest',
    name: 'Forest Night',
    description: 'Nuit mystérieuse en forêt',
    price_cents: 149,
    category: 'banner',
    paymentLink: LINK,
    visual: {
      type: 'banner',
      gradient: 'from-green-600 via-emerald-700 to-teal-900',
      cssGradient: 'linear-gradient(135deg, #16a34a, #047857, #134e4a)',
    },
  },
  {
    id: 'banner_cosmic',
    name: 'Cosmic',
    description: 'Voyage dans l\'univers',
    price_cents: 199,
    category: 'banner',
    paymentLink: LINK,
    visual: {
      type: 'banner',
      gradient: 'from-slate-900 via-purple-900 to-pink-900',
      cssGradient: 'linear-gradient(135deg, #0f172a, #4a1d96, #831843)',
    },
  },
  {
    id: 'banner_cherry',
    name: 'Cherry Blossom',
    description: 'Douceur rose cerisier japonais',
    price_cents: 149,
    category: 'banner',
    paymentLink: LINK,
    visual: {
      type: 'banner',
      gradient: 'from-pink-300 via-rose-300 to-fuchsia-400',
      cssGradient: 'linear-gradient(135deg, #f9a8d4, #fda4af, #e879f9)',
    },
  },
];

export const CATEGORY_LABELS: Record<ShopCategory, string> = {
  flame:  '🔥 Flamme',
  frame:  '✨ Cadres de profil',
  banner: '🎨 Bannières',
};
