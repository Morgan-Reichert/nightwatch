export type BadgeTier = 'bronze' | 'silver' | 'gold' | 'diamond';
export type BadgeCategory = 'drinks' | 'parties' | 'quiche' | 'bisous' | 'social';

export interface BadgeDefinition {
  id: string;
  name: string;
  description: string;
  tier: BadgeTier;
  category: BadgeCategory;
}

export interface EarnedBadge extends BadgeDefinition {
  earned: boolean;
  progress: number;
  current: number;
  required: number;
}

export const BADGE_DEFINITIONS: BadgeDefinition[] = [
  // --- Boissons ---
  { id: 'first_sip',      name: 'Première gorgée',  description: 'Enregistre ton 1er verre',         tier: 'bronze',  category: 'drinks' },
  { id: 'ten_drinks',     name: 'Soif naturelle',   description: '10 verres au compteur',             tier: 'bronze',  category: 'drinks' },
  { id: 'twenty_five',    name: 'Pilier du bar',    description: '25 verres enregistrés',             tier: 'silver',  category: 'drinks' },
  { id: 'fifty_drinks',   name: 'Connaisseur',      description: '50 verres enregistrés',             tier: 'gold',    category: 'drinks' },
  { id: 'hundred_drinks', name: 'Légende',          description: '100 verres — tu es une légende',   tier: 'diamond', category: 'drinks' },

  // --- Soirées ---
  { id: 'first_party',    name: 'Première soirée',  description: 'Rejoins ta 1ère soirée',            tier: 'bronze',  category: 'parties' },
  { id: 'five_parties',   name: 'Habitué',          description: '5 soirées au tableau de chasse',   tier: 'silver',  category: 'parties' },
  { id: 'ten_parties',    name: 'Party Animal',     description: '10 soirées et ça continue',        tier: 'gold',    category: 'parties' },

  // --- Quiche ---
  { id: 'first_quiche',   name: 'Ça arrive...',     description: 'Premier quiche enregistré',        tier: 'bronze',  category: 'quiche' },
  { id: 'three_quiches',  name: 'Régulier',         description: '3 quiches au compteur',            tier: 'silver',  category: 'quiche' },
  { id: 'five_quiches',   name: 'Quiche King',      description: '5 quiches — respect',              tier: 'gold',    category: 'quiche' },

  // --- Bisous ---
  { id: 'first_bisou',    name: 'Romantique',       description: 'Premier bisou de soirée',          tier: 'bronze',  category: 'bisous' },
  { id: 'five_bisous',    name: 'Charmeur',         description: '5 bisous en soirée',               tier: 'silver',  category: 'bisous' },
  { id: 'ten_bisous',     name: 'Love Machine',     description: '10 bisous — charisme légendaire',  tier: 'gold',    category: 'bisous' },

  // --- Social ---
  { id: 'first_friend',   name: 'Premier ami',      description: 'Ajoute ton 1er ami',               tier: 'bronze',  category: 'social' },
  { id: 'five_friends',   name: 'Populaire',        description: '5 amis sur l\'appli',              tier: 'silver',  category: 'social' },
  { id: 'ten_friends',    name: 'Star sociale',     description: '10 amis — tu gères',               tier: 'gold',    category: 'social' },
];

export const CATEGORY_META: Record<BadgeCategory, {
  label: string;
  iconName: string;
  bg: string;
  ring: string;
  text: string;
  glow: string;
}> = {
  drinks:  { label: 'Boissons',  iconName: 'GlassWater', bg: 'bg-sky-500',     ring: 'ring-sky-400',     text: 'text-sky-300',     glow: 'shadow-sky-500/50'     },
  parties: { label: 'Soirées',   iconName: 'Sparkles',   bg: 'bg-violet-500',  ring: 'ring-violet-400',  text: 'text-violet-300',  glow: 'shadow-violet-500/50'  },
  quiche:  { label: 'Quiche',    iconName: 'Flame',      bg: 'bg-orange-500',  ring: 'ring-orange-400',  text: 'text-orange-300',  glow: 'shadow-orange-500/50'  },
  bisous:  { label: 'Bisous',    iconName: 'Heart',      bg: 'bg-rose-500',    ring: 'ring-rose-400',    text: 'text-rose-300',    glow: 'shadow-rose-500/50'    },
  social:  { label: 'Social',    iconName: 'Users',      bg: 'bg-emerald-500', ring: 'ring-emerald-400', text: 'text-emerald-300', glow: 'shadow-emerald-500/50' },
};

export const TIER_META: Record<BadgeTier, { label: string; ring: string; extraClass: string }> = {
  bronze:  { label: 'Bronze',  ring: 'ring-1 ring-amber-600/60',   extraClass: '' },
  silver:  { label: 'Argent',  ring: 'ring-2 ring-slate-300/80',   extraClass: '' },
  gold:    { label: 'Or',      ring: 'ring-2 ring-yellow-400',     extraClass: 'shadow-lg' },
  diamond: { label: 'Diamant', ring: 'ring-2 ring-cyan-300',       extraClass: 'shadow-xl shadow-cyan-400/40' },
};

export function computeBadges(
  totalDrinks: number,
  totalParties: number,
  totalQuiches: number,
  totalBisous: number,
  totalFriends: number,
): EarnedBadge[] {
  const thresholds: Record<string, { current: number; required: number }> = {
    first_sip:      { current: totalDrinks,   required: 1   },
    ten_drinks:     { current: totalDrinks,   required: 10  },
    twenty_five:    { current: totalDrinks,   required: 25  },
    fifty_drinks:   { current: totalDrinks,   required: 50  },
    hundred_drinks: { current: totalDrinks,   required: 100 },
    first_party:    { current: totalParties,  required: 1   },
    five_parties:   { current: totalParties,  required: 5   },
    ten_parties:    { current: totalParties,  required: 10  },
    first_quiche:   { current: totalQuiches,  required: 1   },
    three_quiches:  { current: totalQuiches,  required: 3   },
    five_quiches:   { current: totalQuiches,  required: 5   },
    first_bisou:    { current: totalBisous,   required: 1   },
    five_bisous:    { current: totalBisous,   required: 5   },
    ten_bisous:     { current: totalBisous,   required: 10  },
    first_friend:   { current: totalFriends,  required: 1   },
    five_friends:   { current: totalFriends,  required: 5   },
    ten_friends:    { current: totalFriends,  required: 10  },
  };

  return BADGE_DEFINITIONS.map(def => {
    const t = thresholds[def.id];
    return {
      ...def,
      earned:   t.current >= t.required,
      progress: Math.min(t.current / t.required, 1),
      current:  t.current,
      required: t.required,
    };
  });
}
