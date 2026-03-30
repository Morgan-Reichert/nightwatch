import { useState, useEffect } from 'react';
import { motion } from 'framer-motion';
import { Check } from 'lucide-react';
import { toast } from 'sonner';
import { SHOP_ITEMS, CATEGORY_LABELS, ShopItem, FrameVisual, BannerVisual, ShopCategory } from '@/lib/shopItems';
import { useMyPurchases } from '@/hooks/useSupabase';
import { useProfile } from '@/hooks/useSupabase';

// Animated frame preview ring
function FramePreview({ visual }: { visual: FrameVisual }) {
  return (
    <div className="w-full h-24 rounded-2xl flex items-center justify-center relative overflow-hidden"
      style={{ background: 'rgba(255,255,255,0.03)' }}>
      <div className="w-16 h-16 rounded-full p-[3px]"
        style={{
          background: visual.gradient,
          boxShadow: `0 0 20px ${visual.glow}`,
          animation: visual.animated ? 'spin 3s linear infinite' : undefined,
        }}>
        <div className="w-full h-full rounded-full bg-background/90 flex items-center justify-center text-xl">👤</div>
      </div>
    </div>
  );
}

// Banner preview with shimmer effect
function BannerPreview({ visual }: { visual: BannerVisual }) {
  return (
    <div className="w-full h-24 rounded-2xl relative overflow-hidden"
      style={{ background: visual.cssGradient }}>
      {/* Shimmer sweep */}
      <div className="absolute inset-0 overflow-hidden">
        <div className="absolute inset-y-0 w-1/3 bg-gradient-to-r from-transparent via-white/25 to-transparent"
          style={{ animation: 'shimmer 2.2s ease-in-out infinite', left: '-33%' }} />
      </div>
      {/* Subtle noise overlay */}
      <div className="absolute inset-0 opacity-20"
        style={{ backgroundImage: 'radial-gradient(circle at 30% 50%, white 0%, transparent 60%)' }} />
    </div>
  );
}

// Flame preview using beer mug SVG
function FlamePreview() {
  return (
    <div className="w-full h-24 rounded-2xl flex items-center justify-center relative overflow-hidden"
      style={{ background: 'linear-gradient(135deg, rgba(249,115,22,0.15), rgba(239,68,68,0.15))', boxShadow: '0 0 20px rgba(249,115,22,0.2)' }}>
      <div className="relative flex items-center justify-center w-14 h-14 rounded-2xl"
        style={{ background: 'radial-gradient(circle at 50% 60%, rgba(249,115,22,0.3), transparent 70%)', border: '1.5px solid rgba(249,115,22,0.4)' }}>
        {/* Beer mug SVG */}
        <svg width="32" height="32" viewBox="0 0 32 32" fill="none">
          <rect x="4" y="10" width="18" height="18" rx="3" fill="#f97316" />
          <path d="M22 14 C28 14 28 24 22 24" stroke="#f97316" strokeWidth="3" strokeLinecap="round" fill="none" />
          <ellipse cx="13" cy="10" rx="9" ry="4" fill="white" opacity="0.9" />
          <circle cx="9" cy="20" r="1.5" fill="white" opacity="0.25" />
          <circle cx="14" cy="17" r="1" fill="white" opacity="0.2" />
          <circle cx="11" cy="24" r="1" fill="white" opacity="0.2" />
        </svg>
        {/* Flame badge */}
        <div className="absolute -top-2 -right-2">
          <svg width="18" height="22" viewBox="0 0 20 24" fill="none">
            <path d="M10 2 C10 2 14 7 14 11 C14 13.5 12.5 15 12.5 15 C12.5 15 14 13 13 10 C13 10 16 14 14 18 C12.8 20.5 10 22 10 22 C10 22 7.2 20.5 6 18 C4 14 7 10 7 10 C6 13 7.5 15 7.5 15 C7.5 15 6 13.5 6 11 C6 7 10 2 10 2Z" fill="#22c55e" />
            <path d="M10 10 C10 10 12 13 11.5 15.5 C11 17.5 10 18.5 10 18.5 C10 18.5 9 17.5 8.5 15.5 C8 13 10 10 10 10Z" fill="white" opacity="0.5" />
          </svg>
        </div>
      </div>
    </div>
  );
}

