import { useState } from 'react';
import { motion } from 'framer-motion';
import { useAuth } from '@/contexts/AuthContext';
import { useProfile } from '@/hooks/useSupabase';
import { User, Weight, Ruler, Calendar } from 'lucide-react';
import { toast } from 'sonner';

export default function OnboardingForm({ onComplete }: { onComplete?: () => void }) {
  const { user } = useAuth();
  const { createProfile } = useProfile();
  const [step, setStep] = useState(0);
  const [pseudo, setPseudo] = useState('');
  const [gender, setGender] = useState<'male' | 'female'>('male');
  const [weight, setWeight] = useState('70');
  const [height, setHeight] = useState('175');
  const [age, setAge] = useState('25');
  const [loading, setLoading] = useState(false);

  const handleSubmit = async () => {
    if (!user) return;

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

    setLoading(true);
    try {
      await createProfile({
        pseudo,
        gender,
        weight: parsedWeight,
        height: parsedHeight,
        age: parsedAge,
      });
      toast.success(`Bienvenue ${pseudo} ! 🎉`);
      onComplete?.();
    } catch (err: any) {
      toast.error(err.message || 'Erreur lors de la création du profil');
    }
    setLoading(false);
  };

  const steps = [
    <motion.div key="pseudo" initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} className="space-y-6">
      <div className="text-center space-y-2">
        <div className="w-16 h-16 rounded-full bg-primary/20 flex items-center justify-center mx-auto neon-glow-violet">
          <User className="w-8 h-8 text-primary" />
        </div>
        <h2 className="text-2xl font-bold tracking-tight">Comment on t'appelle ?</h2>
        <p className="text-muted-foreground text-sm">Ton pseudo pour la soirée</p>
      </div>
      <input
        type="text"
        value={pseudo}
        onChange={e => setPseudo(e.target.value)}
        placeholder="Pseudo..."
        className="w-full glass-card px-6 py-4 bg-transparent text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-primary/50 text-center text-lg"
      />
      <motion.button
        whileTap={{ scale: 0.95 }}
        onClick={() => pseudo.trim() && setStep(1)}
        disabled={!pseudo.trim()}
        className="w-full glass-button bg-primary/20 text-primary font-semibold disabled:opacity-30"
      >
        Suivant
      </motion.button>
    </motion.div>,

    <motion.div key="gender" initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} className="space-y-6">
      <div className="text-center space-y-2">
        <h2 className="text-2xl font-bold tracking-tight">Ton profil</h2>
        <p className="text-muted-foreground text-sm">Pour calculer ton taux avec précision</p>
      </div>
      <div className="grid grid-cols-2 gap-4">
        {(['male', 'female'] as const).map(g => (
          <motion.button
            key={g}
            whileTap={{ scale: 0.95 }}
            onClick={() => setGender(g)}
            className={`glass-card p-6 text-center transition-all ${gender === g ? 'border-primary/50 neon-glow-violet' : ''}`}
          >
            <span className="text-3xl">{g === 'male' ? '♂️' : '♀️'}</span>
            <p className="mt-2 font-medium">{g === 'male' ? 'Homme' : 'Femme'}</p>
          </motion.button>
        ))}
      </div>
      <motion.button whileTap={{ scale: 0.95 }} onClick={() => setStep(2)} className="w-full glass-button bg-primary/20 text-primary font-semibold">
        Suivant
      </motion.button>
    </motion.div>,

    <motion.div key="body" initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} className="space-y-6">
      <div className="text-center space-y-2">
        <h2 className="text-2xl font-bold tracking-tight">Tes mesures</h2>
      </div>
      <div className="space-y-4">
        {[
          { icon: Weight, label: 'Poids (kg)', value: weight, set: setWeight },
          { icon: Ruler, label: 'Taille (cm)', value: height, set: setHeight },
          { icon: Calendar, label: 'Âge', value: age, set: setAge },
        ].map(({ icon: Icon, label, value, set }) => (
          <div key={label} className="glass-card p-4 flex items-center gap-4">
            <Icon className="w-5 h-5 text-accent shrink-0" />
            <div className="flex-1">
              <label className="text-xs text-muted-foreground">{label}</label>
              <input type="number" value={value} onChange={e => set(e.target.value)} className="w-full bg-transparent text-lg font-semibold focus:outline-none" />
            </div>
          </div>
        ))}
      </div>
      <motion.button
        whileTap={{ scale: 0.95 }}
        onClick={handleSubmit}
        disabled={loading}
        className="w-full glass-button bg-primary/20 text-primary font-semibold disabled:opacity-50"
      >
        {loading ? 'Création...' : 'C\'est parti 🎉'}
      </motion.button>
    </motion.div>,
  ];

  return (
    <div className="min-h-screen flex flex-col items-center justify-center p-6">
      <motion.div initial={{ opacity: 0, scale: 0.9 }} animate={{ opacity: 1, scale: 1 }} className="w-full max-w-sm">
        <div className="flex gap-2 mb-8 justify-center">
          {[0, 1, 2].map(i => (
            <div key={i} className={`h-1 w-12 rounded-full transition-all ${i <= step ? 'bg-primary' : 'bg-muted'}`} />
          ))}
        </div>
        {steps[step]}
      </motion.div>
    </div>
  );
}
