import { motion } from 'framer-motion';
import { Trophy, Droplets } from 'lucide-react';
import { useState } from 'react';
import { DrinkEntry, Profile, PukeEvent, ShopEvent, calculateBAC } from '@/hooks/useSupabase';
import UserProfileModal from './UserProfileModal';

interface PartyMemberWithProfile {
  id: string;
  party_id: string;
  user_id: string;
  joined_at: string;
  show_bac?: boolean;
  profile?: Profile;
}

interface Props {
  members: PartyMemberWithProfile[];
  drinks: DrinkEntry[];
  pukeEvents?: PukeEvent[];
  shopEvents?: ShopEvent[];
  friends?: (Profile & { user_id: string })[];
  currentUserId?: string;
}

export default function LeaderboardPanel({ members, drinks, pukeEvents = [], shopEvents = [], friends = [], currentUserId }: Props) {
  const [selectedProfile, setSelectedProfile] = useState<Profile | null>(null);
  const [isModalOpen, setIsModalOpen] = useState(false);
  if (members.length === 0) {
    return (
      <div className="glass-card p-8 text-center space-y-3">
        <Trophy className="w-12 h-12 text-muted-foreground mx-auto" />
        <p className="text-muted-foreground text-sm">Rejoins une soirée pour voir le classement !</p>
      </div>
    );
  }

  // Only show members who have BAC visibility enabled (default: true)
  const visibleMembers = members.filter(m => m.show_bac !== false);

  // Calculate stats per member
  const stats = visibleMembers.map(m => {
    const memberDrinks = drinks.filter(d => d.user_id === m.user_id);
    const alcoholDrinks = memberDrinks.filter(d => d.abv > 0);
    const waterDrinks = memberDrinks.filter(d => d.abv === 0);
    const totalAlcohol = alcoholDrinks.reduce((sum, d) => sum + d.alcohol_grams, 0);
    const bac = m.profile
      ? calculateBAC(memberDrinks, m.profile.weight, m.profile.gender as 'male' | 'female')
      : 0;

    return {
      ...m,
      totalAlcohol,
      waterCount: waterDrinks.length,
      drinkCount: alcoholDrinks.length,
      bac,
    };
  });

  const partyKings = [...stats].sort((a, b) => b.totalAlcohol - a.totalAlcohol);
  const hydrationHeroes = [...stats].sort((a, b) => b.waterCount - a.waterCount);

  return (
    <div className="space-y-6">
      {/* Party Kings */}
      <div className="space-y-3">
        <div className="flex items-center gap-2">
          <Trophy className="w-4 h-4 text-primary" />
          <p className="text-xs uppercase tracking-widest text-muted-foreground">Party King 👑</p>
        </div>
        {partyKings.map((s, i) => (
          <motion.div key={s.id} initial={{ opacity: 0, x: -20 }} animate={{ opacity: 1, x: 0 }}
            transition={{ delay: i * 0.1 }}
            className={`glass-card p-4 flex items-center justify-between cursor-pointer hover:bg-primary/5 transition-colors ${i === 0 ? 'neon-glow-violet' : ''}`}
            onClick={() => s.profile && (setSelectedProfile(s.profile), setIsModalOpen(true))}>
            <div className="flex items-center gap-3">
              <span className="text-2xl font-bold text-muted-foreground w-8">
                {i === 0 ? '👑' : i === 1 ? '🥈' : i === 2 ? '🥉' : `${i + 1}`}
              </span>
              <div className="w-9 h-9 rounded-full bg-primary/20 flex items-center justify-center text-sm font-bold overflow-hidden">
                {s.profile?.avatar_url ? (
                  <img src={s.profile.avatar_url} alt={s.profile.pseudo} className="w-full h-full object-cover" />
                ) : (
                  s.profile?.pseudo?.charAt(0).toUpperCase() || '?'
                )}
              </div>
              <div>
                <p className="font-semibold text-sm">{s.profile?.pseudo || 'Anonyme'}</p>
                <p className="text-xs text-muted-foreground">{s.drinkCount} verres</p>
              </div>
            </div>
            <div className="text-right">
              <p className={`font-mono font-bold ${s.bac >= 0.5 ? 'bac-danger' : s.bac >= 0.2 ? 'bac-warning' : 'bac-safe'}`}>
                {s.bac.toFixed(2)}
              </p>
              <p className="text-[10px] text-muted-foreground">g/l</p>
            </div>
          </motion.div>
        ))}
      </div>

      {/* Hydration Heroes */}
      <div className="space-y-3">
        <div className="flex items-center gap-2">
          <Droplets className="w-4 h-4 text-accent" />
          <p className="text-xs uppercase tracking-widest text-muted-foreground">Hydration Hero 💧</p>
        </div>
        {hydrationHeroes.filter(s => s.waterCount > 0).map((s, i) => (
          <motion.div key={s.id} initial={{ opacity: 0, x: -20 }} animate={{ opacity: 1, x: 0 }}
            transition={{ delay: i * 0.1 }}
            className={`glass-card p-4 flex items-center justify-between cursor-pointer hover:bg-accent/5 transition-colors ${i === 0 ? 'neon-glow-cyan' : ''}`}
            onClick={() => s.profile && (setSelectedProfile(s.profile), setIsModalOpen(true))}>
            <div className="flex items-center gap-3">
              <span className="text-2xl">{i === 0 ? '🏆' : '💧'}</span>
              <div className="w-9 h-9 rounded-full bg-accent/20 flex items-center justify-center text-sm font-bold overflow-hidden">
                {s.profile?.avatar_url ? (
                  <img src={s.profile.avatar_url} alt={s.profile.pseudo} className="w-full h-full object-cover" />
                ) : (
                  s.profile?.pseudo?.charAt(0).toUpperCase() || '?'
                )}
              </div>
              <p className="font-semibold text-sm">{s.profile?.pseudo || 'Anonyme'}</p>
            </div>
            <p className="font-mono text-accent font-bold">{s.waterCount} 💧</p>
          </motion.div>
        ))}
        {hydrationHeroes.filter(s => s.waterCount > 0).length === 0 && (
          <p className="text-sm text-muted-foreground text-center glass-card p-4">Personne n'a bu d'eau... 😅</p>
        )}
      </div>

      {/* Quiche Kings */}
      <div className="space-y-3">
        <div className="flex items-center gap-2">
          <span className="text-lg">🤢</span>
          <p className="text-xs uppercase tracking-widest text-muted-foreground">Quiche King</p>
        </div>
        {(() => {
          const quicheStats = members.map(m => ({
            ...m,
            quicheCount: pukeEvents.filter(e => e.user_id === m.user_id).length,
          }));
          const quicheKings = [...quicheStats].sort((a, b) => b.quicheCount - a.quicheCount);
          
          return quicheKings.filter(s => s.quicheCount > 0).map((s, i) => (
            <motion.div key={s.id} initial={{ opacity: 0, x: -20 }} animate={{ opacity: 1, x: 0 }}
              transition={{ delay: i * 0.1 }}
              className={`glass-card p-4 flex items-center justify-between cursor-pointer hover:bg-destructive/5 transition-colors ${i === 0 ? 'neon-glow-red' : ''}`}
              onClick={() => s.profile && (setSelectedProfile(s.profile), setIsModalOpen(true))}>
              <div className="flex items-center gap-3">
                <span className="text-2xl">{i === 0 ? '👑' : '🤢'}</span>
                <div className="w-9 h-9 rounded-full bg-destructive/20 flex items-center justify-center text-sm font-bold overflow-hidden">
                  {s.profile?.avatar_url ? (
                    <img src={s.profile.avatar_url} alt={s.profile.pseudo} className="w-full h-full object-cover" />
                  ) : (
                    s.profile?.pseudo?.charAt(0).toUpperCase() || '?'
                  )}
                </div>
                <p className="font-semibold text-sm">{s.profile?.pseudo || 'Anonyme'}</p>
              </div>
              <p className="font-mono text-destructive font-bold">{s.quicheCount}</p>
            </motion.div>
          ));
        })()}
        {members.every(m => pukeEvents.filter(e => e.user_id === m.user_id).length === 0) && (
          <p className="text-sm text-muted-foreground text-center glass-card p-4">Personne n'a quiché... Tant mieux! 🎉</p>
        )}
      </div>

      {/* Shop Kings */}
      <div className="space-y-3">
        <div className="flex items-center gap-2">
          <span className="text-lg">💋</span>
          <p className="text-xs uppercase tracking-widest text-muted-foreground">Shop King ✨</p>
        </div>
        {(() => {
          const shopStats = members.map(m => ({
            ...m,
            shopCount: shopEvents.filter(e => e.user_id === m.user_id).length,
          }));
          const shopKings = [...shopStats].sort((a, b) => b.shopCount - a.shopCount);
          
          return shopKings.filter(s => s.shopCount > 0).map((s, i) => (
            <motion.div key={s.id} initial={{ opacity: 0, x: -20 }} animate={{ opacity: 1, x: 0 }}
              transition={{ delay: i * 0.1 }}
              className={`glass-card p-4 flex items-center justify-between cursor-pointer transition-colors ${i === 0 ? 'neon-glow-pink' : ''}`}
              style={{
                background: i === 0 ? 'linear-gradient(135deg, rgba(236, 72, 153, 0.1) 0%, rgba(249, 115, 22, 0.1) 100%)' : undefined,
              }}
              onClick={() => s.profile && (setSelectedProfile(s.profile), setIsModalOpen(true))}>
              <div className="flex items-center gap-3">
                <span className="text-2xl">{i === 0 ? '👑' : '💋'}</span>
                <div className="w-9 h-9 rounded-full flex items-center justify-center text-sm font-bold overflow-hidden"
                  style={{
                    background: 'linear-gradient(135deg, rgba(236, 72, 153, 0.2) 0%, rgba(249, 115, 22, 0.2) 100%)',
                  }}>
                  {s.profile?.avatar_url ? (
                    <img src={s.profile.avatar_url} alt={s.profile.pseudo} className="w-full h-full object-cover" />
                  ) : (
                    s.profile?.pseudo?.charAt(0).toUpperCase() || '?'
                  )}
                </div>
                <p className="font-semibold text-sm">{s.profile?.pseudo || 'Anonyme'}</p>
              </div>
              <p className="font-mono font-bold" style={{ color: '#ec4899' }}>{s.shopCount}✨</p>
            </motion.div>
          ));
        })()}
        {members.every(m => shopEvents.filter(e => e.user_id === m.user_id).length === 0) && (
          <p className="text-sm text-muted-foreground text-center glass-card p-4">Personne n'a shopé... À vous de jouer! 💋</p>
        )}
      </div>

      <UserProfileModal
        profile={selectedProfile}
        isOpen={isModalOpen}
        onClose={() => setIsModalOpen(false)}
        isFriend={selectedProfile ? friends.some(f => f.user_id === selectedProfile.user_id) : false}
        isPartyMember={selectedProfile ? members.some(m => m.user_id === selectedProfile.user_id) : false}
        currentUserId={currentUserId}
        onAddFriend={() => {
          // TODO: Implement add friend functionality
        }}
        onInviteToParty={() => {
          // TODO: Implement invite to party functionality
        }}
      />
    </div>
  );
}