function ItemCard({ item, owned, onBuy, onEquip, equipped }: {
  item: ShopItem;
  owned: boolean;
  onBuy: () => void;
  onEquip: () => void;
  equipped: boolean;
}) {
  const visual = item.visual;

  return (
    <motion.div whileTap={{ scale: 0.97 }}
      className={`glass-card p-3 flex flex-col gap-2 relative w-full ${equipped ? 'border-primary/50 bg-primary/5' : ''}`}>
      {equipped && (
        <span className="absolute top-2 right-2 text-[9px] bg-primary/30 text-primary px-1.5 py-0.5 rounded-full font-bold z-10">Équipé</span>
      )}
      {/* Preview */}
      {visual.type === 'frame' && <FramePreview visual={visual} />}
      {visual.type === 'banner' && <BannerPreview visual={visual} />}
      {visual.type === 'flame' && <FlamePreview />}
      {/* Info */}
      <div className="flex-1 flex flex-col gap-1">
        <p className="font-semibold text-sm leading-tight">{item.name}</p>
        <p className="text-[10px] text-muted-foreground leading-snug flex-1">{item.description}</p>
        <p className="text-xs font-bold text-primary">{(item.price_cents / 100).toFixed(2)} €</p>
      </div>
      {owned ? (
        <motion.button whileTap={{ scale: 0.95 }} onClick={onEquip}
          className={`w-full py-2 rounded-xl text-sm font-semibold transition-all ${
            equipped
              ? 'bg-primary/20 text-primary border border-primary/40'
              : 'glass-card text-muted-foreground hover:text-primary hover:border-primary/30'
          }`}>
          {equipped ? '✓ Équipé' : 'Équiper'}
        </motion.button>
      ) : (
        <motion.button whileTap={{ scale: 0.95 }} onClick={onBuy}
          className="w-full py-2 rounded-xl text-sm font-semibold bg-primary/20 text-primary border border-primary/30">
          Acheter
        </motion.button>
      )}
    </motion.div>
  );
}

export default function Shop() {
  const [activeCategory, setActiveCategory] = useState<ShopCategory>('frame');
  const { purchases, recordPurchase } = useMyPurchases();
  const { profile, updateProfile } = useProfile();

  // Handle Stripe success redirect
  useEffect(() => {
    const params = new URLSearchParams(window.location.search);
    if (params.get('success') === '1') {
      const itemId = params.get('item_id');
      if (itemId) {
        recordPurchase(itemId).then(() => {
          toast.success('Achat confirmé ! 🎉');
        });
      }
      // Clean URL
      window.history.replaceState({}, '', window.location.pathname + '?tab=shop');
    }
  }, []);

  const handleBuy = (item: ShopItem) => {
    if (!item.paymentLink) { toast.error('Lien de paiement non disponible'); return; }
    const successUrl = `${window.location.origin}/?tab=shop&success=1&item_id=${item.id}`;
    window.location.href = `${item.paymentLink}?success_url=${encodeURIComponent(successUrl)}`;
  };

  const handleEquip = async (item: ShopItem) => {
    if (!profile) return;
    try {
      if (item.category === 'frame') {
        const isEquipped = profile.avatar_frame === item.id;
        await updateProfile({ avatar_frame: isEquipped ? null : item.id });
        toast.success(isEquipped ? 'Cadre retiré' : `${item.name} équipé !`);
      } else if (item.category === 'banner') {
        const isEquipped = profile.banner_gradient === item.id;
        await updateProfile({ banner_gradient: isEquipped ? null : item.id });
        toast.success(isEquipped ? 'Bannière retirée' : `${item.name} équipée !`);
      }
    } catch (err: any) {
      toast.error(err.message);
    }
  };

  const categories: ShopCategory[] = ['frame', 'banner', 'flame'];
  const filtered = SHOP_ITEMS.filter(i => i.category === activeCategory);
  const isGrid = activeCategory === 'frame' || activeCategory === 'banner';

  return (
    <div className="space-y-4 pb-6">
      <p className="text-xs uppercase tracking-widest text-muted-foreground">Boutique</p>

      {/* Category tabs */}
      <div className="flex gap-2 overflow-x-auto pb-1">
        {categories.map(cat => (
          <motion.button key={cat} whileTap={{ scale: 0.95 }} onClick={() => setActiveCategory(cat)}
            className={`shrink-0 px-4 py-2 rounded-full text-sm font-medium transition-all ${
              activeCategory === cat ? 'bg-primary/30 text-primary border border-primary/50' : 'glass-card text-muted-foreground'
            }`}>
            {CATEGORY_LABELS[cat]}
          </motion.button>
        ))}
      </div>

      {/* Items */}
      <div className={isGrid ? 'grid grid-cols-2 gap-3' : 'space-y-3'}>
        {filtered.map((item, i) => (
          <motion.div key={item.id} initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: i * 0.05 }} className="flex">
            <ItemCard
              item={item}
              owned={purchases.includes(item.id)}
              equipped={profile?.avatar_frame === item.id || profile?.banner_gradient === item.id}
              onBuy={() => handleBuy(item)}
              onEquip={() => handleEquip(item)}
            />
          </motion.div>
        ))}
      </div>
    </div>
  );
}
