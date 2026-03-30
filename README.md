<div align="center">

<img width="100%" src="https://capsule-render.vercel.app/api?type=waving&color=0:0a0a1a,40:1a1040,100:302b63&height=160&section=header&text=NightWatch&fontSize=40&fontColor=ffffff&fontAlignY=45&desc=L'app%20qui%20veille%20sur%20ta%20soirée%20·%20STARIAX&descAlignY=68&descColor=c4b5fd" />

</div>

<div align="center">

[![STARIAX](https://img.shields.io/badge/Groupe-STARIAX-7c3aed?style=for-the-badge&logo=github&logoColor=white)](https://github.com/Morgan-Reichert)
[![iOS](https://img.shields.io/badge/iOS-Swift-000000?style=for-the-badge&logo=swift&logoColor=white)](#)
[![Web](https://img.shields.io/badge/Web-PWA-302b63?style=for-the-badge&logo=pwa&logoColor=white)](#)
[![Beta](https://img.shields.io/badge/statut-Bêta%20ouverte-f59e0b?style=for-the-badge)](#)

</div>

---

## 📸 Aperçu

> 🖼️ **Pour ajouter tes screenshots :** Upload tes images dans ce repo (`Add file` → `Upload files`), puis remplace les liens ci-dessous.

<table>
<tr>
<td width="50%" align="center">

![Screenshot 1](https://placehold.co/600x340/0a0a1a/c4b5fd?text=📸+Screenshot+1+—+Accueil)
*Écran d'accueil*

</td>
<td width="50%" align="center">

![Screenshot 2](https://placehold.co/600x340/1a1040/ffffff?text=📸+Screenshot+2+—+Suivi+soirée)
*Suivi en temps réel*

</td>
</tr>
<tr>
<td width="50%" align="center">

![Screenshot iOS](https://placehold.co/300x580/0f0c29/a78bfa?text=📱+iOS+App)
*Version iOS*

</td>
<td width="50%" align="center">

![Screenshot Web](https://placehold.co/600x340/302b63/f59e0b?text=📸+Version+Web+PWA)
*Version Web (PWA)*

</td>
</tr>
</table>

---

## 🧪 Tester NightWatch en version bêta

<div align="center">

> **NightWatch est en bêta ouverte !**
> Tu cherches une app pour mieux gérer tes soirées entre amis ? Deviens bêta-testeur — iOS ou Web, ton choix.
> Tes retours m'aident directement à améliorer l'app.

[![✉️ Rejoindre la bêta NightWatch](https://img.shields.io/badge/✉️%20Rejoindre%20la%20bêta%20NightWatch-f59e0b?style=for-the-badge)](mailto:morgan.reichert.pro@outlook.com?subject=Beta%20NightWatch&body=Bonjour%20Morgan%2C%20je%20souhaite%20tester%20NightWatch%20en%20version%20bêta.)

*Précise dans ton mail si tu veux tester la version iOS ou Web · Réponse sous 48h* 📬

</div>

---

# NightWatch

> L'app qui veille sur ta soirée — Groupe [Stariax Belgium](https://github.com/Morgan-Reichert/STARIAX)

---

## Présentation

**NightWatch** est une Progressive Web App (PWA) sociale et responsable, conçue pour accompagner les soirées entre amis de façon intelligente. L'application permet de suivre sa consommation d'alcool en temps réel, de partager des moments avec ses amis, et de garder un œil bienveillant sur le groupe.

Ce repo contient **deux applications** :

| Dossier | Description |
|---------|-------------|
| [`social-glow-meter-main/`](./social-glow-meter-main) | Application web PWA (React + Supabase) |
| [`nightwatch-ios/`](./nightwatch-ios) | Application iOS native (Swift 5.9 + iOS 17) |

---

## Philosophie

- **Social** : tout tourne autour du groupe — créer ou rejoindre une soirée, voir ses amis en temps réel.
- **Responsable** : alcoolémie estimée affichée en permanence, alertes si quelqu'un dépasse un seuil dangereux.
- **Fun** : badges, streaks, classements, stories — la soirée gamifiée sans anxiété.
- **Privé** : chaque utilisateur contrôle ce qu'il partage.

---

## Application Web (PWA) — `social-glow-meter-main/`

### Stack Technique

| Composant         | Technologie                                      |
|-------------------|--------------------------------------------------|
| Framework         | React 18 + TypeScript + Vite 8                   |
| UI / Styles       | Tailwind CSS 3 + shadcn/ui                       |
| Animations        | Framer Motion 12                                 |
| Backend / BDD     | Supabase (PostgreSQL + Auth + Storage + Realtime)|
| Paiements         | Stripe Payment Links                             |
| IA (scanner)      | Mistral API — Pixtral (vision)                   |
| Graphiques        | Chart.js 4 + react-chartjs-2                     |
| Déploiement       | Vercel — nightwatch-app.vercel.app               |
| Type d'app        | PWA (Progressive Web App)                        |

### Fonctionnalités Clés

- **Jauge BAC** : alcoolémie estimée en g/L, recalculée toutes les 30s (poids, genre, consommations)
- **Scanner IA** : photo d'une bouteille → Mistral Pixtral identifie la boisson, volume et taux d'alcool
- **Soirées** : créer/rejoindre via un code à 6 caractères, galerie photos partagée, carte temps réel des membres
- **Classements** : Party Kings, Hydration Heroes, Quiche Kings, Shop Kings
- **Stories** : 24h de durée, viewer plein écran avec BAC auto-affiché
- **Amis** : recherche par pseudo, demandes d'amis, suggestions par contacts
- **Boutique** : cadres d'avatar, bannières de profil, résurrection de streak — Stripe Payment Links
- **Streak** : système de flamme par régularité (bleu → violet → or → rouge légendaire)
- **Alertes** : bandeau rouge si BAC > 1.0 g/L, notification de membres en danger
- **Localisation** : partage GPS dans le contexte de la soirée (mise à jour toutes les 60s)

### Base de Données (Supabase)

Tables : `profiles` · `parties` · `party_members` · `drinks` · `friendships` · `stories`
· `party_photos` · `puke_events` · `shop_events` · `party_requests` · `member_locations` · `user_purchases`

Buckets : `avatars` · `stories` · `party-photos`

### Lancement

```bash
cd social-glow-meter-main
npm install
npm run dev
# → http://localhost:8080
```

Variables d'environnement requises :
```
VITE_SUPABASE_URL=...
VITE_SUPABASE_ANON_KEY=...
VITE_STRIPE_PUBLISHABLE_KEY=...
VITE_MISTRAL_API_KEY=...
```

---

## Application iOS — `nightwatch-ios/`

### Stack Technique

| Composant   | Technologie                          |
|-------------|--------------------------------------|
| Langage     | Swift 5.9                            |
| Plateforme  | iOS 17+                              |
| Backend     | Supabase Swift SDK (supabase-swift ^2.0) |
| Build       | Xcode + Swift Package Manager       |

### Structure

```
nightwatch-ios/
├── NightwatchiOS/
│   ├── Core/           # Config, Extensions, Models, Services, SupabaseClient
│   ├── Features/       # Auth, Friends, Home, Leaderboard, Party, Settings, Shop
│   ├── Shared/         # Composants partagés
│   └── NightwatchApp.swift
├── NightwatchiOS.xcodeproj/
└── Package.swift
```

### Lancement

Ouvrir `NightwatchiOS.xcodeproj` dans Xcode, configurer les variables Supabase dans `Core/Config.swift`, puis Build & Run sur simulateur ou appareil iOS 17+.

---

## Groupe Stariax

| Projet | Description |
|--------|-------------|
| [MindScope](https://github.com/Morgan-Reichert/mindscope) | Suivi santé mentale avec IA locale |
| [NightWatch](https://github.com/Morgan-Reichert/nightwatch) | PWA sociale de suivi en soirée |
| [Stariax Showcase](https://github.com/Morgan-Reichert/stariax-showcase) | Site vitrine du groupe |
| [Challenger IA](https://github.com/Morgan-Reichert/challenger-ia) | Plateforme IA — bientôt disponible |

---

*Stariax Belgium — Bruxelles, 2026*

