import { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { ChevronRight, Settings, Sparkles, X } from 'lucide-react';

interface LaunchTutorialProps {
  onComplete: () => void;
  onNavigateToSettings: () => void;
}

export default function LaunchTutorial({ onComplete, onNavigateToSettings }: LaunchTutorialProps) {
  const [step, setStep] = useState(0);

  const steps = [
    {
      title: '🎉 Bienvenue sur Social Glow Meter!',
      description: 'Découvre comment tracker ta nuit et partager avec tes amis. Allons-y!',
      position: 'center' as const,
    },
    {
      title: '✨ Personnalise Ton Profil',
      description: 'Dans les paramètres, tu peux ajouter jusqu\'à 3 cartes personnalisées pour vraiment montrer qui tu es.',
      highlight: 'settings',
      position: 'top' as const,
    },
    {
      title: '🎨 Choisis Tes Cartes',
      description: 'Ma boîte préférée, mon alcool préféré, mon lieu le plus insolite... C\'est toi qui choisis!',
      highlight: 'cards',
      position: 'center' as const,
    },
    {
      title: '📱 Ton Profil, Ta Personnalité',
      description: 'Ces cartes s\'affichent sur ton profil quand d\'autres te trouvent. Montre-leur qui tu es vraiment!',
      highlight: 'profile',
      position: 'center' as const,
    },
    {
      title: '🚀 C\'est parti!',
      description: 'Tu es prêt à commencer ton aventure. Clique sur "Aller aux paramètres" pour personnaliser ton profil.',
      position: 'center' as const,
    },
  ];

  const currentStep = steps[step];

  return (
    <AnimatePresence>
      <motion.div
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        exit={{ opacity: 0 }}
        className="fixed inset-0 z-50 bg-black/60 backdrop-blur-sm flex items-center justify-center"
        onClick={() => step === steps.length - 1 ? onComplete() : setStep(step + 1)}
      >
        <motion.div
          initial={{ scale: 0.9, opacity: 0 }}
          animate={{ scale: 1, opacity: 1 }}
          exit={{ scale: 0.9, opacity: 0 }}
          onClick={(e) => e.stopPropagation()}
          className="relative w-full max-w-md mx-4"
        >
          {/* Close button */}
          <motion.button
            whileTap={{ scale: 0.9 }}
            onClick={onComplete}
            className="absolute -top-3 -right-3 w-10 h-10 rounded-full bg-black/40 backdrop-blur flex items-center justify-center text-white hover:bg-black/60 transition-colors z-10"
          >
            <X className="w-5 h-5" />
          </motion.button>

          {/* Content */}
          <div className="glass-card p-8 rounded-3xl space-y-6 border border-primary/30">
            {/* Step indicator */}
            <div className="flex gap-2 justify-center">
              {steps.map((_, idx) => (
                <motion.div
                  key={idx}
                  className={`h-2 rounded-full ${
                    idx === step ? 'bg-primary w-8' : 'bg-muted-foreground/30 w-2'
                  }`}
                  animate={{ width: idx === step ? 32 : 8 }}
                />
              ))}
            </div>

            {/* Main content */}
            <div className="text-center space-y-3">
              <h2 className="text-2xl font-bold bg-gradient-to-r from-primary to-accent bg-clip-text text-transparent">
                {currentStep.title}
              </h2>
              <p className="text-sm text-muted-foreground">
                {currentStep.description}
              </p>
            </div>

            {/* Feature preview */}
            {step === 1 && (
              <motion.div
                initial={{ y: 20, opacity: 0 }}
                animate={{ y: 0, opacity: 1 }}
                className="bg-primary/10 border border-primary/20 rounded-2xl p-4 flex items-center gap-3"
              >
                <div className="w-12 h-12 rounded-full bg-primary/20 flex items-center justify-center shrink-0">
                  <Settings className="w-6 h-6 text-primary" />
                </div>
                <div>
                  <p className="text-xs text-muted-foreground uppercase font-semibold">Paramètres</p>
                  <p className="text-sm font-medium">Personnalisation du profil</p>
                </div>
              </motion.div>
            )}

            {step === 2 && (
              <motion.div
                initial={{ y: 20, opacity: 0 }}
                animate={{ y: 0, opacity: 1 }}
                className="space-y-2"
              >
                {['🍾 Ma boîte préférée', '🥃 Mon alcool préféré', '📍 Mon lieu le plus insolite'].map((card, idx) => (
                  <div
                    key={idx}
                    className="bg-primary/10 border border-primary/20 rounded-xl p-3 flex items-center gap-3"
                  >
                    <span className="text-xl">{card.split(' ')[0]}</span>
                    <p className="text-sm font-medium">{card}</p>
                  </div>
                ))}
              </motion.div>
            )}

            {step === 3 && (
              <motion.div
                initial={{ y: 20, opacity: 0 }}
                animate={{ y: 0, opacity: 1 }}
                className="bg-accent/10 border border-accent/20 rounded-2xl p-4 flex items-center gap-3"
              >
                <div className="w-12 h-12 rounded-full bg-accent/20 flex items-center justify-center shrink-0 text-xl">
                  ✨
                </div>
                <div>
                  <p className="text-xs text-muted-foreground uppercase font-semibold">Visible par tous</p>
                  <p className="text-sm font-medium">Quand on clique sur ton avatar</p>
                </div>
              </motion.div>
            )}

            {/* Navigation */}
            <div className="flex gap-3">
              {step > 0 && (
                <motion.button
                  whileTap={{ scale: 0.95 }}
                  onClick={(e) => {
                    e.stopPropagation();
                    setStep(step - 1);
                  }}
                  className="flex-1 glass-button bg-muted/20 text-muted-foreground py-2 rounded-xl"
                >
                  Retour
                </motion.button>
              )}
              
              {step === steps.length - 1 ? (
                <motion.button
                  whileTap={{ scale: 0.95 }}
                  onClick={(e) => {
                    e.stopPropagation();
                    onNavigateToSettings();
                  }}
                  className="flex-1 glass-button bg-primary/30 text-primary py-3 rounded-xl font-semibold flex items-center justify-center gap-2"
                >
                  <Settings className="w-4 h-4" />
                  Aller aux paramètres
                </motion.button>
              ) : (
                <motion.button
                  whileTap={{ scale: 0.95 }}
                  onClick={(e) => {
                    e.stopPropagation();
                    setStep(step + 1);
                  }}
                  className="flex-1 glass-button bg-primary/30 text-primary py-3 rounded-xl font-semibold flex items-center justify-center gap-2"
                >
                  Suivant
                  <ChevronRight className="w-4 h-4" />
                </motion.button>
              )}
            </div>

            {/* Skip button */}
            <motion.button
              whileTap={{ scale: 0.95 }}
              onClick={(e) => {
                e.stopPropagation();
                onComplete();
              }}
              className="w-full text-xs text-muted-foreground hover:text-foreground transition-colors"
            >
              Passer le tutoriel
            </motion.button>
          </div>
        </motion.div>
      </motion.div>
    </AnimatePresence>
  );
}
