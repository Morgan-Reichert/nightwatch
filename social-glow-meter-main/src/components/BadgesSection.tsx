import { useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { X, Lock, GlassWater, Sparkles, Flame, Heart, Users } from 'lucide-react';
import { EarnedBadge, CATEGORY_META, TIER_META, BadgeCategory, computeBadges } from '@/lib/badges';
import { useUserStats } from '@/hooks/useSupabase';

interface Props {
  userId?: string;
  badges?: EarnedBadge[];
}

const ICON_MAP: Record<string, React.ReactNode> = {
  GlassWater: <GlassWater className="w-5 h-5" />,
  Sparkles:   <Sparkles   className="w-5 h-5" />,
  Flame:      <Flame      className="w-5 h-5" />,
  Heart:      <Heart      className="w-5 h-5" />,
  Users:      <Users      className="w-5 h-5" />,
};

const ICON_MAP_LG: Record<string, React.ReactNode> = {
  GlassWater: <GlassWater className="w-6 h-6" />,
  Sparkles:   <Sparkles   className="w-6 h-6" />,
  Flame:      <Flame      className="w-6 h-6" />,
  Heart:      <Heart      className="w-6 h-6" />,
  Users:      <Users      className="w-6 h-6" />,
};

function BadgePip({ badge }: { badge: EarnedBadge }) {
  const cat = CATEGORY_META[badge.category];
  const tier = TIER_META[badge.tier];
  const earned = badge.earned;

  return (
    <div className="flex flex-col items-center gap-1.5 w-16">
      <div className={`
        relative w-12 h-12 rounded-2xl flex items-center justify-center
        ${earned ? `${cat.bg} ${tier.ring} ${tier.extraClass}` : 'bg-muted/20 ring-1 ring-muted/30'}
        transition-all
      `}>
        <span className={earned ? 'text-white' : 'text-muted-foreground/30'}>
          {ICON_MAP[cat.iconName]}
        </span>
        {!earned && (
          <div className="absolute inset-0 flex items-center justify-center rounded-2xl bg-black/20">
            <Lock className="w-3 h-3 text-white/40" />
          </div>
        )}
        {/* Tier pip */}
        {earned && (
          <span className={`absolute -bottom-1 -right-1 w-4 h-4 rounded-full text-[8px] font-bold flex items-center justify-center
            ${badge.tier === 'bronze'  ? 'bg-amber-600 text-white'    : ''}
            ${badge.tier === 'silver'  ? 'bg-slate-300 text-slate-800' : ''}
            ${badge.tier === 'gold'    ? 'bg-yellow-400 text-yellow-900' : ''}
            ${badge.tier === 'diamond' ? 'bg-cyan-400 text-cyan-900'   : ''}
          `}>
            {badge.tier === 'bronze' ? 'B' : badge.tier === 'silver' ? 'A' : badge.tier === 'gold' ? 'O' : '◆'}
          </span>
        )}
      </div>
      <p className={`text-[9px] text-center leading-tight font-medium ${earned ? 'text-foreground' : 'text-muted-foreground/40'}`}>
        {badge.name}
      </p>
    </div>
  );
}

function BadgeCard({ badge }: { badge: EarnedBadge }) {
  const cat = CATEGORY_META[badge.category];
  const tier = TIER_META[badge.tier];
  const earned = badge.earned;

  return (
    <div className={`
      rounded-2xl p-3 flex flex-col items-center gap-2 border
      ${earned
        ? `bg-gradient-to-b from-${cat.bg.replace('bg-', '')}/20 to-transparent border-${cat.ring.replace('ring-', '')}/30`
        : 'bg-muted/10 border-muted/20'
      }
    `}>
      <div className={`
        w-14 h-14 rounded-2xl flex items-center justify-center relative
        ${earned ? `${cat.bg} ${tier.ring} ${tier.extraClass}` : 'bg-muted/20 ring-1 ring-muted/30'}
      `}>
        <span className={earned ? 'text-white' : 'text-muted-foreground/30'}>
          {ICON_MAP_LG[cat.iconName]}
        </span>
        {!earned && (
          <div className="absolute inset-0 flex items-center justify-center rounded-2xl bg-black/20">
            <Lock className="w-4 h-4 text-white/40" />
          </div>
        )}
        {earned && (
          <span className={`absolute -bottom-1.5 -right-1.5 w-5 h-5 rounded-full text-[9px] font-bold flex items-center justify-center
            ${badge.tier === 'bronze'  ? 'bg-amber-600 text-white'       : ''}
            ${badge.tier === 'silver'  ? 'bg-slate-300 text-slate-800'   : ''}
            ${badge.tier === 'gold'    ? 'bg-yellow-400 text-yellow-900' : ''}
            ${badge.tier === 'diamond' ? 'bg-cyan-400 text-cyan-900'     : ''}
          `}>
            {badge.tier === 'diamond' ? '◆' : badge.tier === 'gold' ? 'O' : badge.tier === 'silver' ? 'A' : 'B'}
          </span>
        )}
      </div>

      <p className={`text-xs font-semibold text-center leading-tight ${earned ? 'text-foreground' : 'text-muted-foreground/50'}`}>
        {badge.name}
      </p>
      <p className="text-[9px] text-muted-foreground text-center leading-tight">{badge.description}</p>

      {!earned && (
        <div className="w-full">
          <div className="h-1 w-full bg-muted/30 rounded-full overflow-hidden">
            <div
              className={`h-full rounded-full transition-all ${cat.bg.replace('500', '400')}`}
              style={{ width: `${badge.progress * 100}%` }}
            />
          </div>
          <p className="text-[8px] text-muted-foreground text-center mt-0.5">{badge.current}/{badge.required}</p>
        </div>
      )}
    </div>
  );
}

const CATEGORIES: BadgeCategory[] = ['drinks', 'parties', 'quiche', 'bisous', 'social'];

export default function BadgesSection({ userId, badges: badgesProp }: Props) {
  const stats = useUserStats(userId);
  const badges = badgesProp ?? computeBadges(stats.drinks, stats.parties, stats.quiches, stats.bisous, stats.friends);
  const [showAll, setShowAll] = useState(false);

  const earnedBadges = badges.filter(b => b.earned);
  const previewBadges = earnedBadges.slice(0, 4);
  const lockedCount = badges.length - earnedBadges.length;

  return (
    <div className="space-y-2">
      <p className="text-xs uppercase tracking-widest text-muted-foreground">Badges & Récompenses</p>

      <div className="glass-card p-4">
        {earnedBadges.length === 0 ? (
          <p className="text-sm text-muted-foreground text-center py-2">
            Commence à soirée pour débloquer tes badges !
          </p>
        ) : (
          <div className="flex items-start gap-2 flex-wrap">
            {previewBadges.map(badge => (
              <BadgePip key={badge.id} badge={badge} />
            ))}
            {earnedBadges.length > 4 && (
              <div className="flex flex-col items-center gap-1.5 w-16">
                <div className="w-12 h-12 rounded-2xl bg-primary/10 ring-1 ring-primary/30 flex items-center justify-center">
                  <span className="text-primary text-sm font-bold">+{earnedBadges.length - 4}</span>
                </div>
              </div>
            )}
          </div>
        )}

        <motion.button
          whileTap={{ scale: 0.97 }}
          onClick={() => setShowAll(true)}
          className="mt-4 w-full py-2 rounded-xl bg-primary/10 text-primary text-xs font-semibold flex items-center justify-center gap-1.5"
        >
          Voir tous les badges
          {lockedCount > 0 && (
            <span className="text-muted-foreground font-normal">· {lockedCount} à débloquer</span>
          )}
        </motion.button>
      </div>

      {/* Full sheet */}
      <AnimatePresence>
        {showAll && (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            className="fixed inset-0 z-50 bg-black/70 flex items-end justify-center"
            onClick={() => setShowAll(false)}
          >
            <motion.div
              initial={{ y: '100%' }}
              animate={{ y: 0 }}
              exit={{ y: '100%' }}
              transition={{ type: 'spring', damping: 28, stiffness: 300 }}
              className="bg-background w-full max-w-lg rounded-t-3xl max-h-[85vh] overflow-y-auto pb-28"
              onClick={e => e.stopPropagation()}
            >
              {/* Handle */}
              <div className="flex justify-center pt-3 pb-1">
                <div className="w-10 h-1 rounded-full bg-muted-foreground/30" />
              </div>

              <div className="px-5 pt-2 pb-4">
                <div className="flex items-center justify-between mb-5">
                  <div>
                    <p className="font-bold text-base">Badges</p>
                    <p className="text-xs text-muted-foreground">{earnedBadges.length}/{badges.length} débloqués</p>
                  </div>
                  <motion.button whileTap={{ scale: 0.9 }} onClick={() => setShowAll(false)}
                    className="w-8 h-8 rounded-full bg-muted/30 flex items-center justify-center">
                    <X className="w-4 h-4" />
                  </motion.button>
                </div>

                <div className="space-y-6">
                  {CATEGORIES.map(cat => {
                    const meta = CATEGORY_META[cat];
                    const catBadges = badges.filter(b => b.category === cat);
                    return (
                      <div key={cat}>
                        <div className="flex items-center gap-2 mb-3">
                          <div className={`w-6 h-6 rounded-lg ${meta.bg} flex items-center justify-center`}>
                            <span className="text-white">{ICON_MAP[meta.iconName]}</span>
                          </div>
                          <p className={`text-xs font-semibold uppercase tracking-wider ${meta.text}`}>
                            {meta.label}
                          </p>
                          <div className="flex-1 h-px bg-muted/20" />
                        </div>
                        <div className="grid grid-cols-3 gap-2">
                          {catBadges.map(badge => (
                            <BadgeCard key={badge.id} badge={badge} />
                          ))}
                        </div>
                      </div>
                    );
                  })}
                </div>
              </div>
            </motion.div>
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  );
}
