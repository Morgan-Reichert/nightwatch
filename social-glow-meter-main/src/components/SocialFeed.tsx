import { motion } from 'framer-motion';
import { DrinkEntry, PukeEvent, ShopEvent } from '@/hooks/useSupabase';
import { Clock } from 'lucide-react';

interface Props {
  drinks: DrinkEntry[];
  pukeEvents?: PukeEvent[];
  shopEvents?: ShopEvent[];
}

export default function SocialFeed({ drinks, pukeEvents = [], shopEvents = [] }: Props) {
  // Combine all activities and sort by date
  const allActivities = [
    ...drinks.map(d => ({ type: 'drink' as const, data: d, timestamp: new Date(d.created_at).getTime() })),
    ...pukeEvents.map(p => ({ type: 'quiche' as const, data: p, timestamp: new Date(p.created_at).getTime() })),
    ...shopEvents.map(s => ({ type: 'shop' as const, data: s, timestamp: new Date(s.created_at).getTime() })),
  ].sort((a, b) => b.timestamp - a.timestamp);

  if (allActivities.length === 0) return null;

  return (
    <div className="space-y-2">
      <p className="text-xs uppercase tracking-widest text-muted-foreground">Activité récente</p>
      <div className="space-y-2">
        {allActivities.slice(0, 8).map((activity, i) => (
          <motion.div 
            key={`${activity.type}-${activity.data.id}`} 
            initial={{ opacity: 0, x: -20 }} 
            animate={{ opacity: 1, x: 0 }}
            transition={{ delay: i * 0.05 }}
            className="glass-card p-3 flex items-center justify-between"
          >
            {activity.type === 'drink' && (
              <>
                <div className="flex items-center gap-3">
                  <span className="text-xl">
                    {activity.data.abv === 0 ? '💧' : activity.data.detected_by_ai ? '🤖' : '🍺'}
                  </span>
                  <div>
                    <p className="font-medium text-sm">{activity.data.name}</p>
                    <p className="text-xs text-muted-foreground">{activity.data.volume_ml}ml • {(activity.data.abv * 100).toFixed(0)}%</p>
                  </div>
                </div>
              </>
            )}
            
            {activity.type === 'quiche' && (
              <div className="flex items-center gap-3">
                <span className="text-xl">🤢</span>
                <div>
                  <p className="font-medium text-sm">Quiche moment</p>
                  <p className="text-xs text-muted-foreground">Ça va?</p>
                </div>
              </div>
            )}
            
            {activity.type === 'shop' && (
              <div className="flex items-center gap-3">
                <span className="text-xl">💋</span>
                <div>
                  <p className="font-medium text-sm">Shop moment</p>
                  <p className="text-xs text-muted-foreground">Smooch! ✨</p>
                </div>
              </div>
            )}
            
            <div className="flex items-center gap-1 text-xs text-muted-foreground font-mono">
              <Clock className="w-3 h-3" />
              {new Date(activity.data.created_at).toLocaleTimeString('fr-FR', { hour: '2-digit', minute: '2-digit' })}
            </div>
          </motion.div>
        ))}
      </div>
    </div>
  );
}
