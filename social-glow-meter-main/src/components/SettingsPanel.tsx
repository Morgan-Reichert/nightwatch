import { useState } from 'react';
import { motion } from 'framer-motion';
import { Phone, User, Weight, Ruler, Calendar, Lock, LogOut, Save, Upload, MessageCircle, Plus, Trash2, X, MapPin, Briefcase, Music, GraduationCap } from 'lucide-react';
import { Profile, CustomCard } from '@/hooks/useSupabase';
import { useAuth } from '@/contexts/AuthContext';
import { supabase } from '@/integrations/supabase/client';
import { toast } from 'sonner';
import BadgesSection from '@/components/BadgesSection';

interface Props {
  profile: Profile;
  onUpdateProfile: (updates: Partial<Profile>) => Promise<void>;
}

const PRESET_CARDS = [
  { title: 'Ma boîte préférée', icon: '🍾' },
  { title: 'Mon lieu le plus insolite', icon: '📍' },
  { title: 'Mon alcool préféré', icon: '🥃' },
  { title: 'Mon soft préféré', icon: '🥤' },
  { title: 'Ma musique préférée', icon: '🎵' },
  { title: 'Mon partenaire de fête', icon: '👯' },
  { title: 'Ma danse signature', icon: '💃' },
  { title: 'Mon vibe de soirée', icon: '✨' },
];

const ZODIAC_SIGNS = ['♈ Bélier', '♉ Taureau', '♊ Gémeaux', '♋ Cancer', '♌ Lion', '♍ Vierge', '♎ Balance', '♏ Scorpion', '♐ Sagittaire', '♑ Capricorne', '♒ Verseau', '♓ Poissons'];
const PARTY_STYLES = ['🕺 Dancefloor addict', '🍻 Bar hopper', '🎤 Karaoké king/queen', '🎲 Jeux & shots', '🌿 Terrasse & chill', '🎉 Organisateur/trice', '🦉 Late night survivor'];

