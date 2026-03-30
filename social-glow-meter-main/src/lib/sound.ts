export type SfxType = 'success' | 'error' | 'drink' | 'click';

export function playSfx(type: SfxType) {
  if (typeof window === 'undefined') return;

  const AudioContext = window.AudioContext || (window as any).webkitAudioContext;
  if (!AudioContext) return;

  const ctx = new AudioContext();
  const oscillator = ctx.createOscillator();
  const gainNode = ctx.createGain();

  oscillator.type = 'triangle';

  switch (type) {
    case 'success':
      oscillator.frequency.setValueAtTime(440, ctx.currentTime);
      gainNode.gain.setValueAtTime(0.12, ctx.currentTime);
      break;
    case 'error':
      oscillator.frequency.setValueAtTime(220, ctx.currentTime);
      gainNode.gain.setValueAtTime(0.16, ctx.currentTime);
      break;
    case 'drink':
      oscillator.frequency.setValueAtTime(660, ctx.currentTime);
      gainNode.gain.setValueAtTime(0.08, ctx.currentTime);
      break;
    case 'click':
      oscillator.frequency.setValueAtTime(520, ctx.currentTime);
      gainNode.gain.setValueAtTime(0.06, ctx.currentTime);
      break;
  }

  oscillator.connect(gainNode);
  gainNode.connect(ctx.destination);

  oscillator.start();
  oscillator.stop(ctx.currentTime + 0.16);

  gainNode.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + 0.16);

  setTimeout(() => {
    try {
      ctx.close();
    } catch {
      // Ignore
    }
  }, 500);
}
