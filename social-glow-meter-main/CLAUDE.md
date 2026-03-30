# Nightwatch — Context pour Claude

## Infos critiques
- **App** : React 18 + TypeScript + Vite (PAS Next.js)
- **Supabase** : projet perso `vqkiypjxeazydizqhgar` — accès complet au dashboard sur supabase.com
  - URL : `https://vqkiypjxeazydizqhgar.supabase.co`
  - Clé : `sb_publishable_O6Hm_lrqn00XjrounXi7Og_O64VoV1u`
  - Ces valeurs sont dans `.env` (VITE_SUPABASE_URL + VITE_SUPABASE_PUBLISHABLE_KEY)
- **Déployé** sur **https://nightwatch-app.vercel.app** (compte Vercel `alexismcns-projects`)
- **Pas de git** dans ce projet — impossible de revenir en arrière, donc ne pas supprimer de code existant sans demande explicite

## Déployer
```bash
npm run build
cd dist && rm -rf .vercel && npx vercel --prod --yes --name nightwatch-app
```
Toujours `npm run build` avant de déployer. Les env vars sont embarquées au build (Vite).

## Règles absolues
- **Lire entièrement** `useSupabase.ts`, `SettingsPanel.tsx`, `Shop.tsx`, `UserProfileModal.tsx` avant de les modifier
- **Ne jamais supprimer** de fonctionnalité existante sans demande explicite
- `npm run build` doit passer sans erreur avant tout déploiement
- **Ne jamais toucher** au CSS de `.tab-bar` — c'est `position: fixed !important; bottom: 0 !important; z-index: 999 !important`

## Architecture

### Fichier client Supabase
`src/integrations/supabase/client.ts` — utilise `import.meta.env.VITE_SUPABASE_*`

### Hooks (`src/hooks/useSupabase.ts`)
- `useProfile()` — profil complet (snapchat, instagram, tiktok, city, school, job, zodiac, music_taste, party_style, avatar_frame, banner_gradient) + subscription realtime Supabase
- `useDrinks(partyId?)` — retourne aussi `deleteDrink(id)` et `deleteAllDrinks(alcoholOnly?)`
- `useAllMyDrinks()` — tous les drinks de l'utilisateur (global, pas per-party)
- `usePukeEvents(partyId?)` — retourne aussi `deletePukeEvent(id)` et `deleteAllPukeEvents()`
- `useShopEvents(partyId?)` — retourne aussi `deleteShopEvent(id)` et `deleteAllShopEvents()`
- `useStreakForUser(userId)` — streak ISO semaine (1 soirée/semaine pour maintenir)
- `useUserStats(userId)` — stats pour badges (drinks, parties, quiches, bisous, friends)
- `useMyPurchases()` + `recordPurchase(itemId)` — achats boutique
- `isPseudoAvailable(pseudo, userId)` — vérif pseudo unique (index LOWER+TRIM)
- `useFriendships()` — auto-accept si demande inverse existante
- `useParties()` — retourne `{ parties, currentParty, setCurrentParty, members, createParty, joinParty, leaveParty, deleteParty, fetchMembers, toggleBacVisibility, refetch }` — `PartyMember` a `show_bac?: boolean`
- `useStories(partyId?)`, `usePartyPhotos(partyId?)`, `useMemberLocations(partyId?)`
- `useMyPartyInvitations()`, `useInviteMember()`
- `calculateBAC(drinks, weight, gender)` — exportée (utilisée dans Index.tsx, LeaderboardPanel)
- `getBACStatus(bac)` — exportée

### Composants clés
- `BadgesSection` — prop `userId` (calcule elle-même) OU prop `badges` (pré-calculés)
- `StreakDisplay` — icône bière+flamme SVG, props: `weeks`, `alive`, `size` (sm/md/lg), `showLabel`
  - Couleurs : gris=0, bleu=1-2sem, violet=3-4sem, or=5-9sem, rouge=10+sem
  - Sur le profil/modal : badge SVG en bas-droite de l'avatar (condition: `streak.weeks > 0`)
  - Sur l'accueil : affiché à côté du pseudo dans le header (`size="sm" showLabel={false}`)
- `Shop` — Stripe Payment Links statiques dans `src/lib/shopItems.ts`
  - Lien Stripe test : `https://buy.stripe.com/test_eVq6oH6IscP1cr0gDngjC01`
  - URL succès : `https://nightwatch-app.vercel.app/?tab=shop&success=1&item_id=<id>`
  - Grille 2 colonnes pour cadres et bannières, colonne unique pour flamme
