import { motion } from 'framer-motion';

interface Props {
  weeks: number;
  alive: boolean;
  size?: 'sm' | 'md' | 'lg';
  showLabel?: boolean;
}

/** Returns visual config based on streak length */
function getStreakConfig(weeks: number, alive: boolean) {
  if (!alive || weeks === 0) return {
    beerColor:  '#6b7280',
    flameColor: '#9ca3af',
    glowColor:  'transparent',
    label:      'Pas de flamme',
    tier:       'none' as const,
  };
  if (weeks >= 10) return {
    beerColor:  '#ef4444',
    flameColor: '#f97316',
    glowColor:  'rgba(239,68,68,0.5)',
    label:      'Flamme légendaire',
    tier:       'legendary' as const,
  };
  if (weeks >= 5) return {
    beerColor:  '#eab308',
    flameColor: '#f59e0b',
    glowColor:  'rgba(234,179,8,0.45)',
    label:      'Flamme dorée',
    tier:       'gold' as const,
  };
  if (weeks >= 3) return {
    beerColor:  '#a855f7',
    flameColor: '#c084fc',
    glowColor:  'rgba(168,85,247,0.4)',
    label:      'Flamme pourpre',
    tier:       'silver' as const,
  };
  return {
    beerColor:  '#3b82f6',
    flameColor: '#60a5fa',
    glowColor:  'rgba(59,130,246,0.35)',
    label:      'Flamme bleue',
    tier:       'bronze' as const,
  };
}

export default function StreakDisplay({ weeks, alive, size = 'md', showLabel = true }: Props) {
  const cfg = getStreakConfig(weeks, alive);
  const isActive = alive && weeks > 0;

  const dims = {
    sm: { outer: 40, beer: 22, flame: 14, font: '10px', countFont: '9px' },
    md: { outer: 56, beer: 32, flame: 20, font: '11px', countFont: '10px' },
    lg: { outer: 72, beer: 42, flame: 26, font: '13px', countFont: '11px' },
  }[size];

  return (
    <div className="flex flex-col items-center gap-1.5">
      <motion.div
        animate={isActive ? { scale: [1, 1.04, 1] } : {}}
        transition={{ duration: 2.5, repeat: Infinity, ease: 'easeInOut' }}
        style={{
          width: dims.outer,
          height: dims.outer,
          borderRadius: dims.outer * 0.35,
          background: isActive
            ? `radial-gradient(circle at 50% 60%, ${cfg.glowColor}, transparent 70%)`
            : 'rgba(255,255,255,0.04)',
          boxShadow: isActive ? `0 0 ${dims.outer * 0.5}px ${cfg.glowColor}` : 'none',
          border: `1.5px solid ${isActive ? cfg.beerColor + '60' : 'rgba(255,255,255,0.08)'}`,
          position: 'relative',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
        }}
      >
        {/* Beer SVG */}
        <svg width={dims.beer} height={dims.beer} viewBox="0 0 32 32" fill="none">
          {/* Mug body */}
          <rect x="4" y="10" width="18" height="18" rx="3"
            fill={isActive ? cfg.beerColor : '#4b5563'} />
          {/* Handle */}
          <path d="M22 14 C28 14 28 24 22 24" stroke={isActive ? cfg.beerColor : '#4b5563'}
            strokeWidth="3" strokeLinecap="round" fill="none" />
          {/* Foam */}
          <ellipse cx="13" cy="10" rx="9" ry="4"
            fill={isActive ? 'white' : '#6b7280'} opacity={isActive ? 0.9 : 0.4} />
          {/* Bubbles */}
          {isActive && <>
            <circle cx="9"  cy="20" r="1.5" fill="white" opacity="0.25" />
            <circle cx="14" cy="17" r="1"   fill="white" opacity="0.2"  />
            <circle cx="11" cy="24" r="1"   fill="white" opacity="0.2"  />
          </>}
        </svg>

        {/* Flame SVG — top right */}
        {isActive && (
          <motion.div
            style={{ position: 'absolute', top: -dims.flame * 0.45, right: -dims.flame * 0.25 }}
            animate={{ y: [0, -2, 0], scaleY: [1, 1.08, 1] }}
            transition={{ duration: 1.2, repeat: Infinity, ease: 'easeInOut' }}
          >
            <svg width={dims.flame} height={dims.flame} viewBox="0 0 20 24" fill="none">
              <path
                d="M10 2 C10 2 14 7 14 11 C14 13.5 12.5 15 12.5 15 C12.5 15 14 13 13 10 C13 10 16 14 14 18 C12.8 20.5 10 22 10 22 C10 22 7.2 20.5 6 18 C4 14 7 10 7 10 C6 13 7.5 15 7.5 15 C7.5 15 6 13.5 6 11 C6 7 10 2 10 2Z"
                fill={cfg.flameColor}
              />
              <path
                d="M10 10 C10 10 12 13 11.5 15.5 C11 17.5 10 18.5 10 18.5 C10 18.5 9 17.5 8.5 15.5 C8 13 10 10 10 10Z"
                fill="white" opacity="0.5"
              />
            </svg>
          </motion.div>
        )}

        {/* Week count badge */}
        {isActive && (
          <div style={{
            position: 'absolute',
            bottom: -6,
            right: -6,
            background: cfg.beerColor,
            borderRadius: 999,
            minWidth: 18,
            height: 18,
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            padding: '0 4px',
            fontSize: dims.countFont,
            fontWeight: 700,
            color: 'white',
            boxShadow: `0 0 6px ${cfg.glowColor}`,
          }}>
            {weeks}
          </div>
        )}
      </motion.div>

      {showLabel && (
        <div className="text-center">
          <p className="font-semibold leading-tight"
            style={{ color: isActive ? cfg.beerColor : '#6b7280', fontSize: dims.font }}>
            {isActive ? `${weeks} sem.` : 'Éteinte'}
          </p>
          {size !== 'sm' && (
            <p className="text-[9px] text-muted-foreground leading-tight">{cfg.label}</p>
          )}
        </div>
      )}
    </div>
  );
}
