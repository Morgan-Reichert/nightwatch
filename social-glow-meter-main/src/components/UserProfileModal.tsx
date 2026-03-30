import { motion, AnimatePresence } from 'framer-motion';
import { X, Phone, UserPlus, MessageCircle, Share2 } from 'lucide-react';
import { Profile } from '@/hooks/useSupabase';
import { useStreakForUser } from '@/hooks/useSupabase';
import { SHOP_ITEMS, FrameVisual, BannerVisual } from '@/lib/shopItems';
import { toast } from 'sonner';

interface UserProfileModalProps {
  profile: Profile | null;
  isOpen: boolean;
  onClose: () => void;
  onAddFriend?: () => void;
  onInviteToParty?: () => void;
  showActions?: boolean;
  isFriend?: boolean;
  isPartyMember?: boolean;
  currentUserId?: string;
}

export default function UserProfileModal({
  profile,
  isOpen,
  onClose,
  onAddFriend,
  onInviteToParty,
  showActions = true,
  isFriend = false,
  isPartyMember = false,
  currentUserId
}: UserProfileModalProps) {
  const streak = useStreakForUser(profile?.user_id);

  if (!profile) return null;

  const isCurrentUser = currentUserId === profile.user_id;

  // Resolve purchased frame
  const frameItem = profile.avatar_frame ? SHOP_ITEMS.find(i => i.id === profile.avatar_frame) : null;
  const frameVisual = frameItem?.visual.type === 'frame' ? frameItem.visual as FrameVisual : null;

  // Resolve purchased banner
  const bannerItem = profile.banner_gradient ? SHOP_ITEMS.find(i => i.id === profile.banner_gradient) : null;
  const bannerVisual = bannerItem?.visual.type === 'banner' ? bannerItem.visual as BannerVisual : null;

  // Streak visual config (matches StreakDisplay)
  const streakCfg = streak.weeks >= 10
    ? { beer: '#ef4444', flame: '#f97316', glow: 'rgba(239,68,68,0.5)' }
    : streak.weeks >= 5
    ? { beer: '#eab308', flame: '#f59e0b', glow: 'rgba(234,179,8,0.45)' }
    : streak.weeks >= 3
    ? { beer: '#a855f7', flame: '#c084fc', glow: 'rgba(168,85,247,0.4)' }
    : streak.weeks >= 1
    ? { beer: '#3b82f6', flame: '#60a5fa', glow: 'rgba(59,130,246,0.35)' }
    : { beer: '#6b7280', flame: '#9ca3af', glow: 'transparent' };

  const handleShare = async () => {
    const url = window.location.origin + `/profile/${profile.user_id}`;
    if (navigator.share) {
      try {
        await navigator.share({ title: profile.pseudo, url });
      } catch (err: unknown) {
        console.warn('Share failed', err);
        toast.error('Partage échoué');
      }
    } else {
      try {
        await navigator.clipboard.writeText(url);
        toast.success('Lien copié ! 📋');
      } catch (err: unknown) {
        console.warn('Clipboard write failed', err);
        toast.error('Impossible de copier le lien');
      }
    }
  };

  return (
    <AnimatePresence>
      {isOpen && (
        <motion.div 
          initial={{ opacity: 0 }} 
          animate={{ opacity: 1 }} 
          exit={{ opacity: 0 }}
          onClick={onClose}
          className="fixed inset-0 z-[60] bg-black/60 backdrop-blur-sm flex items-center justify-center p-4"
        >
          <motion.div
            initial={{ scale: 0.9, opacity: 0 }} 
            animate={{ scale: 1, opacity: 1 }} 
            exit={{ scale: 0.9, opacity: 0 }}
            transition={{ type: 'spring', damping: 25, stiffness: 300 }}
            onClick={e => e.stopPropagation()}
            className="w-full max-w-sm bg-background rounded-3xl max-h-[80vh] overflow-hidden shadow-2xl relative"
          >
            <motion.button 
              whileTap={{ scale: 0.9 }} 
              onClick={onClose}
              className="absolute top-3 right-4 w-10 h-10 rounded-full bg-black/40 backdrop-blur flex items-center justify-center z-10"
            >
              <X className="w-5 h-5 text-white" />
            </motion.button>

            <div className="overflow-y-auto max-h-[75vh]" style={{ WebkitOverflowScrolling: 'touch' }}>
              <div className="px-6 pt-4 pb-6">
                {/* Avatar avec frame + streak badge */}
                <div className="flex justify-center mb-3" style={{ overflow: 'visible' }}>
                  <div className="relative" style={{ overflow: 'visible' }}>
                    {/* Frame ring */}
                    <div className="w-28 h-28 rounded-full p-[3px]"
                      style={{
                        background: frameVisual?.gradient || 'linear-gradient(135deg, hsl(263 90% 66%), hsl(188 86% 43%))',
                        boxShadow: frameVisual ? `0 0 20px ${frameVisual.glow}` : undefined,
                        animation: frameVisual?.animated ? 'spin 4s linear infinite' : undefined,
                      }}>
                      <div className="w-full h-full rounded-full bg-background overflow-hidden flex items-center justify-center">
                        {profile.avatar_url
                          ? <img src={profile.avatar_url} alt={profile.pseudo} className="w-full h-full object-cover" />
                          : <span className="text-4xl font-bold text-primary">{profile.pseudo?.charAt(0).toUpperCase() || '?'}</span>
                        }
                      </div>
                    </div>
                    {/* Streak badge bottom-right side */}
                    {streak.weeks > 0 && (
                      <div className="absolute -bottom-1 -right-1 flex flex-col items-center"
                        style={{ filter: `drop-shadow(0 0 6px ${streakCfg.glow})` }}>
                        <div className="relative" style={{ width: 44, height: 44 }}>
                          {/* Beer mug SVG */}
                          <svg width="32" height="32" viewBox="0 0 32 32" fill="none"
                            style={{ position: 'absolute', bottom: 0, left: '50%', transform: 'translateX(-50%)' }}>
                            <rect x="4" y="10" width="18" height="18" rx="3" fill={streakCfg.beer} />
                            <path d="M22 14 C28 14 28 24 22 24" stroke={streakCfg.beer} strokeWidth="3" strokeLinecap="round" fill="none" />
                            <ellipse cx="13" cy="10" rx="9" ry="4" fill="white" opacity="0.9" />
                            <circle cx="9" cy="20" r="1.5" fill="white" opacity="0.25" />
                            <circle cx="14" cy="17" r="1" fill="white" opacity="0.2" />
                          </svg>
                          {/* Flame SVG — top right of mug */}
                          <svg width="16" height="20" viewBox="0 0 20 24" fill="none"
                            style={{ position: 'absolute', top: -4, right: 0 }}>
                            <path d="M10 2 C10 2 14 7 14 11 C14 13.5 12.5 15 12.5 15 C12.5 15 14 13 13 10 C13 10 16 14 14 18 C12.8 20.5 10 22 10 22 C10 22 7.2 20.5 6 18 C4 14 7 10 7 10 C6 13 7.5 15 7.5 15 C7.5 15 6 13.5 6 11 C6 7 10 2 10 2Z" fill={streakCfg.flame} />
                            <path d="M10 10 C10 10 12 13 11.5 15.5 C11 17.5 10 18.5 10 18.5 C10 18.5 9 17.5 8.5 15.5 C8 13 10 10 10 10Z" fill="white" opacity="0.5" />
                          </svg>
                          {/* Week count */}
                          <div style={{
                            position: 'absolute', bottom: -2, right: -4,
                            background: streakCfg.beer, borderRadius: 999,
                            minWidth: 18, height: 18,
                            display: 'flex', alignItems: 'center', justifyContent: 'center',
                            padding: '0 4px', fontSize: '10px', fontWeight: 700, color: 'white',
                            boxShadow: `0 0 6px ${streakCfg.glow}`,
                          }}>
                            {streak.weeks}
                          </div>
                        </div>
                      </div>
                    )}
                  </div>
                </div>

                {/* Nom + bio */}
                <div className="text-center mb-2 space-y-1">
                  <h2 className="text-2xl font-bold bg-gradient-to-r from-primary to-accent bg-clip-text text-transparent">{profile.pseudo}</h2>
                  {profile.bio && <p className="text-sm text-muted-foreground italic px-2">"{profile.bio}"</p>}
                </div>

                {/* Infos perso chips */}
                {(profile.city || profile.school || profile.job || profile.zodiac || profile.music_taste || profile.party_style) && (
                  <div className="flex flex-wrap gap-2 justify-center mb-3">
                    {profile.city && <span className="text-xs glass-card px-2.5 py-1 rounded-full">📍 {profile.city}</span>}
                    {profile.school && <span className="text-xs glass-card px-2.5 py-1 rounded-full">🎓 {profile.school}</span>}
                    {profile.job && <span className="text-xs glass-card px-2.5 py-1 rounded-full">💼 {profile.job}</span>}
                    {profile.zodiac && <span className="text-xs glass-card px-2.5 py-1 rounded-full">{profile.zodiac}</span>}
                    {profile.music_taste && <span className="text-xs glass-card px-2.5 py-1 rounded-full">🎵 {profile.music_taste}</span>}
                    {profile.party_style && <span className="text-xs glass-card px-2.5 py-1 rounded-full">{profile.party_style}</span>}
                  </div>
                )}

                {/* Réseaux sociaux */}
                {(profile.snapchat || profile.instagram || profile.tiktok) && (
                  <div className="flex gap-2 justify-center mb-3">
                    {profile.snapchat && (
                      <a href={`https://snapchat.com/add/${profile.snapchat}`} target="_blank" rel="noopener noreferrer"
                        className="flex items-center gap-1.5 px-3 py-1.5 rounded-full text-xs font-bold"
                        style={{ background: '#FFFC00', color: '#000' }}>
                        👻 {profile.snapchat}
                      </a>
                    )}
                    {profile.instagram && (
                      <a href={`https://instagram.com/${profile.instagram.replace('@','')}`} target="_blank" rel="noopener noreferrer"
                        className="flex items-center gap-1.5 px-3 py-1.5 rounded-full text-xs font-bold text-white"
                        style={{ background: 'linear-gradient(135deg, #f09433, #e6683c, #dc2743, #cc2366, #bc1888)' }}>
                        📸 {profile.instagram}
                      </a>
                    )}
                    {profile.tiktok && (
                      <a href={`https://tiktok.com/@${profile.tiktok.replace('@','')}`} target="_blank" rel="noopener noreferrer"
                        className="flex items-center gap-1.5 px-3 py-1.5 rounded-full text-xs font-bold text-white"
                        style={{ background: '#010101' }}>
                        🎵 {profile.tiktok}
                      </a>
                    )}
                  </div>
                )}

                {/* Custom cards horizontal */}
                {profile.custom_cards && profile.custom_cards.length > 0 && (
                  <div className="flex gap-3 overflow-x-auto pb-1 mb-3 snap-x">
                    {profile.custom_cards.map(card => (
                      <div key={card.id} className="glass-card p-3 rounded-2xl border border-primary/20 shrink-0 snap-start min-w-[140px]">
                        {card.icon && <span className="text-2xl block mb-1">{card.icon}</span>}
                        <p className="text-[9px] text-muted-foreground uppercase font-semibold">{card.title}</p>
                        <p className="text-sm font-bold text-primary mt-0.5">{card.value}</p>
                      </div>
                    ))}
                  </div>
                )}

                {/* Téléphone */}
                {profile.phone && (
                  <a href={`tel:${profile.phone}`}
                    className="w-full glass-card p-4 flex items-center gap-3 rounded-2xl border border-accent/30 mb-3">
                    <Phone className="w-5 h-5 text-accent" />
                    <div className="flex-1">
                      <p className="text-[10px] text-muted-foreground uppercase">Téléphone</p>
                      <p className="font-medium">{profile.phone}</p>
                    </div>
                    <span className="text-accent">📞</span>
                  </a>
                )}

                {/* Actions */}
                {showActions && (
                  <div className="space-y-2">
                    {!isCurrentUser && !isFriend && (
                      <motion.button whileTap={{ scale: 0.95 }} onClick={() => { onAddFriend?.(); onClose(); }}
                        className="w-full glass-button bg-gradient-to-r from-primary/30 to-accent/30 py-3 font-semibold flex items-center justify-center gap-2 rounded-2xl border border-primary/30">
                        <UserPlus className="w-5 h-5" /> Ajouter en ami
                      </motion.button>
                    )}
                    {!isCurrentUser && !isPartyMember && (
                      <motion.button whileTap={{ scale: 0.95 }} onClick={() => { onInviteToParty?.(); onClose(); }}
                        className="w-full glass-button bg-gradient-to-r from-accent/30 to-primary/30 py-3 font-semibold flex items-center justify-center gap-2 rounded-2xl border border-accent/30">
                        <MessageCircle className="w-5 h-5" /> Inviter à la soirée
                      </motion.button>
                    )}
                    <motion.button whileTap={{ scale: 0.95 }} onClick={handleShare}
                      className="w-full glass-button bg-gradient-to-r from-blue-500/30 to-cyan-500/30 py-3 font-semibold flex items-center justify-center gap-2 rounded-2xl border border-blue-500/30">
                      <Share2 className="w-5 h-5" /> Partager le profil
                    </motion.button>
                  </div>
                )}
              </div>
            </div>
          </motion.div>
        </motion.div>
      )}
    </AnimatePresence>
  );
}
