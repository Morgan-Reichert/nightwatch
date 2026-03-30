import { motion } from 'framer-motion';
import { Car, Phone, Siren } from 'lucide-react';
import { toast } from 'sonner';
import { playSfx } from '@/lib/sound';

interface Props {
  emergencyContact: string;
  onQuiche?: () => Promise<void>;
  onShop?: () => Promise<void>;
}

export default function EmergencyActions({ emergencyContact, onQuiche, onShop }: Props) {
  const handleQuiche = async () => {
    try {
      await onQuiche?.();
      playSfx('error');
      toast.success('Ça va? 🤢');
    } catch (err: any) {
      toast.error(err.message);
    }
  };

  const handleShop = async () => {
    try {
      await onShop?.();
      playSfx('success');
      toast.success('Slay! 💋✨');
    } catch (err: any) {
      toast.error(err.message);
    }
  };

  return (
    <div className="space-y-3">
      <p className="text-xs uppercase tracking-widest text-muted-foreground">Actions rapides</p>
      <div className="grid grid-cols-3 gap-3">
        <motion.a
          whileTap={{ scale: 0.95 }}
          href="uber://"
          className="glass-card p-4 flex flex-col items-center gap-2 text-center"
        >
          <Car className="w-6 h-6 text-accent" />
          <span className="text-xs font-medium">Uber</span>
        </motion.a>

        <motion.a
          whileTap={{ scale: 0.95 }}
          href={emergencyContact ? `tel:${emergencyContact}` : '#'}
          className="glass-card p-4 flex flex-col items-center gap-2 text-center"
        >
          <Phone className="w-6 h-6 text-primary" />
          <span className="text-xs font-medium">Proche</span>
        </motion.a>

        <motion.a
          whileTap={{ scale: 0.95 }}
          href="tel:112"
          className="glass-card p-4 flex flex-col items-center gap-2 text-center border-red-500/30"
        >
          <Siren className="w-6 h-6 text-red-400" />
          <span className="text-xs font-medium">SOS 112</span>
        </motion.a>
      </div>

      {/* Quiche and Shop buttons */}
      {(onQuiche || onShop) && (
        <div className="grid grid-cols-2 gap-3">
          {onQuiche && (
            <motion.button
              whileTap={{ scale: 0.95 }}
              onClick={handleQuiche}
              className="glass-card p-4 flex flex-col items-center gap-2 text-center text-destructive hover:bg-destructive/10 transition-colors"
            >
              <span className="text-2xl">🤢</span>
              <span className="text-xs font-medium">Quiche</span>
            </motion.button>
          )}
          {onShop && (
            <motion.button
              whileTap={{ scale: 0.95 }}
              onClick={handleShop}
              className="relative overflow-hidden rounded-2xl p-4 flex flex-col items-center gap-2 text-center text-white font-medium"
              style={{
                background: 'linear-gradient(135deg, #ec4899 0%, #f97316 100%)',
              }}
            >
              <span className="text-2xl">💋</span>
              <span className="text-xs">Bisous</span>
            </motion.button>
          )}
        </div>
      )}
    </div>
  );
}
