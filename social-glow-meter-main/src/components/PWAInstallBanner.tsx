import { useEffect, useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { X, Download, Share } from 'lucide-react';

const isIOS = () => /iphone|ipad|ipod/i.test(navigator.userAgent);
const isInStandaloneMode = () =>
  ('standalone' in navigator && (navigator as any).standalone) ||
  window.matchMedia('(display-mode: standalone)').matches;

export default function PWAInstallBanner() {
  const [prompt, setPrompt] = useState<any>(null);
  const [show, setShow] = useState(false);
  const [ios, setIos] = useState(false);

  useEffect(() => {
    if (isInStandaloneMode()) return;
    if (localStorage.getItem('pwa-dismissed')) return;

    if (isIOS()) {
      setIos(true);
      setShow(true);
      return;
    }

    const handler = (e: any) => {
      e.preventDefault();
      setPrompt(e);
      setShow(true);
    };
    window.addEventListener('beforeinstallprompt', handler);
    return () => window.removeEventListener('beforeinstallprompt', handler);
  }, []);

  // Register service worker
  useEffect(() => {
    if ('serviceWorker' in navigator) {
      navigator.serviceWorker.register('/sw.js').catch(() => {});
    }
  }, []);

  const handleInstall = async () => {
    if (!prompt) return;
    prompt.prompt();
    const { outcome } = await prompt.userChoice;
    if (outcome === 'accepted') dismiss();
  };

  const dismiss = () => {
    setShow(false);
    localStorage.setItem('pwa-dismissed', '1');
  };

  return (
    <AnimatePresence>
      {show && (
        <motion.div
          initial={{ y: 120, opacity: 0 }}
          animate={{ y: 0, opacity: 1 }}
          exit={{ y: 120, opacity: 0 }}
          transition={{ type: 'spring', damping: 24, stiffness: 280 }}
          className="fixed bottom-6 left-4 right-4 z-[200] max-w-lg mx-auto"
        >
          <div className="bg-[#13003a] border border-purple-500/40 rounded-2xl p-4 shadow-2xl shadow-purple-900/40 flex items-center gap-4"
            style={{ backdropFilter: 'blur(20px)' }}>
            <img src="/icon-192.png" alt="Nightwatch" className="w-12 h-12 rounded-xl shrink-0" />
            <div className="flex-1 min-w-0">
              <p className="font-bold text-sm text-white">Installer Nightwatch</p>
              {ios ? (
                <p className="text-xs text-purple-300 leading-tight mt-0.5">
                  Appuie sur <Share className="inline w-3 h-3" /> puis <strong>"Sur l'écran d'accueil"</strong>
                </p>
              ) : (
                <p className="text-xs text-purple-300 leading-tight mt-0.5">
                  Accès rapide depuis ton écran d'accueil
                </p>
              )}
            </div>
            {!ios && (
              <motion.button
                whileTap={{ scale: 0.95 }}
                onClick={handleInstall}
                className="shrink-0 flex items-center gap-1.5 bg-purple-600 hover:bg-purple-500 text-white text-xs font-bold px-4 py-2.5 rounded-xl transition-colors"
              >
                <Download className="w-3.5 h-3.5" />
                Installer
              </motion.button>
            )}
            <button onClick={dismiss} className="shrink-0 w-7 h-7 rounded-full bg-white/10 flex items-center justify-center">
              <X className="w-3.5 h-3.5 text-white/70" />
            </button>
          </div>
        </motion.div>
      )}
    </AnimatePresence>
  );
}
