import { useState, useRef } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { Plus, X, Clock } from 'lucide-react';
import { Story, Profile } from '@/hooks/useSupabase';

interface StoryWithProfile extends Story {
  profile?: Profile;
}

interface Props {
  stories: StoryWithProfile[];
  onAddStory: (file: File, caption: string) => Promise<void>;
  onViewingChange?: (viewing: boolean) => void;
}

export default function StoryViewer({ stories, onAddStory, onViewingChange }: Props) {
  const [viewingIdx, setViewingIdx] = useState<number | null>(null);

  const setViewing = (idx: number | null) => {
    setViewingIdx(idx);
    onViewingChange?.(idx !== null);
  };
  const [showAdd, setShowAdd] = useState(false);
  const [caption, setCaption] = useState('');
  const [preview, setPreview] = useState<string | null>(null);
  const [selectedFile, setSelectedFile] = useState<File | null>(null);
  const [uploading, setUploading] = useState(false);
  const fileRef = useRef<HTMLInputElement>(null);

  // Group stories by user
  const grouped = stories.reduce<Record<string, StoryWithProfile[]>>((acc, s) => {
    const key = s.user_id;
    if (!acc[key]) acc[key] = [];
    acc[key].push(s);
    return acc;
  }, {});
  const userStories = Object.values(grouped);

  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;
    setSelectedFile(file);
    const reader = new FileReader();
    reader.onload = () => setPreview(reader.result as string);
    reader.readAsDataURL(file);
    setShowAdd(true);
  };

  const handlePublish = async () => {
    if (!selectedFile) return;
    setUploading(true);
    try {
      await onAddStory(selectedFile, caption);
      setShowAdd(false);
      setCaption('');
      setPreview(null);
      setSelectedFile(null);
    } catch { }
    setUploading(false);
  };

  const currentStory = viewingIdx !== null ? stories[viewingIdx] : null;

  return (
    <>
      {/* Stories bar */}
      <div className="px-6 py-3 flex gap-3 overflow-x-auto scrollbar-hide">
        {/* Add story button */}
        <motion.button whileTap={{ scale: 0.9 }} onClick={() => fileRef.current?.click()}
          className="shrink-0 w-16 h-16 rounded-full border-2 border-dashed border-primary/40 flex items-center justify-center">
          <Plus className="w-5 h-5 text-primary" />
        </motion.button>
        <input ref={fileRef} type="file" accept="image/*" capture="environment" className="hidden" onChange={handleFileChange} />

        {/* User story circles */}
        {userStories.map((group, i) => {
          const latest = group[0];
          return (
            <motion.button key={latest.user_id} whileTap={{ scale: 0.9 }}
              onClick={() => setViewing(stories.indexOf(latest))}
              className="shrink-0 w-16 flex flex-col items-center gap-1">
              <div className="w-14 h-14 rounded-full p-0.5 bg-gradient-to-br from-primary to-accent">
                <div className="w-full h-full rounded-full bg-background flex items-center justify-center overflow-hidden">
                  {latest.image_url ? (
                    <img src={latest.image_url} alt="" className="w-full h-full object-cover rounded-full" />
                  ) : (
                    <span className="text-sm font-bold">{latest.profile?.pseudo?.charAt(0) || '?'}</span>
                  )}
                </div>
              </div>
              <span className="text-[10px] text-muted-foreground truncate w-14 text-center">
                {latest.profile?.pseudo || 'Anonyme'}
              </span>
            </motion.button>
          );
        })}
      </div>

      {/* Story viewer fullscreen */}
      <AnimatePresence>
        {currentStory && viewingIdx !== null && (
          <motion.div
            initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }}
            drag="x"
            dragConstraints={{ left: 0, right: 0 }}
            dragElastic={0.15}
            onDragEnd={(_, info) => {
              if (info.offset.x < -60) {
                if (viewingIdx < stories.length - 1) setViewing(viewingIdx + 1);
                else setViewing(null);
              } else if (info.offset.x > 60) {
                setViewing(Math.max(0, viewingIdx - 1));
              }
            }}
            className="fixed inset-0 z-[70] bg-black flex flex-col">

            {/* Image plein écran */}
            <img src={currentStory.image_url} alt="" className="absolute inset-0 w-full h-full object-contain" />

            {/* Header — au-dessus de la caméra/encoche */}
            <div className="absolute top-0 left-0 right-0 flex items-center justify-between bg-gradient-to-b from-black/70 to-transparent px-4 pb-6"
              style={{ paddingTop: 'calc(1rem + env(safe-area-inset-top))' }}>
              <div className="flex items-center gap-2">
                <div className="w-8 h-8 rounded-full bg-primary/20 flex items-center justify-center text-xs font-bold overflow-hidden">
                  {currentStory.profile?.avatar_url
                    ? <img src={currentStory.profile.avatar_url} alt="" className="w-full h-full object-cover" />
                    : currentStory.profile?.pseudo?.charAt(0) || '?'}
                </div>
                <div>
                  <p className="text-sm font-semibold text-white">{currentStory.profile?.pseudo || 'Anonyme'}</p>
                  <div className="flex items-center gap-1 text-[10px] text-white/70 font-mono">
                    <Clock className="w-2.5 h-2.5" />
                    {new Date(currentStory.created_at).toLocaleTimeString('fr-FR', { hour: '2-digit', minute: '2-digit' })}
                    {currentStory.bac_at_post ? ` • ${currentStory.bac_at_post.toFixed(2)}g/l` : ''}
                  </div>
                </div>
              </div>
              <motion.button whileTap={{ scale: 0.9 }} onClick={() => setViewing(null)}
                className="w-9 h-9 bg-black/40 backdrop-blur-sm flex items-center justify-center rounded-full border border-white/20">
                <X className="w-4 h-4 text-white" />
              </motion.button>
            </div>

            {/* Caption */}
            {currentStory.caption && (
              <div className="absolute left-4 right-4 glass-card p-3"
                style={{ bottom: 'calc(1rem + env(safe-area-inset-bottom))' }}>
                <p className="text-sm text-white">{currentStory.caption}</p>
              </div>
            )}

            {/* Zones de tap gauche/droite (derrière le header) */}
            <div className="absolute inset-0 flex" style={{ top: 'calc(4rem + env(safe-area-inset-top))' }}>
              <button className="flex-1" onClick={() => setViewing(Math.max(0, viewingIdx - 1))} />
              <button className="flex-1" onClick={() => {
                if (viewingIdx < stories.length - 1) setViewing(viewingIdx + 1);
                else setViewing(null);
              }} />
            </div>
          </motion.div>
        )}
      </AnimatePresence>

      {/* Add story drawer */}
      <AnimatePresence>
        {showAdd && (
          <>
            <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }}
              className="fixed inset-0 bg-black/60 z-[60]" onClick={() => setShowAdd(false)} />
            <motion.div initial={{ y: '100%' }} animate={{ y: 0 }} exit={{ y: '100%' }}
              transition={{ type: 'spring', damping: 25, stiffness: 300 }}
              className="fixed bottom-0 left-0 right-0 z-[61] glass-card rounded-b-none p-6 space-y-4" style={{ paddingBottom: 'calc(1.5rem + 5rem + env(safe-area-inset-bottom))' }}>
              {preview && (
                <img src={preview} alt="" className="w-full h-48 object-cover rounded-2xl" />
              )}
              <input value={caption} onChange={e => setCaption(e.target.value)} placeholder="Légende..."
                className="w-full glass-card p-3 bg-transparent text-sm focus:outline-none" />
              <motion.button whileTap={{ scale: 0.95 }} onClick={handlePublish} disabled={uploading}
                className="w-full glass-button bg-primary/20 text-primary font-semibold disabled:opacity-50">
                {uploading ? 'Publication...' : 'Publier la story 📸'}
              </motion.button>
            </motion.div>
          </>
        )}
      </AnimatePresence>
    </>
  );
}
