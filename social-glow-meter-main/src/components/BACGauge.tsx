import { motion } from 'framer-motion';
import { getBACStatus, getTimeTo } from '@/hooks/useSupabase';

interface Props {
  bac: number;
}

export default function BACGauge({ bac }: Props) {
  const status = getBACStatus(bac);
  const timeToZero = getTimeTo(0, bac);
  const timeToLegal = getTimeTo(0.5, bac);

  const statusColors = { safe: 'bac-safe', warning: 'bac-warning', danger: 'bac-danger' };
  const statusGlow = {
    safe: '0 0 40px hsla(142, 71%, 45%, 0.3)',
    warning: '0 0 40px hsla(38, 92%, 50%, 0.3)',
    danger: '0 0 40px hsla(0, 84%, 60%, 0.4)',
  };
  const statusLabel = {
    safe: bac === 0 ? '✨ Sobre' : '🟢 Prudence',
    warning: '🟡 Attention',
    danger: '🔴 NE CONDUIS PAS',
  };

  const formatTime = (hours: number) => {
    if (hours <= 0) return '—';
    const h = Math.floor(hours);
    const m = Math.round((hours - h) * 60);
    return h > 0 ? `${h}h${m.toString().padStart(2, '0')}` : `${m}min`;
  };

  return (
    <motion.div
      initial={{ opacity: 0, scale: 0.9 }}
      animate={{ opacity: 1, scale: 1 }}
      className="glass-card p-6 text-center space-y-4"
      style={{ boxShadow: statusGlow[status] }}
    >
      <p className="text-xs uppercase tracking-widest text-muted-foreground">Taux d'alcoolémie</p>
      <motion.div key={bac} initial={{ scale: 1.1 }} animate={{ scale: 1 }}
        className={`text-6xl font-bold font-mono tabular-nums ${statusColors[status]}`}>
        {bac.toFixed(2)}
        <span className="text-lg text-muted-foreground ml-1">g/l</span>
      </motion.div>
      <p className={`text-sm font-semibold ${statusColors[status]}`}>{statusLabel[status]}</p>
      {bac > 0 && (
        <div className="grid grid-cols-2 gap-3 pt-2">
          <div className="glass-card p-3">
            <p className="text-xs text-muted-foreground">Sobre dans</p>
            <p className="text-lg font-mono font-semibold text-accent">{formatTime(timeToZero)}</p>
          </div>
          {bac > 0.5 && (
            <div className="glass-card p-3">
              <p className="text-xs text-muted-foreground">&lt;0.5g/l dans</p>
              <p className="text-lg font-mono font-semibold bac-warning">{formatTime(timeToLegal)}</p>
            </div>
          )}
        </div>
      )}
    </motion.div>
  );
}