- `SocialFeed` — activité récente avec suppression unitaire (icône poubelle au hover) + menu "Gérer" pour suppression en masse
- `PWAInstallBanner` — Android: `beforeinstallprompt`, iOS: instructions Share
- `DrinkSelector` — 28 boissons en 5 catégories, z-[60] pour passer au-dessus de la navbar
- `UserProfileModal` — z-[60] sur le backdrop ; streak badge SVG en bas-droite de l'avatar avec `overflow: visible` sur les conteneurs parents
- `LeaderboardPanel` — filtre `visibleMembers` (membres avec `show_bac !== false`) pour les stats BAC
- `CameraScanner` — bouton positionné avec `bottom: calc(5.5rem + env(safe-area-inset-bottom))`
- `LaunchTutorial` — affiché au premier lancement (`localStorage: sgm_tutorial_seen`)

### Navbar
- 5 onglets : Accueil / Soirée / Top / Amis / Boutique
- **Réglages** : accessible via photo de profil en haut à droite du header (pas dans la navbar)
- Badge notifications : onglet Amis (demandes en attente) + onglet Soirée (invitations)
- CSS `.tab-bar` — **NE PAS MODIFIER** :
  ```css
  position: fixed !important;
  bottom: 0 !important;
  z-index: 999 !important;
  transform: translateZ(0);
  background: rgba(0, 0, 0, 0.9);
  padding-bottom: max(0.9rem, env(safe-area-inset-bottom));
  ```

### Layout principal (Index.tsx)
```jsx
<div className="min-h-[100vh] pb-[5.5rem] mobile:pb-[6.5rem] max-w-[430px] w-full mx-auto"
     style={{ paddingTop: 'env(safe-area-inset-top)' }}>
  {/* header, content, nav */}
</div>
```
- La navbar est un sibling du contenu (pas dans un flex container)
- `#root` dans index.css : `padding-top: env(safe-area-inset-top)`, `width: min(100%, 430px)`, `min-height: 100dvh`

### PWA / Mobile
- `viewport-fit=cover` + `apple-mobile-web-app-status-bar-style: black-translucent` dans `index.html`
- `#root { padding-top: env(safe-area-inset-top); padding-bottom: env(safe-area-inset-bottom) }` dans `index.css`
- `.tab-bar` a `padding-bottom: max(0.9rem, env(safe-area-inset-bottom))`
- Service worker : `public/sw.js`
- `overscroll-behavior: none` sur `body`
- `100dvh` pour iOS Safari

### BAC Toggle (Leaderboard)
- Colonne `show_bac BOOLEAN DEFAULT true` dans la table `party_members` (migration SQL nécessaire si pas encore appliquée)
- `toggleBacVisibility(partyId)` dans `useParties()` — toggle pour l'utilisateur courant
- Toggle affiché dans le tab Leaderboard quand l'utilisateur est dans une soirée
- `LeaderboardPanel` filtre avec `members.filter(m => m.show_bac !== false)`

### Détection boissons par IA
- **Mistral Pixtral** (remplacé OpenAI suite à quota insuffisant)
- Clé API dans `.env` : `VITE_MISTRAL_API_KEY`
- Fichier : `src/components/CameraScanner.tsx`

### Base de données (toutes les tables)
profiles, parties, party_members, drinks, friendships, stories, party_photos, puke_events, shop_events, party_requests, member_locations, user_purchases
+ Storage buckets : avatars, stories, party-photos

### Stripe
- Pas d'Edge Function (contournement avec Payment Links statiques)
- Carte test : `4242 4242 4242 4242`, date future, CVC quelconque
- En production : changer les liens test par de vrais liens Stripe dans `src/lib/shopItems.ts`

## Auth Google + Apple
Maintenant possible car accès au vrai dashboard Supabase :
1. Supabase → Authentication → URL Configuration → ajouter `https://nightwatch-app.vercel.app/**`
2. Google : créer OAuth client sur console.cloud.google.com, redirect URI = `https://vqkiypjxeazydizqhgar.supabase.co/auth/v1/callback`
3. Apple : nécessite compte Apple Developer (99$/an)

## Ce qui reste à faire
- Configurer Google/Apple OAuth (maintenant possible avec Supabase perso)
- Liens Stripe réels pour tous les items (pour l'instant même lien test pour tout)
- Appliquer avatar_frame dans FriendsPanel si les avatars y sont affichés
- Migration SQL BAC toggle si pas encore appliquée : `ALTER TABLE party_members ADD COLUMN IF NOT EXISTS show_bac BOOLEAN DEFAULT true;`
