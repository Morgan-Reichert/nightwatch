import { useState, useRef, useCallback } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { Wine, X, Check, Loader2, Zap, ZapOff, ChevronDown } from 'lucide-react';
import { toast } from 'sonner';
import { supabase } from '@/integrations/supabase/client';

interface DetectedDrink {
  drink: string;
  volume_ml: number;
  abv: number;
  confidence: number;
}

interface Props {
  onDrinkDetected: (drink: { name: string; volume_ml: number; abv: number; detected_by_ai: boolean }) => void;
  onOpenChange?: (open: boolean) => void;
}

const VOLUME_PRESETS = [
  { label: 'Shot', ml: 30 },
  { label: 'Verre', ml: 150 },
  { label: 'Demi', ml: 250 },
  { label: 'Can', ml: 330 },
  { label: '50cl', ml: 500 },
  { label: '75cl', ml: 750 },
];

export default function CameraScanner({ onDrinkDetected, onOpenChange }: Props) {
  const [isOpen, setIsOpen] = useState(false);
  const [isScanning, setIsScanning] = useState(false);
  const [detected, setDetected] = useState<DetectedDrink | null>(null);
  const [flashOn, setFlashOn] = useState(false);
  // editable fields
  const [editName, setEditName] = useState('');
  const [editVolume, setEditVolume] = useState(0);
  const [customVolume, setCustomVolume] = useState('');
  const [showCustom, setShowCustom] = useState(false);
  const videoRef = useRef<HTMLVideoElement>(null);
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const streamRef = useRef<MediaStream | null>(null);

  const startCamera = useCallback(async () => {
    try {
      const stream = await navigator.mediaDevices.getUserMedia({ video: { facingMode: 'environment' } });
      streamRef.current = stream;
      if (videoRef.current) videoRef.current.srcObject = stream;
    } catch {
      toast.error("Impossible d'accéder à la caméra");
      setIsOpen(false);
    }
  }, []);

  const stopCamera = useCallback(() => {
    streamRef.current?.getTracks().forEach(t => t.stop());
    streamRef.current = null;
    setFlashOn(false);
  }, []);

  const toggleFlash = useCallback(async () => {
    const track = streamRef.current?.getVideoTracks()[0];
    if (!track) return;
    try {
      const capabilities = track.getCapabilities() as any;
      if (!capabilities?.torch) { toast.error('Flash non disponible'); return; }
      const newState = !flashOn;
      await track.applyConstraints({ advanced: [{ torch: newState } as any] });
      setFlashOn(newState);
    } catch { toast.error('Flash non disponible'); }
  }, [flashOn]);

  const open = () => {
    setIsOpen(true);
    onOpenChange?.(true);
    setDetected(null);
    setShowCustom(false);
    setTimeout(startCamera, 300);
  };

  const close = () => {
    stopCamera();
    setIsOpen(false);
    onOpenChange?.(false);
    setDetected(null);
    setShowCustom(false);
  };

  const captureAndScan = async () => {
    if (!videoRef.current || !canvasRef.current) return;
    setIsScanning(true);
    const video = videoRef.current;
    const canvas = canvasRef.current;
    canvas.width = video.videoWidth || 640;
    canvas.height = video.videoHeight || 480;
    const ctx = canvas.getContext('2d');
    if (!ctx) return;
    ctx.drawImage(video, 0, 0);
    const imageBase64 = canvas.toDataURL('image/jpeg', 0.8);
    try {
      const { data, error } = await supabase.functions.invoke('detect-drink', { body: { imageBase64 } });
      if (error) throw error;
      if (data.error) throw new Error(data.error);
      const d = data as DetectedDrink;
      setDetected(d);
      setEditName(d.drink);
      setEditVolume(d.volume_ml);
      setCustomVolume(String(d.volume_ml));
    } catch (err: any) {
      toast.error(err.message || "Erreur lors de l'analyse");
    }
    setIsScanning(false);
  };

  const confirm = () => {
    if (!detected) return;
    const finalVolume = showCustom ? (parseInt(customVolume) || editVolume) : editVolume;
    onDrinkDetected({
      name: editName || detected.drink,
      volume_ml: finalVolume,
      abv: detected.abv,
      detected_by_ai: true,
    });
    toast.success(`📸 ${editName} ajouté !`);
    close();
  };

  const selectPreset = (ml: number) => {
    setEditVolume(ml);
    setShowCustom(false);
  };

  return (
    <>
      <motion.button
        whileTap={{ scale: 0.9 }}
        onClick={open}
        className="fixed right-6 z-40 w-14 h-14 rounded-full bg-accent flex items-center justify-center neon-glow-cyan"
        style={{ bottom: 'calc(5.5rem + env(safe-area-inset-bottom))' }}
      >
        <Wine className="w-6 h-6 text-accent-foreground" />
      </motion.button>

      <canvas ref={canvasRef} className="hidden" />

      <AnimatePresence>
        {isOpen && (
          <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }}
            className="fixed inset-0 z-[60] bg-background flex flex-col">

            {/* Camera feed */}
            <div className="relative flex-1 overflow-hidden">
              <video ref={videoRef} autoPlay playsInline muted className="w-full h-full object-cover" />
              {isScanning && (
                <div className="absolute inset-0 pointer-events-none">
                  <div className="absolute left-0 right-0 h-0.5 bg-gradient-to-r from-transparent via-accent to-transparent animate-scan-line" />
                </div>
              )}
              <div className="absolute inset-0 flex items-center justify-center pointer-events-none">
                <div className="w-48 h-48 border-2 border-accent/40 rounded-3xl" />
              </div>
              <div className="absolute top-6 left-6 right-6 flex justify-between">
                <motion.button whileTap={{ scale: 0.9 }} onClick={close}
                  className="w-10 h-10 glass-card flex items-center justify-center rounded-full">
                  <X className="w-5 h-5" />
                </motion.button>
                <motion.button whileTap={{ scale: 0.9 }} onClick={toggleFlash}
                  className={`w-10 h-10 glass-card flex items-center justify-center rounded-full ${flashOn ? 'bg-accent/30' : ''}`}>
                  {flashOn ? <Zap className="w-5 h-5 text-accent" /> : <ZapOff className="w-5 h-5 text-muted-foreground" />}
                </motion.button>
              </div>
            </div>

            {/* Bottom panel */}
            <div className="p-5 space-y-4 bg-background">
              {!detected && !isScanning && (
                <motion.button whileTap={{ scale: 0.95 }} onClick={captureAndScan}
                  className="w-full glass-button bg-accent/20 text-accent font-semibold text-center">
                  📸 Scanner avec l'IA
                </motion.button>
              )}

              {isScanning && (
                <div className="flex items-center justify-center gap-2 text-accent py-3">
                  <Loader2 className="w-5 h-5 animate-spin" />
                  <span className="text-sm">Analyse IA en cours...</span>
                </div>
              )}

              {detected && (
                <motion.div initial={{ y: 20, opacity: 0 }} animate={{ y: 0, opacity: 1 }} className="space-y-4">
                  {/* Confidence badge */}
                  <div className="flex items-center justify-between">
                    <p className="text-xs text-muted-foreground">Détecté par l'IA</p>
                    <span className="text-xs bg-accent/20 text-accent px-2 py-1 rounded-full">
                      {Math.round(detected.confidence * 100)}% sûr
                    </span>
                  </div>

                  {/* Editable drink name */}
                  <div className="glass-card px-4 py-3">
                    <p className="text-[10px] text-muted-foreground mb-1 uppercase tracking-wide">Boisson</p>
                    <input
                      value={editName}
                      onChange={e => setEditName(e.target.value)}
                      className="bg-transparent w-full text-base font-bold focus:outline-none"
                      placeholder="Nom de la boisson"
                    />
                  </div>

                  {/* Volume presets */}
                  <div>
                    <p className="text-[10px] text-muted-foreground mb-2 uppercase tracking-wide">Quantité bue</p>
                    <div className="grid grid-cols-3 gap-2">
                      {VOLUME_PRESETS.map(p => (
                        <motion.button
                          key={p.ml}
                          whileTap={{ scale: 0.95 }}
                          onClick={() => selectPreset(p.ml)}
                          className={`py-2.5 rounded-xl text-sm font-medium transition-all ${
                            editVolume === p.ml && !showCustom
                              ? 'bg-primary/30 text-primary border border-primary/50'
                              : 'glass-card text-muted-foreground'
                          }`}
                        >
                          <span className="block text-xs font-bold">{p.label}</span>
                          <span className="block text-[10px] opacity-60">{p.ml}ml</span>
                        </motion.button>
                      ))}
                    </div>

                    {/* Custom volume toggle */}
                    <motion.button
                      whileTap={{ scale: 0.97 }}
                      onClick={() => setShowCustom(!showCustom)}
                      className="mt-2 w-full glass-card py-2 text-xs text-muted-foreground flex items-center justify-center gap-1"
                    >
                      Autre quantité
                      <ChevronDown className={`w-3 h-3 transition-transform ${showCustom ? 'rotate-180' : ''}`} />
                    </motion.button>

                    <AnimatePresence>
                      {showCustom && (
                        <motion.div
                          initial={{ height: 0, opacity: 0 }}
                          animate={{ height: 'auto', opacity: 1 }}
                          exit={{ height: 0, opacity: 0 }}
                          className="overflow-hidden"
                        >
                          <div className="glass-card px-4 py-3 mt-2 flex items-center gap-2">
                            <input
                              type="number"
                              value={customVolume}
                              onChange={e => setCustomVolume(e.target.value)}
                              className="bg-transparent flex-1 text-sm focus:outline-none"
                              placeholder="Ex: 400"
                            />
                            <span className="text-xs text-muted-foreground">ml</span>
                          </div>
                        </motion.div>
                      )}
                    </AnimatePresence>
                  </div>

                  {/* Action buttons */}
                  <div className="grid grid-cols-2 gap-3">
                    <motion.button whileTap={{ scale: 0.95 }} onClick={() => { setDetected(null); setShowCustom(false); }}
                      className="glass-button text-center text-sm">
                      Réessayer
                    </motion.button>
                    <motion.button whileTap={{ scale: 0.95 }} onClick={confirm}
                      className="glass-button bg-primary/20 text-primary text-center text-sm font-semibold">
                      <Check className="w-4 h-4 inline mr-1" /> Confirmer
                    </motion.button>
                  </div>
                </motion.div>
              )}
            </div>
          </motion.div>
        )}
      </AnimatePresence>
    </>
  );
}