export default function SettingsPanel({ profile, onUpdateProfile }: Props) {
  const { signOut, user } = useAuth();
  const [emergencyContact, setEmergencyContact] = useState(profile.emergency_contact || '');
  const [phoneNumber, setPhoneNumber] = useState(profile.phone || '');
  const [bio, setBio] = useState(profile.bio || '');
  const [pseudo, setPseudo] = useState(profile.pseudo);
  const [weight, setWeight] = useState(String(profile.weight));
  const [height, setHeight] = useState(String(profile.height));
  const [age, setAge] = useState(String(profile.age));
  const [gender, setGender] = useState(profile.gender);
  const [saving, setSaving] = useState(false);
  const [uploadingPhoto, setUploadingPhoto] = useState(false);

  // Réseaux sociaux
  const [snapchat, setSnapchat] = useState(profile.snapchat || '');
  const [instagram, setInstagram] = useState(profile.instagram || '');
  const [tiktok, setTiktok] = useState(profile.tiktok || '');

  // Infos perso
  const [city, setCity] = useState(profile.city || '');
  const [school, setSchool] = useState(profile.school || '');
  const [job, setJob] = useState(profile.job || '');
  const [musicTaste, setMusicTaste] = useState(profile.music_taste || '');
  const [zodiac, setZodiac] = useState(profile.zodiac || '');
  const [partyStyle, setPartyStyle] = useState(profile.party_style || '');

  // Custom cards
  const [customCards, setCustomCards] = useState<CustomCard[]>(profile.custom_cards || []);
  const [showCardForm, setShowCardForm] = useState(false);
  const [newCardValue, setNewCardValue] = useState('');
  const [selectedPreset, setSelectedPreset] = useState<typeof PRESET_CARDS[0] | null>(null);

  // Password change
  const [newPassword, setNewPassword] = useState('');
  const [changingPw, setChangingPw] = useState(false);

  const handlePhotoUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file || !user) return;
    setUploadingPhoto(true);
    try {
      const fileName = `${user.id}_${Date.now()}.jpg`;
      const { error: uploadErr } = await supabase.storage.from('avatars').upload(fileName, file);
      if (uploadErr) throw uploadErr;
      const { data: urlData } = supabase.storage.from('avatars').getPublicUrl(fileName);
      await onUpdateProfile({ avatar_url: urlData.publicUrl });
      toast.success('Photo de profil mise à jour ! 📸');
    } catch (err: any) {
      toast.error(err.message);
    }
    setUploadingPhoto(false);
  };

  const handleSave = async () => {
    const parsedWeight = Number(weight);
    const parsedHeight = Number(height);
    const parsedAge = Number(age);

    if (Number.isNaN(parsedWeight) || parsedWeight <= 0) {
      toast.error('Poids invalide');
      return;
    }
    if (Number.isNaN(parsedHeight) || parsedHeight <= 0) {
      toast.error('Taille invalide');
      return;
    }
    if (Number.isNaN(parsedAge) || parsedAge <= 0) {
      toast.error('Âge invalide');
      return;
    }

    setSaving(true);
    try {
      await onUpdateProfile({
        pseudo,
        weight: parsedWeight,
        height: parsedHeight,
        age: parsedAge,
        gender: gender as 'male' | 'female',
        emergency_contact: emergencyContact || null,
        phone: phoneNumber || null,
        bio: bio || null,
        custom_cards: customCards,
        snapchat: snapchat || null,
        instagram: instagram || null,
        tiktok: tiktok || null,
        city: city || null,
        school: school || null,
        job: job || null,
        music_taste: musicTaste || null,
        zodiac: zodiac || null,
        party_style: partyStyle || null,
      });
      toast.success('Profil mis à jour ✓');
    } catch (err: any) {
      toast.error(err.message);
    }
    setSaving(false);
  };

  const addCustomCard = () => {
    if (!selectedPreset) { toast.error('Choisis une carte d\'abord'); return; }
    if (!newCardValue.trim()) { toast.error('Complète la réponse'); return; }
    if (customCards.length >= 3) { toast.error('Maximum 3 cartes'); return; }
    const newCard: CustomCard = {
      id: `card_${Date.now()}`,
      title: selectedPreset.title,
      value: newCardValue,
      icon: selectedPreset.icon,
    };
    setCustomCards([...customCards, newCard]);
    setNewCardValue('');
    setSelectedPreset(null);
    setShowCardForm(false);
    toast.success('Carte ajoutée !');
  };

  const handlePasswordChange = async () => {
    if (newPassword.length < 6) { toast.error('6 caractères minimum'); return; }
    setChangingPw(true);
    const { error } = await supabase.auth.updateUser({ password: newPassword });
    if (error) toast.error(error.message);
    else { toast.success('Mot de passe modifié ✓'); setNewPassword(''); }
    setChangingPw(false);
  };

  return (
    <div className="space-y-6 pb-6">
      <p className="text-xs uppercase tracking-widest text-muted-foreground">Profil</p>

      {/* Photo de profil */}
      <div className="glass-card p-4 flex flex-col items-center gap-3">
        <div className="w-16 h-16 rounded-full bg-primary/20 flex items-center justify-center text-3xl overflow-hidden">
          {profile.avatar_url
            ? <img src={profile.avatar_url} alt={profile.pseudo} className="w-full h-full object-cover" />
            : profile.pseudo?.charAt(0).toUpperCase() || '?'}
        </div>
        <label className="cursor-pointer glass-button text-sm px-3 py-2 flex items-center gap-2" style={{ pointerEvents: uploadingPhoto ? 'none' : 'auto' }}>
          <Upload className="w-4 h-4" />
          {uploadingPhoto ? 'Upload...' : 'Photo de profil'}
          <input type="file" accept="image/*" onChange={handlePhotoUpload} className="hidden" disabled={uploadingPhoto} />
        </label>
      </div>

      {/* Infos de base */}
      <div className="glass-card p-4 space-y-4">
        <div className="flex items-center gap-3">
          <User className="w-5 h-5 text-primary shrink-0" />
          <div className="flex-1">
            <label className="text-[10px] text-muted-foreground uppercase">Pseudo</label>
            <input value={pseudo} onChange={e => setPseudo(e.target.value)}
              className="w-full bg-transparent text-sm font-medium focus:outline-none" />
          </div>
        </div>
        <div className="flex items-center gap-3">
          <MessageCircle className="w-5 h-5 text-accent shrink-0" />
          <div className="flex-1">
            <label className="text-[10px] text-muted-foreground uppercase">Bio</label>
            <textarea value={bio} onChange={e => setBio(e.target.value)} maxLength={150}
              placeholder="Une petite description..."
              className="w-full bg-transparent text-sm focus:outline-none resize-none h-12" />
            <p className="text-[8px] text-muted-foreground">{bio.length}/150</p>
          </div>
        </div>
        <div className="grid grid-cols-2 gap-3">
          {(['male', 'female'] as const).map(g => (
            <motion.button key={g} whileTap={{ scale: 0.95 }} onClick={() => setGender(g)}
              className={`glass-card p-3 text-center text-sm transition-all ${gender === g ? 'border-primary/50 bg-primary/10' : ''}`}>
              {g === 'male' ? '♂️ Homme' : '♀️ Femme'}
            </motion.button>
          ))}
        </div>
        {[
          { icon: Weight, label: 'Poids (kg)', value: weight, set: setWeight },
          { icon: Ruler, label: 'Taille (cm)', value: height, set: setHeight },
          { icon: Calendar, label: 'Âge', value: age, set: setAge },
        ].map(({ icon: Icon, label, value, set }) => (
          <div key={label} className="flex items-center gap-3">
            <Icon className="w-5 h-5 text-accent shrink-0" />
            <div className="flex-1">
              <label className="text-[10px] text-muted-foreground uppercase">{label}</label>
              <input type="number" value={value} onChange={e => set(e.target.value)}
                className="w-full bg-transparent text-sm font-medium focus:outline-none" />
            </div>
          </div>
        ))}
      </div>

      {/* Réseaux sociaux */}
      <div className="space-y-2">
        <p className="text-xs uppercase tracking-widest text-muted-foreground">Réseaux sociaux</p>
        <div className="glass-card p-4 space-y-4">
          <div className="flex items-center gap-3">
            <span className="text-xl shrink-0">👻</span>
            <div className="flex-1">
              <label className="text-[10px] text-muted-foreground uppercase">Snapchat</label>
              <input value={snapchat} onChange={e => setSnapchat(e.target.value)}
                placeholder="ton.pseudo" autoComplete="off"
                className="w-full bg-transparent text-sm font-medium focus:outline-none" style={{ color: '#FFFC00' }} />
            </div>
          </div>
          <div className="flex items-center gap-3">
            <span className="text-xl shrink-0">📸</span>
            <div className="flex-1">
              <label className="text-[10px] text-muted-foreground uppercase">Instagram</label>
              <input value={instagram} onChange={e => setInstagram(e.target.value)}
                placeholder="@ton.pseudo" autoComplete="off"
                className="w-full bg-transparent text-sm font-medium focus:outline-none" style={{ color: '#E1306C' }} />
            </div>
          </div>
          <div className="flex items-center gap-3">
            <span className="text-xl shrink-0">🎵</span>
            <div className="flex-1">
              <label className="text-[10px] text-muted-foreground uppercase">TikTok</label>
              <input value={tiktok} onChange={e => setTiktok(e.target.value)}
                placeholder="@ton.pseudo" autoComplete="off"
                className="w-full bg-transparent text-sm font-medium focus:outline-none" style={{ color: '#69C9D0' }} />
            </div>
          </div>
        </div>
      </div>

      {/* Infos perso */}
      <div className="space-y-2">
        <p className="text-xs uppercase tracking-widest text-muted-foreground">À propos de toi</p>
        <div className="glass-card p-4 space-y-4">
          <div className="flex items-center gap-3">
            <MapPin className="w-5 h-5 text-accent shrink-0" />
            <div className="flex-1">
              <label className="text-[10px] text-muted-foreground uppercase">Ville</label>
              <input value={city} onChange={e => setCity(e.target.value)} placeholder="Paris, Lyon..."
                className="w-full bg-transparent text-sm font-medium focus:outline-none" />
            </div>
          </div>
          <div className="flex items-center gap-3">
            <GraduationCap className="w-5 h-5 text-accent shrink-0" />
            <div className="flex-1">
              <label className="text-[10px] text-muted-foreground uppercase">École / Université</label>
              <input value={school} onChange={e => setSchool(e.target.value)} placeholder="HEC, Sorbonne..."
                className="w-full bg-transparent text-sm font-medium focus:outline-none" />
            </div>
          </div>
          <div className="flex items-center gap-3">
            <Briefcase className="w-5 h-5 text-accent shrink-0" />
            <div className="flex-1">
              <label className="text-[10px] text-muted-foreground uppercase">Métier / Job</label>
              <input value={job} onChange={e => setJob(e.target.value)} placeholder="Dev, Designer..."
                className="w-full bg-transparent text-sm font-medium focus:outline-none" />
            </div>
          </div>
          <div className="flex items-center gap-3">
            <Music className="w-5 h-5 text-accent shrink-0" />
            <div className="flex-1">
              <label className="text-[10px] text-muted-foreground uppercase">Musique</label>
              <input value={musicTaste} onChange={e => setMusicTaste(e.target.value)} placeholder="Techno, R&B, House..."
                className="w-full bg-transparent text-sm font-medium focus:outline-none" />
            </div>
          </div>
          <div className="flex-1">
            <label className="text-[10px] text-muted-foreground uppercase block mb-2">Signe astrologique</label>
            <div className="grid grid-cols-3 gap-2">
              {ZODIAC_SIGNS.map(sign => (
                <motion.button key={sign} whileTap={{ scale: 0.95 }} onClick={() => setZodiac(zodiac === sign ? '' : sign)}
                  className={`text-xs p-2 rounded-xl text-center transition-all ${zodiac === sign ? 'bg-primary/30 border border-primary/50 text-primary' : 'glass-card text-muted-foreground'}`}>
                  {sign}
                </motion.button>
              ))}
            </div>
          </div>
          <div className="flex-1">
            <label className="text-[10px] text-muted-foreground uppercase block mb-2">Style de soirée</label>
            <div className="space-y-2">
              {PARTY_STYLES.map(style => (
                <motion.button key={style} whileTap={{ scale: 0.95 }} onClick={() => setPartyStyle(partyStyle === style ? '' : style)}
                  className={`w-full text-sm p-2.5 rounded-xl text-left transition-all ${partyStyle === style ? 'bg-primary/30 border border-primary/50 text-primary' : 'glass-card text-muted-foreground'}`}>
                  {style}
                </motion.button>
              ))}
            </div>
          </div>
        </div>
      </div>

      {/* Numéros */}
      <div className="space-y-2">
        <p className="text-xs uppercase tracking-widest text-muted-foreground">Contacts</p>
        <div className="glass-card p-4 space-y-4">
          <div className="flex items-center gap-3">
            <Phone className="w-5 h-5 text-primary shrink-0" />
            <div className="flex-1">
              <label className="text-[10px] text-muted-foreground uppercase">Téléphone personnel</label>
              <input type="tel" value={phoneNumber} onChange={e => setPhoneNumber(e.target.value)}
                placeholder="+33 6 12 34 56 78"
                className="w-full bg-transparent text-sm font-medium focus:outline-none" />
            </div>
          </div>
          <div className="flex items-center gap-3">
            <Phone className="w-5 h-5 text-destructive shrink-0" />
            <div className="flex-1">
              <label className="text-[10px] text-muted-foreground uppercase">Contact d'urgence</label>
              <input type="tel" value={emergencyContact} onChange={e => setEmergencyContact(e.target.value)}
                placeholder="+33 6 12 34 56 78"
                className="w-full bg-transparent text-sm font-medium focus:outline-none" />
            </div>
          </div>
        </div>
      </div>

      {/* Custom Cards */}
      <div className="space-y-2">
        <p className="text-xs uppercase tracking-widest text-muted-foreground">Cartes personnalisées (max 3)</p>
        {customCards.length > 0 && (
          <div className="glass-card p-4 space-y-3">
            {customCards.map((card) => (
              <div key={card.id} className="flex items-center gap-3 p-3 bg-primary/10 rounded-lg border border-primary/20">
                {card.icon && <span className="text-2xl">{card.icon}</span>}
                <div className="flex-1 min-w-0">
                  <p className="text-[10px] text-muted-foreground uppercase font-semibold">{card.title}</p>
                  <p className="text-sm font-medium truncate">{card.value}</p>
                </div>
                <motion.button whileTap={{ scale: 0.9 }} onClick={() => setCustomCards(customCards.filter(c => c.id !== card.id))}
                  className="w-8 h-8 rounded-full bg-destructive/20 flex items-center justify-center shrink-0">
                  <Trash2 className="w-4 h-4 text-destructive" />
                </motion.button>
              </div>
            ))}
          </div>
        )}
        {customCards.length < 3 && !showCardForm && (
          <motion.button whileTap={{ scale: 0.95 }} onClick={() => setShowCardForm(true)}
            className="w-full glass-card p-3 flex items-center justify-center gap-2 text-primary">
            <Plus className="w-4 h-4" /> Ajouter une carte
          </motion.button>
        )}
        {showCardForm && (
          <div className="glass-card p-4 space-y-3">
            <div className="flex items-center justify-between">
              <p className="text-xs font-semibold text-muted-foreground">Choisir une carte</p>
              <motion.button whileTap={{ scale: 0.9 }} onClick={() => { setShowCardForm(false); setSelectedPreset(null); setNewCardValue(''); }}>
                <X className="w-4 h-4 text-muted-foreground" />
              </motion.button>
            </div>
            <div className="grid grid-cols-2 gap-2 max-h-40 overflow-y-auto">
              {PRESET_CARDS.map((preset) => (
                <motion.button key={preset.title} whileTap={{ scale: 0.95 }}
                  onClick={() => { setSelectedPreset(preset); setNewCardValue(''); }}
                  className={`p-2 rounded-lg border text-sm font-medium text-center transition-all ${selectedPreset?.title === preset.title ? 'bg-primary/30 border-primary/50' : 'bg-primary/10 border-primary/20'}`}>
                  <span className="block text-xl mb-1">{preset.icon}</span>
                  <span className="text-xs">{preset.title}</span>
                </motion.button>
              ))}
            </div>
            {selectedPreset && (
              <>
                <input type="text" placeholder="Complète la phrase..." value={newCardValue}
                  onChange={(e) => setNewCardValue(e.target.value)} maxLength={40}
                  className="w-full bg-transparent text-sm border-b border-muted focus:border-primary outline-none pb-1" />
                <p className="text-[10px] text-muted-foreground text-right">{newCardValue.length}/40</p>
              </>
            )}
            <motion.button whileTap={{ scale: 0.95 }} onClick={addCustomCard}
              disabled={!selectedPreset || !newCardValue.trim()}
              className="w-full glass-button bg-primary/20 text-primary text-sm py-2 font-semibold disabled:opacity-50">
              <Plus className="w-4 h-4 inline mr-1" /> Ajouter
            </motion.button>
          </div>
        )}
      </div>

      {/* Badges */}
      <BadgesSection userId={user?.id} />

      <motion.button whileTap={{ scale: 0.95 }} onClick={handleSave} disabled={saving}
        className="w-full glass-button bg-primary/20 text-primary font-semibold flex items-center justify-center gap-2 disabled:opacity-50">
        <Save className="w-4 h-4" />
        {saving ? 'Enregistrement...' : 'Sauvegarder'}
      </motion.button>

      {/* Sécurité */}
      <div className="space-y-2">
        <p className="text-xs uppercase tracking-widest text-muted-foreground">Sécurité</p>
        <div className="glass-card p-4 space-y-3">
          <p className="text-xs text-muted-foreground">{user?.email}</p>
          <div className="flex items-center gap-3">
            <Lock className="w-5 h-5 text-muted-foreground shrink-0" />
            <input type="password" value={newPassword} onChange={e => setNewPassword(e.target.value)}
              placeholder="Nouveau mot de passe"
              className="flex-1 bg-transparent text-sm focus:outline-none" />
          </div>
          <motion.button whileTap={{ scale: 0.95 }} onClick={handlePasswordChange} disabled={changingPw || !newPassword}
            className="w-full glass-button text-sm text-center disabled:opacity-50">
            Changer le mot de passe
          </motion.button>
        </div>
      </div>

      <motion.button whileTap={{ scale: 0.95 }} onClick={signOut}
        className="w-full glass-card p-4 flex items-center justify-center gap-2 text-destructive font-semibold">
        <LogOut className="w-5 h-5" /> Se déconnecter
      </motion.button>
    </div>
  );
}
