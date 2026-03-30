import { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { Plus, Trophy, Users, Home, UserPlus, ShoppingBag, AlertCircle } from 'lucide-react';
import { toast } from 'sonner';
import { playSfx } from '@/lib/sound';
import { useAuth } from '@/contexts/AuthContext';
import { useProfile, useDrinks, useAllMyDrinks, useParties, useStories, useFriendships, usePartyPhotos, useMemberLocations, useMyPartyInvitations, useInviteMember, usePukeEvents, useShopEvents, calculateBAC, getBACStatus } from '@/hooks/useSupabase';
import OnboardingForm from '@/components/OnboardingForm';
import BACGauge from '@/components/BACGauge';
import BACChart from '@/components/BACChart';
import DrinkSelector from '@/components/DrinkSelector';
import EmergencyActions from '@/components/EmergencyActions';
import CameraScanner from '@/components/CameraScanner';
import SocialFeed from '@/components/SocialFeed';
import PartyPanel from '@/components/PartyPanel';
import LeaderboardPanel from '@/components/LeaderboardPanel';
import FriendsPanel from '@/components/FriendsPanel';
import StoryViewer from '@/components/StoryViewer';
import SettingsPanel from '@/components/SettingsPanel';
import LaunchTutorial from '@/components/LaunchTutorial';
import UserProfileModal from '@/components/UserProfileModal';
import Shop from '@/components/Shop';
import { useStreakForUser } from '@/hooks/useSupabase';
import StreakDisplay from '@/components/StreakDisplay';

type Tab = 'home' | 'party' | 'leaderboard' | 'friends' | 'shop' | 'settings';

export default function Index() {
  const { user } = useAuth();
  const { profile, loading: profileLoading, updateProfile, refetch: refetchProfile } = useProfile();
  const { parties, currentParty, setCurrentParty, members, createParty, joinParty, leaveParty, deleteParty, fetchMembers, toggleBacVisibility } = useParties();
  const { drinks: partyDrinks, addDrink, deleteDrink, deleteAllDrinks, refetch: refetchDrinks } = useDrinks(currentParty?.id);
  const { drinks: allMyDrinks, refetch: refetchAllDrinks } = useAllMyDrinks();
  const { pukeEvents, addPukeEvent, deletePukeEvent, deleteAllPukeEvents } = usePukeEvents(currentParty?.id);
  const { shopEvents, addShopEvent, deleteShopEvent, deleteAllShopEvents } = useShopEvents(currentParty?.id);
  const { stories, addStory, refetch: refetchStories } = useStories(currentParty?.id);
  const { friends, requests, sendRequest, acceptRequest, rejectRequest } = useFriendships();
  const { photos, addPhoto } = usePartyPhotos(currentParty?.id);
  const { locations, updateMyLocation } = useMemberLocations(currentParty?.id);
  const { invitations, acceptInvitation, rejectInvitation } = useMyPartyInvitations();
  const { inviteMember } = useInviteMember();

  const [tab, setTab] = useState<Tab>('home');
  const streak = useStreakForUser(user?.id);
  const [drinkOpen, setDrinkOpen] = useState(false);
  const [currentBAC, setCurrentBAC] = useState(0);
  const [hasShownCriticalBAC, setHasShownCriticalBAC] = useState(false);
  const [showMyProfileModal, setShowMyProfileModal] = useState(false);
  const [cameraOpen, setCameraOpen] = useState(false);
  const [storyOpen, setStoryOpen] = useState(false);
  const [savePhotosModal, setSavePhotosModal] = useState<{ action: 'leave' | 'delete'; partyId: string } | null>(null);
  const [savingPhotos, setSavingPhotos] = useState(false);

  const savePartyPhotosToGallery = async () => {
    if (!photos.length) return;
    setSavingPhotos(true);
    try {
      const files = await Promise.all(
        photos.map(async (p, i) => {
          const res = await fetch(p.image_url);
          const blob = await res.blob();
          return new File([blob], `nightwatch_${i + 1}.jpg`, { type: 'image/jpeg' });
        })
      );
      if (navigator.canShare && navigator.canShare({ files })) {
        await navigator.share({ files, title: 'Photos de soirée Nightwatch' });
      } else {
        files.forEach((file, i) => {
          const url = URL.createObjectURL(file);
          const a = document.createElement('a');
          a.href = url;
          a.download = file.name;
          document.body.appendChild(a);
          a.click();
          document.body.removeChild(a);
          URL.revokeObjectURL(url);
        });
      }
    } catch (err: any) {
      if (err?.name !== 'AbortError') toast.error('Erreur lors de la sauvegarde des photos');
    }
    setSavingPhotos(false);
  };

  const handleLeaveParty = async (partyId: string) => {
    if (photos.length > 0) {
      setSavePhotosModal({ action: 'leave', partyId });
    } else {
      await leaveParty(partyId);
    }
  };

  const handleDeleteParty = async (partyId: string) => {
    if (photos.length > 0) {
      setSavePhotosModal({ action: 'delete', partyId });
    } else {
      await deleteParty(partyId);
    }
  };

  const confirmSavePhotosAndProceed = async (save: boolean) => {
    if (!savePhotosModal) return;
    if (save) await savePartyPhotosToGallery();
    if (savePhotosModal.action === 'leave') await leaveParty(savePhotosModal.partyId);
    else await deleteParty(savePhotosModal.partyId);
    setSavePhotosModal(null);
  };

  // Launch tutorial for first-time users
  const [showTutorial, setShowTutorial] = useState(false);

  // Check if this is the first launch
  useEffect(() => {
    const hasSeenTutorial = localStorage.getItem('sgm_tutorial_seen');
    if (!hasSeenTutorial && user && profile) {
      setShowTutorial(true);
    }
  }, [user, profile]);

  const handleTutorialComplete = () => {
    localStorage.setItem('sgm_tutorial_seen', 'true');
    setShowTutorial(false);
  };

  const handleTutorialNavigateToSettings = () => {
    localStorage.setItem('sgm_tutorial_seen', 'true');
    setTab('settings');
    setShowTutorial(false);
  };

  // Transform friends with profiles for PartyPanel
  const friendProfiles = friends
    .filter(f => f.profile)
    .map(f => ({
      ...f.profile!,
      user_id: f.profile!.user_id,
    }));

  // Global BAC from ALL drinks (not per-party)
  useEffect(() => {
    if (!profile) return;

    const update = () => setCurrentBAC(calculateBAC(allMyDrinks, profile.weight, profile.gender as 'male' | 'female'));
    update();
    const interval = setInterval(update, 30000);
    return () => clearInterval(interval);
  }, [allMyDrinks, profile]);

  // Load party members
  useEffect(() => {
    if (currentParty) fetchMembers(currentParty.id);
  }, [currentParty, fetchMembers]);

  // Auto-refresh party drinks every 15 seconds to keep data in sync
  useEffect(() => {
    if (!currentParty) return;
    refetchDrinks();
    const interval = setInterval(() => refetchDrinks(), 15000);
    return () => clearInterval(interval);
  }, [currentParty, refetchDrinks]);

  // Auto-share location when in a party
  useEffect(() => {
    if (!currentParty) return;
    updateMyLocation(currentParty.id);
    const interval = setInterval(() => updateMyLocation(currentParty.id), 60000);
    return () => clearInterval(interval);
  }, [currentParty, updateMyLocation]);

  // Auto-share location more frequently when BAC is critical (> 1.0)
  useEffect(() => {
    if (!currentParty || currentBAC <= 1.0) return;
    
    // Update location every 30 seconds when BAC is critical
    const frequentInterval = setInterval(() => {
      updateMyLocation(currentParty.id);
    }, 30000);
    
    return () => clearInterval(frequentInterval);
  }, [currentParty, currentBAC, updateMyLocation]);

  // Members status tracking (no toasts, just for display)
  useEffect(() => {
    if (!profile || allMyDrinks.length === 0) return;
    const interval = setInterval(() => {
      const alcoholDrinks = allMyDrinks.filter(d => d.abv > 0);
      const waterDrinks = allMyDrinks.filter(d => d.abv === 0);
      if (alcoholDrinks.length > 2 && waterDrinks.length < alcoholDrinks.length / 2) {
        toast(`💧 Hé ${profile.pseudo}, bois un verre d'eau !`, { description: 'Ton futur toi te remerciera.' });
      }
    }, 5 * 60 * 1000);
    return () => clearInterval(interval);
  }, [allMyDrinks, profile]);

  if (profileLoading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="w-8 h-8 border-2 border-primary border-t-transparent rounded-full animate-spin" />
      </div>
    );
  }

  if (!profile) return <OnboardingForm onComplete={refetchProfile} />;

  const handleAddDrink = async (drink: { name: string; volume_ml: number; abv: number; detected_by_ai?: boolean }) => {
    try {
      await addDrink({ ...drink, party_id: currentParty?.id });
      await refetchAllDrinks(); // Ensure drinks are updated immediately
      setCurrentBAC(calculateBAC(allMyDrinks, profile.weight, profile.gender as 'male' | 'female')); // Recalculate BAC immediately
      if (drink.abv === 0) {
        playSfx('drink');
        toast.success(`💧 Bien joué ${profile.pseudo} !`);
      } else {
        playSfx('click');
        toast(`🍻 ${drink.name} ajouté !`);
      }
    } catch (err: any) {
      playSfx('error');
      toast.error(err.message);
    }
  };

  const handleAcceptInvitation = async (invitationId: string, partyId: string) => {
    await acceptInvitation(invitationId, partyId);
    const joinedParty = parties.find(p => p.id === partyId);
    if (joinedParty) {
      setCurrentParty(joinedParty);
    }
  };

  const handleRejectInvitation = async (invitationId: string) => {
    await rejectInvitation(invitationId);
  };

  const tabs = [
    { id: 'home' as Tab, icon: Home, label: 'Accueil' },
    { id: 'party' as Tab, icon: Users, label: 'Soirée' },
    { id: 'leaderboard' as Tab, icon: Trophy, label: 'Top' },
    { id: 'friends' as Tab, icon: UserPlus, label: 'Amis' },
    { id: 'shop' as Tab, icon: ShoppingBag, label: 'Boutique' },
  ];

  return (
    <div className="min-h-[100vh] pb-[5.5rem] mobile:pb-[6.5rem] max-w-[430px] w-full mx-auto" style={{ paddingTop: 'env(safe-area-inset-top)' }}>
      {/* Header */}
      <motion.header initial={{ opacity: 0, y: -20 }} animate={{ opacity: 1, y: 0 }}
        className="p-6 pb-2 flex items-center justify-between">
        <motion.div
          onClick={() => profile && setShowMyProfileModal(true)}
          className="cursor-pointer hover:opacity-80 transition-opacity">
          <p className="text-sm text-muted-foreground">Bonsoir,</p>
          <div className="flex items-center gap-3 mt-0.5">
            <h1 className="text-2xl font-bold tracking-tight">
              <span className="gradient-text">{profile.pseudo}</span>
            </h1>
            <StreakDisplay weeks={streak.weeks} alive={streak.alive} size="sm" showLabel={false} />
          </div>
        </motion.div>
        <div className="flex items-center gap-3">
          {currentParty && (
            <span className="text-xs bg-primary/20 text-primary px-3 py-1 rounded-full font-mono">
              #{currentParty.code}
            </span>
          )}
          {/* Avatar → Réglages */}
          <motion.button whileTap={{ scale: 0.92 }} onClick={() => setTab('settings')}
            className="w-10 h-10 rounded-full overflow-hidden border-2 border-primary/40 shrink-0">
            {profile.avatar_url
              ? <img src={profile.avatar_url} alt={profile.pseudo} className="w-full h-full object-cover" />
              : <div className="w-full h-full bg-primary/20 flex items-center justify-center text-sm font-bold text-primary">
                  {profile.pseudo?.charAt(0).toUpperCase()}
                </div>
            }
          </motion.button>
        </div>
      </motion.header>

      {/* Alert banner for dangerous BAC */}
      {currentBAC > 1.0 && (
        <motion.div
          initial={{ opacity: 0, y: -10 }}
          animate={{ opacity: 1, y: 0 }}
          className="mx-6 mb-4 p-4 bg-destructive/20 border border-destructive/50 rounded-2xl flex items-center gap-3"
        >
          <span className="text-2xl">⚠️</span>
          <div className="flex-1">
            <p className="text-sm font-bold text-destructive">⚠️ Attention - Ébriété sévère</p>
            <p className="text-xs text-destructive/80">
              Tu es actuellement à {currentBAC.toFixed(2)} g/L. C'est dangereux ! Cherche de l'aide si besoin.
            </p>
          </div>
          {currentParty && (
            <span className="text-[10px] bg-destructive/30 text-destructive px-2 py-1 rounded-full whitespace-nowrap">
              📍 Localisation partagée
            </span>
          )}
        </motion.div>
      )}

      {/* Alert banner for other dangerous members in party */}
      {currentParty && (() => {
        const dangerousMembers = members
          .filter(m => m.user_id !== user?.id)
          .map(m => {
            const memberDrinks = partyDrinks.filter(d => d.user_id === m.user_id);
            const bac = m.profile ? calculateBAC(memberDrinks, m.profile.weight, m.profile.gender as 'male' | 'female') : 0;
            return { member: m, bac };
          });

        const criticalMembers = dangerousMembers.filter(({ bac }) => bac > 1.0);
        const warningMembers = dangerousMembers.filter(({ bac }) => bac >= 0.5 && bac <= 1.0);

        return (
          <>
            {criticalMembers.length > 0 && (
              <motion.div
                initial={{ opacity: 0, y: -10 }}
                animate={{ opacity: 1, y: 0 }}
                className="mx-6 mb-4 p-4 bg-destructive/20 border border-destructive/50 rounded-2xl flex items-center gap-3"
              >
                <span className="text-2xl">⚠️</span>
                <div className="flex-1">
                  <p className="text-sm font-bold text-destructive">Attention - État d'ébriété grave</p>
                  <p className="text-xs text-destructive/80">
                    {criticalMembers.map(({ member }) => member.profile?.pseudo).join(', ')} {criticalMembers.length === 1 ? 'est' : 'sont'} en danger. Surveille{criticalMembers.length === 1 ? '-le' : '-les'} de près.
                  </p>
                </div>
              </motion.div>
            )}

            {warningMembers.length > 0 && (
              <motion.div
                initial={{ opacity: 0, y: -10 }}
                animate={{ opacity: 1, y: 0 }}
                className="mx-6 mb-4 p-3 bg-yellow-500/20 border border-yellow-500/50 rounded-2xl flex items-center gap-3"
              >
                <span className="text-xl">⚠️</span>
                <div className="flex-1">
                  <p className="text-sm font-bold text-yellow-700">Attention - Membres ébriés</p>
                  <div className="text-xs text-yellow-700/80 space-y-1">
                    {warningMembers.map(({ member, bac }) => (
                      <p key={member.id}>{member.profile?.pseudo} : {bac.toFixed(2)} g/L</p>
                    ))}
                  </div>
                </div>
              </motion.div>
            )}
          </>
        );
      })()}


      {/* Content */}

      {/* Stories bar */}
      <StoryViewer
        stories={stories}
        onViewingChange={setStoryOpen}
        onAddStory={async (file, caption) => {
          try {
            await addStory(file, caption, currentBAC, currentParty?.id);
            toast.success('Story publiée ! 📸');
          } catch (err: any) {
            toast.error(err.message);
          }
        }}
      />

      {/* Content */}
      <AnimatePresence mode="wait">
        <motion.div key={tab} initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }}
          exit={{ opacity: 0, y: -10 }} transition={{ duration: 0.2 }} className="px-6 space-y-4">
          {tab === 'home' && (
            <>
              <BACGauge bac={currentBAC} />
              <BACChart drinks={allMyDrinks} weight={profile.weight} gender={profile.gender as 'male' | 'female'} />
              <EmergencyActions
                emergencyContact={profile.emergency_contact || ''}
                onQuiche={addPukeEvent}
                onShop={addShopEvent}
              />
              <motion.button whileTap={{ scale: 0.95 }} onClick={() => setDrinkOpen(true)}
                className="w-full glass-card-hover p-4 flex items-center justify-center gap-2 text-primary font-semibold rounded-2xl">
                <Plus className="w-5 h-5" /> Ajouter un verre
              </motion.button>
              <SocialFeed
                drinks={currentParty ? partyDrinks.filter(d => d.user_id === user?.id) : allMyDrinks.filter(d => d.user_id === user?.id)}
                pukeEvents={pukeEvents}
                shopEvents={shopEvents}
                onDeleteDrink={deleteDrink}
                onDeletePukeEvent={deletePukeEvent}
                onDeleteShopEvent={deleteShopEvent}
                onDeleteAllDrinks={async () => { await deleteAllDrinks(false); await refetchAllDrinks(); }}
                onDeleteAllAlcohol={async () => { await deleteAllDrinks(true); await refetchAllDrinks(); }}
                onDeleteAllQuiches={deleteAllPukeEvents}
                onDeleteAllBisous={deleteAllShopEvents}
                onDeleteAll={async () => { await deleteAllDrinks(false); await deleteAllPukeEvents(); await deleteAllShopEvents(); await refetchAllDrinks(); }}
              />
            </>
          )}

          {tab === 'party' && (
            <PartyPanel
              parties={parties}
              currentParty={currentParty}
              members={members}
              friends={friendProfiles}
              photos={photos}
              locations={locations}
              drinks={partyDrinks}
              allMyDrinks={allMyDrinks}
              partyInvitations={invitations}
              pukeEvents={pukeEvents}
              shopEvents={shopEvents}
              currentUserId={user?.id}
              onSelect={setCurrentParty}
              onCreate={async (name) => { await createParty(name); toast.success('Soirée créée !'); }}
              onJoin={async (code) => { await joinParty(code); toast.success('Tu as rejoint la soirée !'); }}
              onLeave={handleLeaveParty}
              onDelete={handleDeleteParty}
              onAddPhoto={addPhoto}
              onUpdateLocation={updateMyLocation}
              onAcceptInvitation={handleAcceptInvitation}
              onRejectInvitation={handleRejectInvitation}
              onInviteMember={inviteMember}
            />
          )}

          {tab === 'leaderboard' && !currentParty && (
            <div className="glass-card p-8 text-center space-y-2">
              <p className="text-3xl">🏆</p>
              <p className="text-sm font-semibold">Pas de soirée active</p>
              <p className="text-xs text-muted-foreground">Rejoins ou crée une soirée pour voir le classement</p>
            </div>
          )}

          {tab === 'leaderboard' && currentParty && (
            <>
              {(() => {
                const myShowBac = members.find(m => m.user_id === user?.id)?.show_bac !== false;
                return (
                  <div className="glass-card p-4 flex items-center justify-between">
                    <div>
                      <p className="text-sm font-semibold">Mon classement d'alcoolémie</p>
                      <p className="text-xs text-muted-foreground">{myShowBac ? 'Visible par les autres' : 'Caché du classement'}</p>
                    </div>
                    <motion.button whileTap={{ scale: 0.9 }} onClick={() => toggleBacVisibility(currentParty.id)}
                      className={`relative w-12 h-6 rounded-full transition-colors duration-300 ${myShowBac ? 'bg-accent' : 'bg-white/20'}`}>
                      <motion.div animate={{ x: myShowBac ? 24 : 2 }} transition={{ type: 'spring', stiffness: 500, damping: 30 }}
                        className="absolute top-1 w-4 h-4 rounded-full bg-white shadow" />
                    </motion.button>
                  </div>
                );
              })()}
              <LeaderboardPanel
                members={members}
                drinks={partyDrinks}
                pukeEvents={pukeEvents}
                shopEvents={shopEvents}
                friends={friendProfiles}
                currentUserId={user?.id}
              />
            </>
          )}

          {tab === 'friends' && (
            <FriendsPanel
              friends={friends}
              requests={requests}
              parties={parties}
              currentUserId={user?.id}
              currentMembers={members}
              onSendRequest={sendRequest}
              onAccept={acceptRequest}
              onReject={rejectRequest}
            />
          )}

          {tab === 'settings' && (
            <SettingsPanel profile={profile} onUpdateProfile={updateProfile} />
          )}

          {tab === 'shop' && (
            <Shop />
          )}
        </motion.div>
      </AnimatePresence>
      <DrinkSelector
        open={drinkOpen}
        onClose={() => setDrinkOpen(false)}
        onSelect={handleAddDrink}
        pseudo={profile.pseudo}
      />

      <CameraScanner onDrinkDetected={handleAddDrink} onOpenChange={setCameraOpen} />

      {/* Tab bar */}
      <nav className="tab-bar" style={{ display: (cameraOpen || storyOpen) ? 'none' : undefined }}>
        <div className="flex justify-around items-center">
          {tabs.map(t => {
            const Icon = t.icon;
            const isActive = tab === t.id;
            return (
              <motion.button key={t.id} whileTap={{ scale: 0.9 }} onClick={() => setTab(t.id)}
                aria-current={isActive ? 'page' : undefined}
                className={`flex flex-col items-center gap-0.5 py-2 px-3 rounded-lg transition-all duration-200 relative ${isActive ? 'active' : ''}`}>
                <Icon className={`w-5 h-5 ${isActive ? 'text-white' : 'text-gray-200/80'}`} />
                <span className={`text-[11px] font-semibold leading-none ${isActive ? 'text-white' : 'text-gray-100/75'}`}>{t.label}</span>
                {t.id === 'friends' && requests.length > 0 && (
                  <span className="absolute -top-1 -right-1 w-4 h-4 bg-destructive rounded-full text-[9px] flex items-center justify-center font-bold text-destructive-foreground">
                    {requests.length}
                  </span>
                )}
                {t.id === 'party' && invitations.length > 0 && (
                  <span className="absolute -top-1 -right-1 w-4 h-4 bg-destructive rounded-full text-[9px] flex items-center justify-center font-bold text-destructive-foreground">
                    {invitations.length}
                  </span>
                )}
              </motion.button>
            );
          })}
        </div>
      </nav>

      {/* Launch Tutorial */}
      <AnimatePresence>
        {showTutorial && (
          <LaunchTutorial
            onComplete={handleTutorialComplete}
            onNavigateToSettings={handleTutorialNavigateToSettings}
          />
        )}
      </AnimatePresence>

      {/* Save photos modal */}
      <AnimatePresence>
        {savePhotosModal && (
          <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }}
            className="fixed inset-0 z-[70] bg-black/70 backdrop-blur-sm flex items-end justify-center p-4"
            style={{ paddingBottom: 'max(1.5rem, env(safe-area-inset-bottom))' }}>
            <motion.div initial={{ y: 60, opacity: 0 }} animate={{ y: 0, opacity: 1 }} exit={{ y: 60, opacity: 0 }}
              className="w-full max-w-sm bg-background rounded-3xl p-6 space-y-4">
              <div className="text-center space-y-2">
                <p className="text-3xl">📸</p>
                <h3 className="text-lg font-bold">
                  {savePhotosModal.action === 'delete' ? 'Supprimer la soirée' : 'Quitter la soirée'}
                </h3>
                <p className="text-sm text-muted-foreground">
                  Il y a <span className="text-primary font-semibold">{photos.length} photo{photos.length > 1 ? 's' : ''}</span> dans cette soirée.
                  Tu veux les enregistrer dans ta galerie avant de {savePhotosModal.action === 'delete' ? 'supprimer' : 'quitter'} ?
                </p>
              </div>
              <div className="space-y-2">
                <motion.button whileTap={{ scale: 0.97 }} disabled={savingPhotos}
                  onClick={() => confirmSavePhotosAndProceed(true)}
                  className="w-full glass-button bg-primary/20 text-primary font-semibold py-3 flex items-center justify-center gap-2">
                  {savingPhotos ? <div className="w-4 h-4 border-2 border-primary border-t-transparent rounded-full animate-spin" /> : '📥'}
                  {savingPhotos ? 'Sauvegarde...' : 'Oui, enregistrer les photos'}
                </motion.button>
                <motion.button whileTap={{ scale: 0.97 }} disabled={savingPhotos}
                  onClick={() => confirmSavePhotosAndProceed(false)}
                  className="w-full glass-button text-muted-foreground py-3">
                  Non, {savePhotosModal.action === 'delete' ? 'supprimer' : 'quitter'} sans sauvegarder
                </motion.button>
                <motion.button whileTap={{ scale: 0.97 }} disabled={savingPhotos}
                  onClick={() => setSavePhotosModal(null)}
                  className="w-full text-sm text-muted-foreground py-2">
                  Annuler
                </motion.button>
              </div>
            </motion.div>
          </motion.div>
        )}
      </AnimatePresence>

      {/* My Profile Modal */}
      <UserProfileModal
        profile={profile}
        isOpen={showMyProfileModal}
        onClose={() => setShowMyProfileModal(false)}
        isFriend={false}
        isPartyMember={currentParty ? members.some(m => m.user_id === user?.id) : false}
        currentUserId={user?.id}
        onAddFriend={() => {}}
        onInviteToParty={() => {}}
      />
    </div>
  );
}
