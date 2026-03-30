import { useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { ChevronDown } from 'lucide-react';
import {
  Chart as ChartJS,
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  Title,
  Tooltip,
  Legend,
} from 'chart.js';
import { Line } from 'react-chartjs-2';
import { calculateBAC, DrinkEntry } from '@/hooks/useSupabase';

// Register required components for Chart.js
ChartJS.register(CategoryScale, LinearScale, PointElement, LineElement, Title, Tooltip, Legend);

interface Props {
  drinks: DrinkEntry[];
  weight: number;
  gender: 'male' | 'female';
}

export default function BACChart({ drinks, weight, gender }: Props) {
  const [expanded, setExpanded] = useState(false);
  const [showAdditional, setShowAdditional] = useState(false);

  const now = Date.now();
  
  // Generate data points for the next 12 hours
  const futureDataPoints = Array.from({ length: 13 }, (_, i) => {
    const time = now + i * 60 * 60 * 1000; // Every hour
    const bac = calculateBAC(drinks, weight, gender, time);
    return { 
      x: new Date(time).toLocaleTimeString('fr-FR', { hour: '2-digit', minute: '2-digit' }), 
      y: bac 
    };
  });

  // Generate data points for the past 6 hours
  const pastDataPoints = Array.from({ length: 7 }, (_, i) => {
    const time = now - (6 - i) * 60 * 60 * 1000; // Every hour, going back
    const bac = calculateBAC(drinks, weight, gender, time);
    return { 
      x: new Date(time).toLocaleTimeString('fr-FR', { hour: '2-digit', minute: '2-digit' }), 
      y: bac 
    };
  });

  // Combine past and future
  const allDataPoints = [...pastDataPoints, ...futureDataPoints];

  const mainData = {
    labels: futureDataPoints.map(p => p.x),
    datasets: [
      {
        label: 'Taux d\'alcoolémie (g/L)',
        data: futureDataPoints.map(p => p.y),
        borderColor: 'rgba(75, 192, 192, 1)',
        backgroundColor: 'rgba(75, 192, 192, 0.1)',
        borderWidth: 2,
        tension: 0.4,
        fill: true,
      },
    ],
  };

  const extendedData = {
    labels: allDataPoints.map(p => p.x),
    datasets: [
      {
        label: 'Taux d\'alcoolémie (g/L)',
        data: allDataPoints.map(p => p.y),
        borderColor: 'rgba(75, 192, 192, 1)',
        backgroundColor: 'rgba(75, 192, 192, 0.1)',
        borderWidth: 2,
        tension: 0.4,
        fill: true,
      },
    ],
  };

  const chartOptions = {
    responsive: true,
    maintainAspectRatio: true,
    plugins: {
      legend: {
        display: true,
        position: 'top' as const,
      },
    },
    scales: {
      x: {
        title: {
          display: true,
          text: 'Heure',
        },
      },
      y: {
        title: {
          display: true,
          text: 'BAC (g/L)',
        },
        min: 0,
        max: Math.max(3, Math.max(...allDataPoints.map(p => p.y)) + 0.5),
      },
    },
  };

  if (!expanded) {
    return (
      <motion.button
        onClick={() => setExpanded(true)}
        className="w-full glass-card p-4 flex items-center justify-between hover:bg-primary/10 transition-colors"
      >
        <p className="text-sm font-semibold text-muted-foreground">📊 Graphs de taux d'alcoolémie</p>
        <ChevronDown className="w-5 h-5 text-primary" />
      </motion.button>
    );
  }

  return (
    <motion.div
      initial={{ opacity: 0, height: 0 }}
      animate={{ opacity: 1, height: 'auto' }}
      exit={{ opacity: 0, height: 0 }}
      className="space-y-4"
    >
      {/* Main chart - next 12 hours */}
      <div className="glass-card p-4 space-y-3">
        <div className="flex items-center justify-between">
          <p className="text-sm font-semibold">Projection (12h)</p>
          <motion.button
            onClick={() => setExpanded(false)}
            className="text-sm text-muted-foreground hover:text-primary transition-colors"
          >
            ✕
          </motion.button>
        </div>
        <div className="h-64">
          <Line data={mainData} options={chartOptions} />
        </div>
      </div>

      {/* Additional graphs section */}
      <motion.button
        onClick={() => setShowAdditional(!showAdditional)}
        className="w-full glass-card p-3 flex items-center justify-between hover:bg-primary/10 transition-colors"
      >
        <p className="text-sm font-medium text-muted-foreground">+ Autres courbes</p>
        <ChevronDown
          className="w-4 h-4 text-primary transition-transform"
          style={{ transform: showAdditional ? 'rotate(180deg)' : 'rotate(0deg)' }}
        />
      </motion.button>

      <AnimatePresence>
        {showAdditional && (
          <motion.div
            initial={{ opacity: 0, height: 0 }}
            animate={{ opacity: 1, height: 'auto' }}
            exit={{ opacity: 0, height: 0 }}
            className="space-y-4"
          >
            {/* Extended timeline - past 6h + next 12h */}
            <div className="glass-card p-4 space-y-3">
              <p className="text-sm font-semibold">Timeline complète (-6h à +12h)</p>
              <div className="h-64">
                <Line data={extendedData} options={chartOptions} />
              </div>
            </div>

            {/* Stats */}
            <div className="glass-card p-4 space-y-3">
              <p className="text-sm font-semibold">Statistiques</p>
              <div className="grid grid-cols-2 gap-3">
                <div className="bg-primary/10 rounded-xl p-3">
                  <p className="text-xs text-muted-foreground">Alcool consommé</p>
                  <p className="text-xl font-bold">
                    {drinks.filter(d => d.alcohol_grams > 0).reduce((sum, d) => sum + d.alcohol_grams, 0).toFixed(1)}g
                  </p>
                </div>
                <div className="bg-accent/10 rounded-xl p-3">
                  <p className="text-xs text-muted-foreground">Verres</p>
                  <p className="text-xl font-bold">{drinks.filter(d => d.alcohol_grams > 0).length}</p>
                </div>
                <div className="bg-primary/10 rounded-xl p-3">
                  <p className="text-xs text-muted-foreground">Eau</p>
                  <p className="text-xl font-bold">{drinks.filter(d => d.alcohol_grams === 0).length}</p>
                </div>
                <div className="bg-accent/10 rounded-xl p-3">
                  <p className="text-xs text-muted-foreground">BAC max</p>
                  <p className="text-xl font-bold">{Math.max(...allDataPoints.map(p => p.y)).toFixed(2)}</p>
                </div>
              </div>
            </div>
          </motion.div>
        )}
      </AnimatePresence>
    </motion.div>
  );
}
