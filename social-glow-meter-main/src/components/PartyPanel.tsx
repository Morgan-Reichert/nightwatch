import { useState, useRef, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { Plus, Hash, Users, Trash2, LogOut, MapPin, Camera, Image, AlertTriangle, Phone, UserPlus, X, MessageCircle, CheckCircle2, XCircle } from 'lucide-react';
import { Party, Profile, PartyPhoto, MemberLocation, DrinkEntry, PartyRequest, PukeEvent, ShopEvent, calculateBAC } from '@/hooks/useSupabase';
import { useAuth } from '@/contexts/AuthContext';
import { toast } from 'sonner';
import { playSfx } from '@/lib/sound';
import UserProfileModal from './UserProfileModal';

interface PartyMemberWithProfile {
  id: string;
  party_id: string;
  user_id: string;
  joined_at: string;
  profile?: Profile;
}

interface Props {
  parties: Party[];
  currentParty: Party | null;
  members: PartyMemberWithProfile[];
  friends: (Profile & { user_id: string })[];
  photos: (PartyPhoto & { profile?: Profile })[];
  locations: (MemberLocation & { profile?: Profile })[];
  drinks: DrinkEntry[];
  allMyDrinks: DrinkEntry[];
  partyInvitations: (PartyRequest & { profile?: Profile; party?: Party })[];
  pukeEvents?: PukeEvent[];
  shopEvents?: ShopEvent[];
  currentUserId?: string;
  onSelect: (party: Party) => void;
  onCreate: (name: string) => Promise<void>;
  onJoin: (code: string) => Promise<void>;
  onLeave: (partyId: string) => Promise<void>;
  onDelete: (partyId: string) => Promise<void>;
  onAddPhoto: (file: File, caption: string, partyId: string) => Promise<void>;
  onUpdateLocation: (partyId: string) => Promise<void>;
  onAcceptInvitation: (invitationId: string, partyId: string) => Promise<void>;
  onRejectInvitation: (invitationId: string) => Promise<void>;
  onInviteMember: (partyId: string, userId: string) => Promise<void>;
}

export default function PartyPanel({ parties, currentParty, members, friends, photos, locations, drinks, allMyDrinks, partyInvitations, pukeEvents = [], shopEvents = [], currentUserId, onSelect, onCreate, onJoin, onLeave, onDelete, onAddPhoto, onUpdateLocation, onAcceptInvitation, onRejectInvitation, onInviteMember }: Props) {
  const { user } = useAuth();
  const [newName, setNewName] = useState('');
  const [joinCode, setJoinCode] = useState('');
  const [creating, setCreating] = useState(false);
  const [showPhotos, setShowPhotos] = useState(false);
  const [showMap, setShowMap] = useState(false);
  const [selectedMember, setSelectedMember] = useState<PartyMemberWithProfile | null>(null);
  const [selectedProfile, setSelectedProfile] = useState<Profile | null>(null);
  const [isProfileModalOpen, setIsProfileModalOpen] = useState(false);

  const [dismissedInvitations, setDismissedInvitations] = useState<Set<string>>(new Set());

  const visibleInvitations = partyInvitations.filter(i => !dismissedInvitations.has(i.id));

  useEffect(() => {
    setDismissedInvitations(prev => new Set([...prev].filter(id => partyInvitations.some(i => i.id === id))));
  }, [partyInvitations]);
  const cameraInputRef = useRef<HTMLInputElement>(null);
  const galleryInputRef = useRef<HTMLInputElement>(null);

  const isAdmin = currentParty && user ? currentParty.created_by === user.id : false;
  const [showConfetti, setShowConfetti] = useState(false);
  const [showRejectSplash, setShowRejectSplash] = useState(false);
  const [acceptedPartyName, setAcceptedPartyName] = useState<string | null>(null);

  useEffect(() => {
    if (!showConfetti) return;
    const timer = window.setTimeout(() => setShowConfetti(false), 1600);
    return () => window.clearTimeout(timer);
  }, [showConfetti]);

  useEffect(() => {
    if (!showRejectSplash) return;
    const timer = window.setTimeout(() => setShowRejectSplash(false), 900);
    return () => window.clearTimeout(timer);
  }, [showRejectSplash]);

  const handleAcceptInvitation = async (invitation: { id: string; party_id: string; party?: Party }) => {
    try {
      await onAcceptInvitation(invitation.id, invitation.party_id);
      setAcceptedPartyName(invitation.party?.name || 'la soirée');
      setShowConfetti(true);
      playSfx('success');
      if (invitation.party) {
        onSelect(invitation.party);
      }
    } catch (error: any) {
      toast.error(error?.message || 'Impossible d\'accepter l\'invitation');
    }
  };

  const handlePhotoUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file || !currentParty) return;
    try {
      await onAddPhoto(file, '', currentParty.id);
      toast.success('Photo ajoutée ! 📸');
    } catch (err: any) {
      toast.error(err.message);
    }
  };

  const handleGalleryUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file || !currentParty) return;
    try {
      await onAddPhoto(file, '', currentParty.id);
      toast.success('Photo importée ! 📸');
    } catch (err: any) {
      toast.error(err.message);
    }
  };

  return (
    <div className="space-y-6">
      <input ref={cameraInputRef} type="file" accept="image/*" capture="environment" className="hidden" onChange={handlePhotoUpload} />
      <input ref={galleryInputRef} type="file" accept="image/*" className="hidden" onChange={handleGalleryUpload} />

      {showConfetti && (
        <div className="pointer-events-none fixed inset-0 z-50 flex items-center justify-center">
          <div className="absolute inset-0 bg-black/20 backdrop-blur-sm" />
          <div className="relative w-full h-full overflow-hidden">
            {Array.from({ length: 30 }).map((_, idx) => (
              <span key={idx}
                className="confetti-piece absolute w-1 h-4 rounded-sm"
                style={{
                  background: `linear-gradient(45deg, hsl(${Math.floor(Math.random()*360)}, 80%, 60%), hsl(${Math.floor(Math.random()*360)}, 70%, 55%))`,
                  left: `${Math.random() * 100}%`,
                  top: `${Math.random() * 30}%`,
                  transform: `rotate(${Math.random() * 360}deg)`,
                  animationDelay: `${(Math.random() * 0.3).toFixed(2)}s`,
                }}
              />
            ))}
          </div>
          <div className="relative z-10 text-center text-lg font-bold text-white bg-black/40 px-4 py-3 rounded-lg">
            🎉 Tu as rejoint {acceptedPartyName || 'la soirée'} !
          </div>
        </div>
      )}

      {showRejectSplash && (
        <motion.div
          initial={{ scale: 0.8, opacity: 0 }}
          animate={{ scale: 1.2, opacity: 1 }}
          exit={{ scale: 0.8, opacity: 0 }}
          className="pointer-events-none fixed inset-0 z-50 flex items-center justify-center"
        >
          <div className="absolute inset-0 bg-black/0" />
          <div className="relative flex items-center justify-center">
            <div className="text-8xl font-black text-red-500 drop-shadow-[0_0_20px_rgba(239,68,68,0.6)] animate-[pulse_0.7s_ease-in-out]">✕</div>
          </div>
        </motion.div>
      )}

      {/* PENDING INVITATIONS - PROMINENT SECTION AT TOP */}
      {visibleInvitations.length > 0 && (
        <motion.div
          initial={{ opacity: 0, y: -10 }}
          animate={{ opacity: 1, y: 0 }}
          className="space-y-2 border-l-4 border-accent p-4 bg-gradient-to-r from-accent/20 to-accent/5 rounded-lg">
          <p className="text-sm font-bold text-accent uppercase tracking-widest">📬 {visibleInvitations.length} Invitation{visibleInvitations.length > 1 ? 's' : ''} en attente</p>
          {visibleInvitations.map(inv => (
            <div
              key={inv.id}
              className="glass-card p-3 flex items-center gap-3 bg-accent/10 border border-accent/30 rounded-lg">
              <div className="w-8 h-8 rounded-full bg-accent/30 flex items-center justify-center shrink-0 text-lg">
                🎉
              </div>
              <div className="flex-1 min-w-0">
                <p className="font-semibold text-sm">{inv.party?.name}</p>
                <p className="text-[10px] text-muted-foreground">Clique pour répondre</p>
              </div>
              <div className="flex gap-2 shrink-0">
                <motion.button
                  whileTap={{ scale: 0.95 }}
                  onClick={async () => {
                    try {
                      await onAcceptInvitation(inv.id, inv.party_id);
                      setDismissedInvitations(prev => new Set(prev).add(inv.id));
                      playSfx('success');
                      if (inv.party) {
                        onSelect(inv.party);
                        setAcceptedPartyName(inv.party.name);
                      }
                      setShowConfetti(true);
                      toast.success(`Bienvenue dans ${inv.party?.name || 'la soirée'} ! 🎉`);
                    } catch (e: any) {
                      toast.error(e.message);
                    }
                  }}
                  className="bg-primary/30 hover:bg-primary/40 text-primary px-3 py-1 rounded text-xs font-semibold transition-colors">
                  ✅ Accepter
                </motion.button>
                <motion.button
                  whileTap={{ scale: 0.95 }}
                  onClick={async () => {
                    try {
                      await onRejectInvitation(inv.id);
                      setDismissedInvitations(prev => new Set(prev).add(inv.id));
                      setShowRejectSplash(true);
                      playSfx('error');
                      toast.success('Invitation refusée');
                    } catch (e: any) {
                      toast.error(e.message);
                    }
                  }}
                  className="bg-destructive/30 hover:bg-destructive/40 text-destructive px-3 py-1 rounded text-xs font-semibold transition-colors">
                  ❌ Refuser
                </motion.button>
              </div>
            </div>
          ))}
        </motion.div>
      )}

      {/* Create or join */}
      <div className="grid grid-cols-2 gap-3">
        <div className="glass-card p-4 space-y-3">
          <p className="text-xs uppercase tracking-widest text-muted-foreground">Créer</p>
          <input value={newName} onChange={e => setNewName(e.target.value)} placeholder="Nom de la soirée"
            className="w-full bg-transparent text-sm border-b border-muted pb-1 focus:outline-none focus:border-primary" />
          <motion.button whileTap={{ scale: 0.95 }} disabled={!newName.trim() || creating}
            onClick={async () => {
              setCreating(true);
              try { await onCreate(newName); setNewName(''); } catch (e: any) { toast.error(e.message); }
              setCreating(false);
            }}
            className="w-full glass-button bg-primary/20 text-primary text-xs py-2 font-semibold disabled:opacity-50">
            <Plus className="w-3 h-3 inline mr-1" /> Créer
          </motion.button>
        </div>

        <div className="glass-card p-4 space-y-3">
          <p className="text-xs uppercase tracking-widest text-muted-foreground">Rejoindre</p>
          <input value={joinCode} onChange={e => setJoinCode(e.target.value)} placeholder="Code #"
            className="w-full bg-transparent text-sm border-b border-muted pb-1 focus:outline-none focus:border-accent font-mono" />
          <motion.button whileTap={{ scale: 0.95 }} disabled={!joinCode.trim()}
            onClick={async () => {
              try { await onJoin(joinCode); setJoinCode(''); } catch (e: any) { toast.error(e.message); }
            }}
            className="w-full glass-button bg-accent/20 text-accent text-xs py-2 font-semibold disabled:opacity-50">
            <Hash className="w-3 h-3 inline mr-1" /> Rejoindre
          </motion.button>
        </div>
      </div>

      {/* Current party */}
      {currentParty && (
        <div className="space-y-3">
          <div className="flex items-center justify-between">
            <p className="text-xs uppercase tracking-widest text-muted-foreground">
              {currentParty.name}
            </p>
            <span className="text-xs font-mono bg-primary/20 text-primary px-2 py-0.5 rounded-full">
              #{currentParty.code}
            </span>
          </div>

          {/* Invitations section is already displayed above and shared globally */}

          {/* Party actions */}
          <div className="grid grid-cols-4 gap-2">
            <motion.button whileTap={{ scale: 0.95 }} onClick={() => cameraInputRef.current?.click()}
              className="glass-card p-3 flex flex-col items-center gap-1">
              <Camera className="w-5 h-5 text-accent" />
              <span className="text-[10px] text-muted-foreground">Caméra</span>
            </motion.button>
            <motion.button whileTap={{ scale: 0.95 }} onClick={() => setShowPhotos(!showPhotos)}
              className="glass-card p-3 flex flex-col items-center gap-1">
              <Image className="w-5 h-5 text-primary" />
              <span className="text-[10px] text-muted-foreground">{photos.length}</span>
            </motion.button>
            <motion.button whileTap={{ scale: 0.95 }} onClick={() => { onUpdateLocation(currentParty.id); setShowMap(!showMap); }}
              className="glass-card p-3 flex flex-col items-center gap-1">
              <MapPin className="w-5 h-5 text-accent" />
              <span className="text-[10px] text-muted-foreground">Loca</span>
            </motion.button>
            {isAdmin ? (
              <motion.button whileTap={{ scale: 0.95 }} onClick={async () => {
                if (confirm('Supprimer cette soirée ?')) { await onDelete(currentParty.id); toast.success('Soirée supprimée'); }
              }} className="glass-card p-3 flex flex-col items-center gap-1 border-destructive/30">
                <Trash2 className="w-5 h-5 text-destructive" />
                <span className="text-[10px] text-muted-foreground">Suppr</span>
              </motion.button>
            ) : (
              <motion.button whileTap={{ scale: 0.95 }} onClick={async () => {
                if (confirm('Quitter cette soirée ?')) { await onLeave(currentParty.id); toast.success('Tu as quitté la soirée'); }
              }} className="glass-card p-3 flex flex-col items-center gap-1">
                <LogOut className="w-5 h-5 text-muted-foreground" />
                <span className="text-[10px] text-muted-foreground">Quitter</span>
              </motion.button>
            )}
          </div>

          {/* Photos gallery */}
          {showPhotos && (
            <div className="space-y-3">
              <div className="flex items-center justify-between">
                <p className="text-xs uppercase tracking-widest text-muted-foreground">Photos de la soirée</p>
                <motion.button whileTap={{ scale: 0.95 }} onClick={() => galleryInputRef.current?.click()}
                  className="text-xs bg-primary/20 text-primary px-2 py-1 rounded-full hover:bg-primary/30 transition-colors">
                  + Importer
                </motion.button>
              </div>
              {photos.length > 0 ? (
                <div className="grid grid-cols-3 gap-2">
                  {photos.map(p => (
                    <div key={p.id} className="aspect-square rounded-2xl overflow-hidden relative">
                      <img src={p.image_url} alt="" className="w-full h-full object-cover" />
                      <div className="absolute bottom-0 left-0 right-0 bg-gradient-to-t from-black/60 p-1">
                        <p className="text-[9px] text-white truncate">{p.profile?.pseudo}</p>
                      </div>
                    </div>
                  ))}
                </div>
              ) : (
                <div className="glass-card p-4 text-center">
                  <p className="text-sm text-muted-foreground mb-3">Aucune photo pour le moment</p>
                  <motion.button whileTap={{ scale: 0.95 }} onClick={() => galleryInputRef.current?.click()}
                    className="text-sm bg-primary/20 text-primary px-3 py-2 rounded-lg hover:bg-primary/30 transition-colors">
                    Importer des photos
                  </motion.button>
                </div>
              )}
            </div>
          )}

          {/* Location map placeholder */}
          {showMap && (
            <div className="space-y-2">
              <p className="text-xs uppercase tracking-widest text-muted-foreground">Localisation des membres</p>
              {locations.length === 0 ? (
                <p className="text-sm text-muted-foreground glass-card p-4 text-center">Aucune position partagée pour le moment</p>
              ) : (
                <div className="space-y-2">
                  {locations.map(l => (
                    <a key={l.id} href={`https://maps.google.com/?q=${l.latitude},${l.longitude}`} target="_blank" rel="noopener noreferrer"
                      className="glass-card p-3 flex items-center gap-3">
                      <MapPin className="w-4 h-4 text-accent shrink-0" />
                      <div className="flex-1">
                        <p className="text-sm font-medium">{l.profile?.pseudo || 'Anonyme'}</p>
                        <p className="text-[10px] text-muted-foreground">
                          Mis à jour {new Date(l.updated_at).toLocaleTimeString('fr-FR', { hour: '2-digit', minute: '2-digit' })}
                        </p>
                      </div>
                      <span className="text-[10px] text-accent">Voir →</span>
                    </a>
                  ))}
                </div>
              )}
            </div>
          )}

          {/* Members */}
          <div className="space-y-2">
            <p className="text-xs uppercase tracking-widest text-muted-foreground">Membres ({members.length})</p>
            {members.map(m => {
              // Use allMyDrinks for current user, partyDrinks for others
              const memberDrinks = m.user_id === currentUserId ? allMyDrinks : drinks.filter(d => d.user_id === m.user_id);
              const bac = m.profile ? calculateBAC(memberDrinks, m.profile.weight, m.profile.gender as 'male' | 'female') : 0;
              const isDanger = bac > 1.0;
              const isWarning = bac >= 0.5 && bac < 1.0;
              
              return (
                <motion.div
                  key={m.id}
                  onClick={() => m.profile && (setSelectedProfile(m.profile), setIsProfileModalOpen(true))}
                  className={`w-full glass-card p-3 flex items-center gap-3 hover:bg-primary/5 transition-colors text-left cursor-pointer ${isDanger ? 'border-destructive/50 bg-destructive/5' : isWarning ? 'border-yellow-500/30 bg-yellow-500/5' : ''}`}>
                  <div className={`w-8 h-8 rounded-full flex items-center justify-center text-sm font-bold shrink-0 ${isDanger ? 'bg-destructive/30 text-destructive' : isWarning ? 'bg-yellow-500/30 text-yellow-600' : 'bg-primary/20'}`}>
                    {m.profile?.avatar_url ? (
                      <img src={m.profile.avatar_url} alt={m.profile.pseudo} className="w-full h-full rounded-full object-cover" />
                    ) : (
                      m.profile?.pseudo?.charAt(0).toUpperCase() || '?'
                    )}
                  </div>
                  <div className="flex-1 min-w-0">
                    <p className="font-medium text-sm">{m.profile?.pseudo || 'Anonyme'}</p>
                    {isDanger && <p className="text-[10px] text-destructive font-semibold">BAC critique: {bac.toFixed(2)} g/L</p>}
                    {isWarning && <p className="text-[10px] text-yellow-600 font-semibold">Attention: {bac.toFixed(2)} g/L</p>}
                  </div>
                  {isDanger && (
                    <AlertTriangle className="w-4 h-4 text-destructive animate-pulse shrink-0" />
                  )}
                  {isWarning && (
                    <AlertTriangle className="w-4 h-4 text-yellow-600 shrink-0" />
                  )}
                  {currentParty.created_by === m.user_id && (
                    <span className="text-[10px] bg-primary/20 text-primary px-2 py-0.5 rounded-full shrink-0">Admin</span>
                  )}
                </motion.div>
              );
            })}
          </div>

          {/* Puke Events Counter */}
          {pukeEvents.length > 0 && (
            <motion.div
              initial={{ opacity: 0, y: 10 }}
              animate={{ opacity: 1, y: 0 }}
              className="glass-card p-4 rounded-2xl border border-destructive/30 bg-destructive/5 space-y-3">
              <div className="flex items-center gap-3">
                <span className="text-3xl">🤢</span>
                <div>
                  <p className="text-xs text-muted-foreground uppercase font-semibold">Incidents 🤮</p>
                  <p className="text-xl font-bold text-destructive">{pukeEvents.length}</p>
                </div>
              </div>
              {pukeEvents.slice(0, 3).map(event => {
                const member = members.find(m => m.user_id === event.user_id);
                return (
                  <p key={event.id} className="text-xs text-muted-foreground">
                    🤢 {member?.profile?.pseudo || 'Quelqu\'un'} à {new Date(event.created_at).toLocaleTimeString('fr-FR', { hour: '2-digit', minute: '2-digit' })}
                  </p>
                );
              })}
            </motion.div>
          )}

          {/* Shop Events Counter */}
          {shopEvents.length > 0 && (
            <motion.div
              initial={{ opacity: 0, y: 10 }}
              animate={{ opacity: 1, y: 0 }}
              className="relative overflow-hidden rounded-2xl p-4 space-y-3"
              style={{
                background: 'linear-gradient(135deg, rgba(236, 72, 153, 0.1) 0%, rgba(249, 115, 22, 0.05) 50%, rgba(251, 191, 36, 0.1) 100%)',
                border: '1px solid rgba(236, 72, 153, 0.3)',
              }}>
              <motion.div
                className="absolute inset-0 opacity-20"
                animate={{
                  background: [
                    'radial-gradient(circle at 0% 0%, rgba(255,255,255,0.5) 0%, transparent 50%)',
                    'radial-gradient(circle at 100% 100%, rgba(255,255,255,0.5) 0%, transparent 50%)',
                    'radial-gradient(circle at 0% 0%, rgba(255,255,255,0.5) 0%, transparent 50%)',
                  ]
                }}
                transition={{ duration: 4, repeat: Infinity }}
              />
              <div className="relative flex items-center gap-3">
                <motion.span
                  className="text-3xl"
                  animate={{ scale: [1, 1.2, 1] }}
                  transition={{ duration: 0.8, repeat: Infinity }}
                >
                  💋
                </motion.span>
                <div>
                  <p className="text-xs text-muted-foreground uppercase font-semibold bg-gradient-to-r from-pink-500 to-orange-500 bg-clip-text text-transparent">
                    Smooch Moments ✨
                  </p>
                  <p className="text-xl font-bold bg-gradient-to-r from-pink-500 to-orange-500 bg-clip-text text-transparent">{shopEvents.length}</p>
                </div>
              </div>
              {shopEvents.slice(0, 3).map(event => {
                const member = members.find(m => m.user_id === event.user_id);
                return (
                  <p key={event.id} className="text-xs text-muted-foreground">
                    💋 {member?.profile?.pseudo || 'Quelqu\'un'} à {new Date(event.created_at).toLocaleTimeString('fr-FR', { hour: '2-digit', minute: '2-digit' })}
                  </p>
                );
              })}
            </motion.div>
          )}

          {/* Invite friends */}
          {friends.length > 0 && (
            <div className="space-y-2">
              <p className="text-xs uppercase tracking-widest text-muted-foreground">Inviter des amis</p>
              {friends
                .filter(f => !members.some(m => m.user_id === f.user_id))
                .map(friend => (
                  <div
                    key={friend.user_id}
                    className="w-full glass-card p-3 flex items-center gap-3 hover:bg-accent/5 transition-colors text-left cursor-pointer"
                    onClick={() => (setSelectedProfile(friend), setIsProfileModalOpen(true))}>
                    <div className="w-8 h-8 rounded-full flex items-center justify-center text-sm font-bold shrink-0 bg-accent/20">
                      {friend.avatar_url ? (
                        <img src={friend.avatar_url} alt={friend.pseudo} className="w-full h-full rounded-full object-cover" />
                      ) : (
                        friend.pseudo?.charAt(0).toUpperCase() || '?'
                      )}
                    </div>
                    <div className="flex-1 min-w-0">
                      <p className="font-medium text-sm">{friend.pseudo}</p>
                    </div>
                    <div className="bg-accent/20 text-accent px-3 py-1 rounded-full text-xs font-semibold shrink-0">
                      <MessageCircle className="w-3 h-3 inline mr-1" />
                      Inviter
                    </div>
                  </div>
                ))}
            </div>
          )}
        </div>
      )}

      {/* My parties */}
      {parties.length > 0 && (
        <div className="space-y-3">
          <p className="text-xs uppercase tracking-widest text-muted-foreground">Mes soirées</p>
          {parties.map(p => (
            <motion.button key={p.id} whileTap={{ scale: 0.97 }} onClick={() => onSelect(p)}
              className={`w-full glass-card p-4 flex items-center justify-between text-left ${currentParty?.id === p.id ? 'border-primary/50 neon-glow-violet' : ''}`}>
              <div>
                <p className="font-medium text-sm">{p.name}</p>
                <p className="text-xs text-muted-foreground font-mono">#{p.code}</p>
              </div>
              <Users className="w-4 h-4 text-muted-foreground" />
            </motion.button>
          ))}
        </div>
      )}

      {/* Member Profile Modal */}
      <AnimatePresence>
        {selectedMember && (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            onClick={() => setSelectedMember(null)}
            className="fixed inset-0 z-50 bg-black/60 backdrop-blur-sm flex items-end"
          >
            <motion.div
              initial={{ y: 100, opacity: 0 }}
              animate={{ y: 0, opacity: 1 }}
              exit={{ y: 100, opacity: 0 }}
              transition={{ type: "spring", damping: 30 }}
              onClick={(e) => e.stopPropagation()}
              className="w-full bg-gradient-to-b from-background via-background to-background/95 rounded-t-[32px] overflow-hidden max-h-[90vh] overflow-y-auto pb-24"
            >
              {/* Gradient Header */}
              <div className="relative h-32 bg-gradient-to-r from-primary/40 via-accent/30 to-primary/40 rounded-b-3xl">
                <motion.button
                  whileTap={{ scale: 0.9 }}
                  onClick={() => setSelectedMember(null)}
                  className="absolute top-4 right-4 w-10 h-10 rounded-full bg-black/40 backdrop-blur flex items-center justify-center text-white hover:bg-black/60 transition-colors z-10"
                >
                  <X className="w-5 h-5" />
                </motion.button>
              </div>

              {/* Profile Content */}
              <div className="px-6 -mt-16 pb-6">
                {/* Avatar */}
                <div className="flex justify-center mb-6">
                  <div className="relative w-28 h-28 rounded-full bg-gradient-to-br from-primary via-accent to-primary p-1 shadow-2xl">
                    <div className="w-full h-full rounded-full bg-background overflow-hidden flex items-center justify-center">
                      {selectedMember.profile?.avatar_url ? (
                        <img src={selectedMember.profile.avatar_url} alt={selectedMember.profile?.pseudo} className="w-full h-full object-cover" />
                      ) : (
                        <span className="text-4xl font-bold text-primary">{selectedMember.profile?.pseudo?.charAt(0).toUpperCase() || '?'}</span>
                      )}
                    </div>
                  </div>
                </div>

                {/* Name and Bio */}
                <div className="text-center mb-6 space-y-2">
                  <h2 className="text-2xl font-bold bg-gradient-to-r from-primary to-accent bg-clip-text text-transparent">{selectedMember.profile?.pseudo}</h2>
                  {selectedMember.profile?.bio && (
                    <p className="text-sm text-muted-foreground italic px-2">"{selectedMember.profile.bio}"</p>
                  )}
                </div>

                {/* Stats Grid */}
                <div className="grid grid-cols-3 gap-3 mb-6">
                  <div className="glass-card p-4 text-center rounded-2xl border border-primary/20">
                    <p className="text-[10px] text-muted-foreground uppercase font-semibold mb-1">Poids</p>
                    <p className="text-lg font-bold text-primary">{selectedMember.profile?.weight}</p>
                    <p className="text-[10px] text-muted-foreground">kg</p>
                  </div>
                  <div className="glass-card p-4 text-center rounded-2xl border border-accent/20">
                    <p className="text-[10px] text-muted-foreground uppercase font-semibold mb-1">Âge</p>
                    <p className="text-lg font-bold text-accent">{selectedMember.profile?.age}</p>
                    <p className="text-[10px] text-muted-foreground">ans</p>
                  </div>
                  <div className="glass-card p-4 text-center rounded-2xl border border-primary/20">
                    <p className="text-[10px] text-muted-foreground uppercase font-semibold mb-1">Taille</p>
                    <p className="text-lg font-bold text-primary">{selectedMember.profile?.height}</p>
                    <p className="text-[10px] text-muted-foreground">cm</p>
                  </div>
                </div>

                {/* Contact Section */}
                <div className="space-y-3 mb-6">
                  {selectedMember.profile?.phone && (
                    <a href={`tel:${selectedMember.profile.phone}`}
                      className="w-full glass-card p-4 flex items-center gap-3 hover:bg-accent/20 transition-colors rounded-2xl border border-accent/30 group">
                      <div className="w-10 h-10 rounded-full bg-accent/20 flex items-center justify-center group-hover:bg-accent/30 transition-colors">
                        <Phone className="w-5 h-5 text-accent" />
                      </div>
                      <div className="flex-1">
                        <p className="text-[10px] text-muted-foreground uppercase">Téléphone</p>
                        <p className="font-medium">{selectedMember.profile.phone}</p>
                      </div>
                      <span className="text-accent group-hover:scale-110 transition-transform">📞</span>
                    </a>
                  )}
                </div>

                {/* Action Buttons */}
                <div className="space-y-2">
                  {selectedMember.user_id !== currentUserId && (
                    <motion.button
                      whileTap={{ scale: 0.95 }}
                      onClick={() => {
                        toast.success(`Demande d'ami envoyée à ${selectedMember.profile?.pseudo} ! 👋`);
                        setSelectedMember(null);
                      }}
                      className="w-full glass-button bg-gradient-to-r from-primary/30 to-accent/30 hover:from-primary/40 hover:to-accent/40 py-3 font-semibold flex items-center justify-center gap-2 rounded-2xl transition-all border border-primary/30"
                    >
                      <UserPlus className="w-5 h-5" />
                      Ajouter en ami
                    </motion.button>
                  )}
                  {currentParty && selectedMember.user_id !== currentUserId && (
                    <motion.button
                      whileTap={{ scale: 0.95 }}
                      onClick={async () => {
                        try {
                          await onInviteMember(currentParty.id, selectedMember.user_id);
                          toast.success(`Invitation envoyée à ${selectedMember.profile?.pseudo} ! 📬`);
                          setSelectedMember(null);
                        } catch (e: any) {
                          toast.error(e.message);
                        }
                      }}
                      className="w-full glass-button bg-gradient-to-r from-accent/30 to-primary/30 hover:from-accent/40 hover:to-primary/40 py-3 font-semibold flex items-center justify-center gap-2 rounded-2xl transition-all border border-accent/30"
                    >
                      <MessageCircle className="w-5 h-5" />
                      Inviter à la soirée
                    </motion.button>
                  )}
                </div>
              </div>
            </motion.div>
          </motion.div>
        )}
      </AnimatePresence>

      <UserProfileModal
        profile={selectedProfile}
        isOpen={isProfileModalOpen}
        onClose={() => setIsProfileModalOpen(false)}
        isFriend={selectedProfile ? friends.some(f => f.user_id === selectedProfile.user_id) : false}
        isPartyMember={selectedProfile ? members.some(m => m.user_id === selectedProfile.user_id) : false}
        currentUserId={currentUserId}
        onAddFriend={() => {
          // TODO: Implement add friend functionality
        }}
        onInviteToParty={currentParty ? () => {
          if (selectedProfile) {
            onInviteMember(currentParty.id, selectedProfile.user_id);
            toast.success(`Invitation envoyée à ${selectedProfile.pseudo} ! 📬`);
          }
        } : undefined}
      />
    </div>
  );
}

