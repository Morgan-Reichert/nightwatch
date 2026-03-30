import { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { UserPlus, Check, X, Search, Send, Share2, MessageCircle, Phone, Users, UserCheck } from 'lucide-react';
import { Friendship, Profile, Party, useContactSuggestions } from '@/hooks/useSupabase';
import { toast } from 'sonner';
import { playSfx } from '@/lib/sound';
import UserProfileModal from './UserProfileModal';

interface FriendWithProfile extends Friendship {
  profile?: Profile;
}

interface Props {
  friends: FriendWithProfile[];
  requests: FriendWithProfile[];
  parties: Party[];
  currentUserId?: string;
  currentMembers?: Array<{ user_id: string }>;
  onSendRequest: (pseudo: string) => Promise<void>;
  onAccept: (id: string) => Promise<void>;
  onReject: (id: string) => Promise<void>;
}

export default function FriendsPanel({ friends, requests, parties, currentUserId, currentMembers = [], onSendRequest, onAccept, onReject }: Props) {
  const [searchPseudo, setSearchPseudo] = useState('');
  const [sending, setSending] = useState(false);
  const [showAddFriend, setShowAddFriend] = useState(false);
  const [selectedFriend, setSelectedFriend] = useState<FriendWithProfile | null>(null);
  const [invitingFriend, setInvitingFriend] = useState<FriendWithProfile | null>(null);
  const [inviteCode, setInviteCode] = useState('');
  const [showRejectSplash, setShowRejectSplash] = useState(false);
  const [selectedProfile, setSelectedProfile] = useState<Profile | null>(null);
  const [isProfileModalOpen, setIsProfileModalOpen] = useState(false);
  const [activeTab, setActiveTab] = useState<'friends' | 'suggestions'>('friends');

  const {
    contactSuggestions,
    loading: contactsLoading,
    hasPermission,
    checkContactsPermission,
    findContactsOnApp,
    sendFriendRequestToContact
  } = useContactSuggestions();

  useEffect(() => {
    if (!showRejectSplash) return;
    const timer = window.setTimeout(() => setShowRejectSplash(false), 900);
    return () => window.clearTimeout(timer);
  }, [showRejectSplash]);

  const handleSend = async () => {
    if (!searchPseudo.trim()) return;
    setSending(true);
    try {
      await onSendRequest(searchPseudo.trim());
      toast.success(`Demande envoyée à ${searchPseudo} !`);
      setSearchPseudo('');
      setShowAddFriend(false);
    } catch (err: any) {
      toast.error(err.message);
    }
    setSending(false);
  };

  const handleAccept = async (request: FriendWithProfile) => {
    try {
      await onAccept(request.id);
      playSfx('success');
      toast.success('Ami ajouté !');
    } catch (e: any) {
      toast.error(e.message);
    }
  };

  const handleReject = async (request: FriendWithProfile) => {
    try {
      await onReject(request.id);
      setShowRejectSplash(true);
      playSfx('error');
      toast.success('Demande d\'ami refusée');
    } catch (e: any) {
      toast.error(e.message);
    }
  };

  return (
    <div className="space-y-6">
      {/* Top bar with add friend button */}
      <div className="flex justify-end">
        <motion.button
          whileTap={{ scale: 0.9 }}
          onClick={() => setShowAddFriend(!showAddFriend)}
          className="w-10 h-10 rounded-full bg-primary/20 flex items-center justify-center"
        >
          <UserPlus className="w-5 h-5 text-primary" />
        </motion.button>
      </div>

      {/* Add friend search bar */}
      <AnimatePresence>
        {showAddFriend && (
          <motion.div
            initial={{ opacity: 0, height: 0 }}
            animate={{ opacity: 1, height: 'auto' }}
            exit={{ opacity: 0, height: 0 }}
            className="overflow-hidden"
          >
            <div className="glass-card p-4 space-y-3">
              <div className="flex gap-2">
                <input
                  type="text"
                  placeholder="Nom d'utilisateur..."
                  value={searchPseudo}
                  onChange={(e) => setSearchPseudo(e.target.value)}
                  onKeyPress={(e) => e.key === 'Enter' && handleSend()}
                  className="flex-1 glass-input px-3 py-2 text-sm"
                />
                <motion.button
                  whileTap={{ scale: 0.9 }}
                  onClick={handleSend}
                  disabled={sending || !searchPseudo.trim()}
                  className="glass-button px-4 py-2 disabled:opacity-50"
                >
                  {sending ? '...' : <Send className="w-4 h-4" />}
                </motion.button>
              </div>
            </div>
          </motion.div>
        )}
      </AnimatePresence>

      {/* Navigation bar with sections and friend requests */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-6">
          <button onClick={() => setActiveTab('friends')} className={`text-sm font-semibold pb-1 transition-colors ${activeTab === 'friends' ? 'text-primary border-b-2 border-primary' : 'text-muted-foreground hover:text-foreground'}`}>
            Mes amis ({friends.length})
          </button>
          <button onClick={() => setActiveTab('suggestions')} className={`text-sm font-semibold pb-1 transition-colors ${activeTab === 'suggestions' ? 'text-primary border-b-2 border-primary' : 'text-muted-foreground hover:text-foreground'}`}>
            Suggestions ({contactSuggestions.length})
          </button>
        </div>

        {/* Friend requests indicator */}
        {requests.length > 0 && (
          <motion.button
            whileTap={{ scale: 0.9 }}
            onClick={() => setSelectedFriend(requests[0])}
            className="relative w-10 h-10 rounded-full bg-destructive/20 flex items-center justify-center"
          >
            <UserCheck className="w-5 h-5 text-destructive" />
            <span className="absolute -top-1 -right-1 w-5 h-5 bg-destructive rounded-full text-[10px] flex items-center justify-center font-bold text-destructive-foreground">
              {requests.length}
            </span>
          </motion.button>
        )}
      </div>

      {/* Friend requests modal */}
      <AnimatePresence>
        {selectedFriend && (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            onClick={() => setSelectedFriend(null)}
            className="fixed inset-0 z-[60] bg-black/60 backdrop-blur-sm flex items-center justify-center p-4"
          >
            <motion.div
              initial={{ scale: 0.9, opacity: 0 }}
              animate={{ scale: 1, opacity: 1 }}
              exit={{ scale: 0.9, opacity: 0 }}
              onClick={e => e.stopPropagation()}
              className="w-full max-w-sm bg-background rounded-3xl p-6 space-y-4"
            >
              <div className="text-center">
                <div className="w-16 h-16 rounded-full bg-primary/20 flex items-center justify-center mx-auto mb-3">
                  {selectedFriend.profile?.avatar_url ? (
                    <img src={selectedFriend.profile.avatar_url} alt={selectedFriend.profile.pseudo} className="w-full h-full object-cover rounded-full" />
                  ) : (
                    <span className="text-2xl font-bold text-primary">{selectedFriend.profile?.pseudo?.charAt(0).toUpperCase() || '?'}</span>
                  )}
                </div>
                <h3 className="text-lg font-bold">{selectedFriend.profile?.pseudo || 'Inconnu'}</h3>
                <p className="text-sm text-muted-foreground">veut être ton ami</p>
              </div>

              <div className="flex gap-3">
                <motion.button
                  whileTap={{ scale: 0.95 }}
                  onClick={() => { handleAccept(selectedFriend); setSelectedFriend(null); }}
                  className="flex-1 glass-button bg-safe/20 text-safe py-3 font-semibold flex items-center justify-center gap-2"
                >
                  <Check className="w-4 h-4" />
                  Accepter
                </motion.button>
                <motion.button
                  whileTap={{ scale: 0.95 }}
                  onClick={() => { handleReject(selectedFriend); setSelectedFriend(null); }}
                  className="flex-1 glass-button bg-destructive/20 text-destructive py-3 font-semibold flex items-center justify-center gap-2"
                >
                  <X className="w-4 h-4" />
                  Refuser
                </motion.button>
              </div>
            </motion.div>
          </motion.div>
        )}
      </AnimatePresence>

      {/* My Friends section */}
      {activeTab === 'friends' && <div className="space-y-3">
        {friends.length === 0 ? (
          <div className="glass-card p-6 text-center">
            <Users className="w-8 h-8 mx-auto mb-2 text-muted-foreground" />
            <p className="text-sm text-muted-foreground">
              Aucun ami pour le moment
            </p>
            <p className="text-xs text-muted-foreground mt-1">
              Ajoute des amis pour commencer !
            </p>
          </div>
        ) : (
          <div className="space-y-2">
            {friends.map(friend => (
              <motion.div
                key={friend.id}
                initial={{ opacity: 0, y: 10 }}
                animate={{ opacity: 1, y: 0 }}
                className="glass-card p-4 flex items-center justify-between"
              >
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 rounded-full bg-primary/20 flex items-center justify-center">
                    {friend.profile?.avatar_url ? (
                      <img src={friend.profile.avatar_url} alt={friend.profile.pseudo} className="w-full h-full object-cover rounded-full" />
                    ) : (
                      <span className="text-sm font-bold text-primary">{friend.profile?.pseudo?.charAt(0).toUpperCase() || '?'}</span>
                    )}
                  </div>
                  <div>
                    <p className="font-medium text-sm">{friend.profile?.pseudo || 'Inconnu'}</p>
                    <p className="text-xs text-muted-foreground">Ami depuis {new Date(friend.created_at).toLocaleDateString('fr-FR')}</p>
                  </div>
                </div>
                <div className="flex gap-2">
                  <motion.button
                    whileTap={{ scale: 0.9 }}
                    onClick={() => {
                      setSelectedProfile(friend.profile || null);
                      setIsProfileModalOpen(true);
                    }}
                    className="glass-button px-3 py-2 text-xs"
                  >
                    Voir
                  </motion.button>
                  {currentMembers.some(m => m.user_id === friend.profile?.user_id) && (
                    <motion.button
                      whileTap={{ scale: 0.9 }}
                      onClick={() => setInvitingFriend(friend)}
                      className="glass-button px-3 py-2 text-xs flex items-center gap-1"
                    >
                      <MessageCircle className="w-3 h-3" />
                      Inviter
                    </motion.button>
                  )}
                </div>
              </motion.div>
            ))}
          </div>
        )}
      </div>}

      {/* Contact Suggestions section */}
      {activeTab === 'suggestions' && <div className="space-y-3">
        <div className="flex items-center justify-between mb-3">
          {hasPermission === null && (
            <motion.button
              whileTap={{ scale: 0.95 }}
              onClick={async () => {
                const granted = await checkContactsPermission();
                if (granted) {
                  await findContactsOnApp();
                } else {
                  toast.error(
                    window.location.protocol !== 'https:' && window.location.hostname !== 'localhost'
                      ? 'L\'API Contacts nécessite HTTPS. Testez en production.'
                      : 'Permission refusée ou navigateur non supporté.'
                  );
                }
              }}
              className="text-xs glass-button px-3 py-1.5 flex items-center gap-1.5"
            >
              <Phone className="w-3 h-3" />
              Scanner
            </motion.button>
          )}
          {hasPermission === true && contactSuggestions.length === 0 && !contactsLoading && (
            <motion.button
              whileTap={{ scale: 0.95 }}
              onClick={findContactsOnApp}
              disabled={contactsLoading}
              className="text-xs glass-button px-3 py-1.5 flex items-center gap-1.5"
            >
              <Search className="w-3 h-3" />
              {contactsLoading ? '...' : 'Actualiser'}
            </motion.button>
          )}
        </div>

        {contactsLoading && (
          <div className="flex items-center justify-center py-8">
            <div className="w-6 h-6 border-2 border-primary border-t-transparent rounded-full animate-spin" />
          </div>
        )}

        {hasPermission === false && (
          <div className="glass-card p-4 text-center">
            <Phone className="w-8 h-8 mx-auto mb-2 text-muted-foreground" />
            <p className="text-sm text-muted-foreground mb-2">
              Accès aux contacts non disponible
            </p>
            <p className="text-xs text-muted-foreground mb-3">
              {window.location.protocol !== 'https:' && window.location.hostname !== 'localhost'
                ? 'L\'API Contacts nécessite HTTPS. Fonctionne uniquement en production.'
                : 'Votre navigateur ne supporte pas l\'accès aux contacts ou la permission a été refusée.'
              }
            </p>
            {window.location.protocol === 'https:' && (
              <motion.button
                whileTap={{ scale: 0.95 }}
                onClick={async () => {
                  const granted = await checkContactsPermission();
                  if (granted) {
                    await findContactsOnApp();
                  } else {
                    toast.error('Permission refusée. Vérifiez les paramètres de votre navigateur.');
                  }
                }}
                className="mt-3 text-xs glass-button px-4 py-2"
              >
                Réessayer
              </motion.button>
            )}
          </div>
        )}

        {contactSuggestions.length > 0 && (
          <div className="space-y-2">
            {contactSuggestions.map(suggestion => (
              <motion.div
                key={suggestion.user_id}
                initial={{ opacity: 0, y: 10 }}
                animate={{ opacity: 1, y: 0 }}
                className="glass-card p-4 flex items-center justify-between"
              >
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 rounded-full bg-primary/20 flex items-center justify-center">
                    {suggestion.avatar_url ? (
                      <img src={suggestion.avatar_url} alt={suggestion.pseudo} className="w-full h-full object-cover rounded-full" />
                    ) : (
                      <span className="text-sm font-bold text-primary">{suggestion.pseudo?.charAt(0).toUpperCase() || '?'}</span>
                    )}
                  </div>
                  <div>
                    <p className="font-medium text-sm">{suggestion.pseudo}</p>
                    <p className="text-xs text-muted-foreground">Dans vos contacts</p>
                  </div>
                </div>
                <motion.button
                  whileTap={{ scale: 0.9 }}
                  onClick={async () => {
                    try {
                      await sendFriendRequestToContact(suggestion.user_id);
                      playSfx('success');
                      toast.success(`Demande envoyée à ${suggestion.pseudo} !`);
                    } catch (err: any) {
                      toast.error(err.message);
                    }
                  }}
                  className="glass-button px-3 py-2 text-xs flex items-center gap-1.5"
                >
                  <UserPlus className="w-3 h-3" />
                  Ajouter
                </motion.button>
              </motion.div>
            ))}
          </div>
        )}

        {hasPermission === true && contactSuggestions.length === 0 && !contactsLoading && (
          <div className="glass-card p-6 text-center">
            <UserPlus className="w-8 h-8 mx-auto mb-2 text-muted-foreground" />
            <p className="text-sm text-muted-foreground">
              Aucun contact trouvé sur l'application
            </p>
            <p className="text-xs text-muted-foreground mt-1">
              Invitez vos amis à rejoindre Social Glow Meter !
            </p>
          </div>
        )}
      </div>}

      {/* Party invitation modal */}
      <AnimatePresence>
        {invitingFriend && (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            onClick={() => setInvitingFriend(null)}
            className="fixed inset-0 z-[60] bg-black/60 backdrop-blur-sm flex items-center justify-center p-4"
          >
            <motion.div
              initial={{ scale: 0.9, opacity: 0 }}
              animate={{ scale: 1, opacity: 1 }}
              exit={{ scale: 0.9, opacity: 0 }}
              onClick={e => e.stopPropagation()}
              className="w-full max-w-sm bg-background rounded-3xl p-6 space-y-4"
            >
              <div className="text-center">
                <h3 className="text-lg font-bold mb-2">Inviter {invitingFriend.profile?.pseudo}</h3>
                <p className="text-sm text-muted-foreground mb-4">
                  Choisis une soirée à laquelle l'inviter
                </p>
              </div>

              <div className="space-y-2 max-h-48 overflow-y-auto">
                {parties.map(party => (
                  <motion.button
                    key={party.id}
                    whileTap={{ scale: 0.95 }}
                    onClick={() => {
                      setInviteCode(party.code);
                      setInvitingFriend(null);
                      toast.success(`${invitingFriend.profile?.pseudo} invité à ${party.name} !`);
                    }}
                    className="w-full glass-card p-3 text-left"
                  >
                    <p className="font-medium text-sm">{party.name}</p>
                    <p className="text-xs text-muted-foreground">Code: {party.code}</p>
                  </motion.button>
                ))}
              </div>

              {parties.length === 0 && (
                <p className="text-sm text-muted-foreground text-center">
                  Aucune soirée active
                </p>
              )}
            </motion.div>
          </motion.div>
        )}
      </AnimatePresence>

      {/* Profile modal */}
      <UserProfileModal
        profile={selectedProfile}
        isOpen={isProfileModalOpen}
        onClose={() => setIsProfileModalOpen(false)}
        currentUserId={currentUserId}
        isFriend={true}
      />
    </div>
  );
}
