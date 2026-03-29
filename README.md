# 🚚 Food Truck Pre-Order System

Système de pré-commande ultra-simple pour food truck.
Le client scanne un QR → choisit ses plats → choisit un créneau → confirme.
Le owner voit toutes les commandes dans le dashboard.

## Stack

- **Frontend**: Vanilla HTML/CSS/JS (zero build step)
- **Backend**: Supabase (Postgres + RLS + Realtime)
- **Hosting**: N'importe où (Vercel, Netlify, même GitHub Pages)

## Setup

### 1. Supabase

1. Crée un projet sur [supabase.com](https://supabase.com)
2. Va dans **SQL Editor** et colle le contenu de `schema.sql`
3. Exécute — ça crée les tables, RLS policies, function, et seed data
4. Récupère ton `SUPABASE_URL` et `SUPABASE_ANON_KEY` dans Settings > API

### 2. Config

Dans `public/index.html`, remplace :
```js
const SUPABASE_URL = 'YOUR_SUPABASE_URL';
const SUPABASE_ANON_KEY = 'YOUR_SUPABASE_ANON_KEY';
```

Dans `public/admin.html`, remplace :
```js
const SUPABASE_URL = 'YOUR_SUPABASE_URL';
const SUPABASE_KEY = 'YOUR_SUPABASE_SERVICE_ROLE_KEY';
```

> ⚠️ Le `service_role` key donne un accès admin complet. 
> En production, protège `admin.html` avec un mot de passe ou une auth.

### 3. Personnalisation

- Change le nom du food truck dans `index.html` (header)
- Modifie le seed data dans `schema.sql` (menu items, slots)
- Ajuste les créneaux horaires dans la table `slot_config`

### 4. Déploiement

```bash
# Option simple: Vercel
npm i -g vercel
cd public
vercel
```

Ou mets les 2 fichiers HTML sur n'importe quel hébergement statique.

### 5. QR Code

Génère un QR code pointant vers l'URL publique de `index.html`.
Le owner l'affiche sur son food truck → les clients scannent et réservent.

## Architecture

```
public/
├── index.html    ← Page client (pré-commande)
└── admin.html    ← Dashboard owner

schema.sql        ← Migration Supabase
```

### Tables

| Table | Usage |
|-------|-------|
| `menu_items` | Les plats du food truck |
| `slot_config` | Créneaux horaires + capacité max |
| `orders` | Commandes clients |
| `order_items` | Détail des plats par commande |

### Fonction RPC

`get_slot_availability(target_date)` → retourne les créneaux avec le nombre de places restantes.

## Évolutions possibles

- [ ] Auth admin (Supabase Auth)
- [ ] Notifications push / SMS quand la commande est prête
- [ ] Paiement en ligne (Stripe)
- [ ] Multi-day planning (pas juste "today")
- [ ] Photo des plats
- [ ] PWA pour le owner (notifications)
- [ ] **Intégration Opnclo** comme module de réservation
