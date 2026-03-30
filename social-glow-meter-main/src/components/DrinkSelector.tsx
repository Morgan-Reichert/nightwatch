import { motion, AnimatePresence } from 'framer-motion';
import { useState } from 'react';
import { X, Check } from 'lucide-react';

const DRINK_CATEGORIES = [
  {
    label: '🍺 Bières',
    drinks: [
      { name: 'Bière légère (25cl)', volume_ml: 250, abv: 0.04 },
      { name: 'Bière (25cl)',        volume_ml: 250, abv: 0.05 },
      { name: 'Bière (33cl)',        volume_ml: 330, abv: 0.05 },
      { name: 'Bière (50cl)',        volume_ml: 500, abv: 0.05 },
      { name: 'Bière forte (33cl)', volume_ml: 330, abv: 0.08 },
      { name: 'Cidre (25cl)',        volume_ml: 250, abv: 0.045 },
    ],
  },
  {
    label: '🍷 Vins',
    drinks: [
      { name: 'Vin rouge',    volume_ml: 150, abv: 0.13 },
      { name: 'Vin blanc',    volume_ml: 150, abv: 0.12 },
      { name: 'Vin rosé',     volume_ml: 150, abv: 0.12 },
      { name: 'Champagne',    volume_ml: 150, abv: 0.12 },
      { name: 'Prosecco',     volume_ml: 150, abv: 0.11 },
    ],
  },
  {
    label: '🍹 Cocktails',
    drinks: [
      { name: 'Cocktail maison',  volume_ml: 200, abv: 0.10 },
      { name: 'Mojito',           volume_ml: 200, abv: 0.12 },
      { name: 'Gin tonic',        volume_ml: 200, abv: 0.11 },
      { name: 'Spritz',           volume_ml: 200, abv: 0.08 },
      { name: 'Margarita',        volume_ml: 150, abv: 0.20 },
      { name: 'Cuba libre',       volume_ml: 200, abv: 0.10 },
      { name: 'Long Island',      volume_ml: 250, abv: 0.22 },
    ],
  },
  {
    label: '🥃 Spiritueux',
    drinks: [
      { name: 'Shot (4cl)',   volume_ml: 40, abv: 0.40 },
      { name: 'Whisky',       volume_ml: 40, abv: 0.40 },
      { name: 'Vodka',        volume_ml: 40, abv: 0.40 },
      { name: 'Rhum',         volume_ml: 40, abv: 0.40 },
      { name: 'Tequila',      volume_ml: 40, abv: 0.38 },
      { name: 'Gin',          volume_ml: 40, abv: 0.40 },
      { name: 'Pastis (2cl)', volume_ml: 20, abv: 0.45 },
    ],
  },
  {
    label: '💧 Sans alcool',
    drinks: [
      { name: 'Eau',          volume_ml: 250, abv: 0 },
      { name: 'Jus de fruit', volume_ml: 200, abv: 0 },
      { name: 'Soda',         volume_ml: 330, abv: 0 },
    ],
  },
];

const ALL_DRINKS = DRINK_CATEGORIES.flatMap(c => c.drinks);

interface Props {
  open: boolean;
  onClose: () => void;
  onSelect: (drink: { name: string; volume_ml: number; abv: number }) => void;
  pseudo: string;
}

export default function DrinkSelector({ open, onClose, onSelect, pseudo }: Props) {
  const [selectedIdx, setSelectedIdx] = useState<number | null>(null);

  const handleConfirm = () => {
    if (selectedIdx === null) return;
    onSelect(ALL_DRINKS[selectedIdx]);
    setSelectedIdx(null);
    onClose();
  };

  const handleClose = () => {
    setSelectedIdx(null);
    onClose();
  };

  return (
    <AnimatePresence>
      {open && (
        <>
          <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }}
            className="fixed inset-0 bg-black/60 z-40" onClick={handleClose} />

          <motion.div
            initial={{ y: '100%' }} animate={{ y: 0 }} exit={{ y: '100%' }}
            transition={{ type: 'spring', damping: 25, stiffness: 300 }}
            className="fixed bottom-0 left-0 right-0 z-[60] glass-card rounded-b-none rounded-t-3xl flex flex-col"
            style={{ maxHeight: '78vh' }}
          >
            {/* Header fixe */}
            <div className="flex items-center justify-between px-6 pt-5 pb-3 shrink-0">
              <div>
                <h3 className="text-lg font-bold">Qu'est-ce que tu bois ? 🍸</h3>
                <p className="text-xs text-muted-foreground">{pseudo}</p>
              </div>
              <motion.button whileTap={{ scale: 0.9 }} onClick={handleClose}
                className="w-8 h-8 rounded-full bg-muted/30 flex items-center justify-center">
                <X className="w-4 h-4" />
              </motion.button>
            </div>

            {/* Liste scrollable */}
            <div className="overflow-y-auto flex-1 px-6 space-y-5 pb-4">
              {DRINK_CATEGORIES.map(cat => {
                const catOffset = ALL_DRINKS.indexOf(cat.drinks[0]);
                return (
                  <div key={cat.label}>
                    <p className="text-xs font-semibold text-muted-foreground uppercase tracking-wider mb-2">
                      {cat.label}
                    </p>
                    <div className="grid grid-cols-2 gap-2">
                      {cat.drinks.map((drink, i) => {
                        const globalIdx = catOffset + i;
                        const isSelected = selectedIdx === globalIdx;
                        return (
                          <motion.button key={drink.name} whileTap={{ scale: 0.95 }}
                            onClick={() => setSelectedIdx(isSelected ? null : globalIdx)}
                            className={`glass-card p-3 text-left transition-all rounded-xl flex items-center gap-2
                              ${isSelected ? 'border-primary/60 bg-primary/10' : ''}
                              ${drink.abv === 0 ? 'border-accent/20' : ''}
                            `}>
                            {isSelected && (
                              <div className="w-5 h-5 rounded-full bg-primary flex items-center justify-center shrink-0">
                                <Check className="w-3 h-3 text-white" />
                              </div>
                            )}
                            <div className="min-w-0">
                              <p className="font-medium text-sm leading-tight truncate">{drink.name}</p>
                              <p className="text-xs text-muted-foreground mt-0.5">
                                {drink.abv === 0 ? '0%' : `${(drink.abv * 100).toFixed(0)}% · ${drink.volume_ml}ml`}
                              </p>
                            </div>
                          </motion.button>
                        );
                      })}
                    </div>
                  </div>
                );
              })}
            </div>

            {/* Bouton confirmer — toujours visible */}
            <div className="shrink-0 px-6 pt-3 pb-8 border-t border-white/5 bg-background/80 backdrop-blur-sm">
              <motion.button
                whileTap={{ scale: 0.97 }}
                onClick={handleConfirm}
                disabled={selectedIdx === null}
                className="w-full py-4 rounded-2xl font-semibold text-sm transition-all
                  bg-primary text-primary-foreground
                  disabled:opacity-30 disabled:cursor-not-allowed
                  enabled:hover:bg-primary/90"
              >
                {selectedIdx !== null
                  ? `Ajouter — ${ALL_DRINKS[selectedIdx].name} ✓`
                  : 'Sélectionne une boisson'}
              </motion.button>
            </div>
          </motion.div>
        </>
      )}
    </AnimatePresence>
  );
}
