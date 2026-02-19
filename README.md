# 📰 Gazette Famille

**App Flutter de journal familial mensuel partagé** — Créez ensemble une gazette imprimable chaque mois.

---

## 🎯 Concept

Chaque mois, les membres de la famille contribuent à une gazette commune : photos, textes, humeurs, moments magiques. À la fin du mois, exportez un PDF prêt à imprimer et conserver.

**Idéal pour :**
- Familles éloignées géographiquement
- Garder des souvenirs mensuels
- Impliquer les enfants et grands-parents
- Créer un héritage familial tangible

---

## ✨ Fonctionnalités

### Authentification
- Inscription/connexion Email + Mot de passe
- Firebase Authentication

### Familles
- Créer une famille (nom, limite foyers)
- Inviter des membres via lien (deep link `gazette://invite/{familleId}`)
- Gérer les membres

### Gazettes mensuelles
- Création automatique de la gazette du mois
- Contributions individuelles (chacun sa page)
- 4 layouts au choix :
  - **1 photo** : texte long (300 mots)
  - **2 photos** : texte moyen (200 mots)
  - **3 photos** : texte court (100 mots)
  - **Texte à trous** : phrases pré-remplies (pour maman/enfants)

### Contenus
- **Photos** : 1 à 3 selon layout
- **Titre + texte** libre
- **Humeur du mois** : sélection emoji
- **Meilleure chose du mois**
- **Anticipation** : ce que j'attends le mois prochain
- **Mode blancs** : Moment magique, Activité, Bon repas

### Export PDF
- Page de couverture (nom famille + mois)
- 1 page A4 par membre
- Photos intégrées
- Mise en page automatique
- Partage direct (impression ou envoi)

---

## 🚀 Installation & Configuration

### Prérequis
- Flutter 3.41.0+
- Dart 3.11.0+
- Compte Firebase (gratuit)

### Setup Firebase

Voir **[FIREBASE-SETUP.md](FIREBASE-SETUP.md)** pour le guide complet (9 étapes).

**Résumé :**
1. Créer projet Firebase
2. Ajouter app Android (`com.cenaia.gazette_famille`)
3. Télécharger `google-services.json` → `android/app/`
4. Activer Authentication (Email/Password)
5. Créer Firestore Database (mode test)
6. Activer Firebase Storage
7. `flutter pub get`

### Commandes

```bash
# Dépendances
flutter pub get

# Vérifier le code
flutter analyze

# Lancer sur device
flutter run

# Build APK Android
flutter build apk --debug
```

---

## 📂 Structure

```
lib/
├── main.dart                        # Point d'entrée + deep links
├── models/
│   ├── famille.dart
│   ├── gazette.dart
│   └── page_gazette.dart
├── screens/
│   ├── auth/
│   │   └── login_screen.dart        # Connexion/inscription
│   ├── famille/
│   │   ├── create_famille_screen.dart
│   │   ├── invite_screen.dart       # Partage lien invitation
│   │   └── join_famille_screen.dart # Rejoindre via lien
│   ├── gazette/
│   │   ├── gazette_screen.dart      # Liste gazettes
│   │   └── preview_screen.dart      # Preview + export PDF
│   ├── contribution/
│   │   └── contribution_screen.dart # Ma page du mois
│   ├── home/
│   │   └── home_screen.dart         # Dashboard
│   └── profile/
│       └── profile_screen.dart      # Profil utilisateur
└── utils/
    └── colors.dart
```

---

## 🔥 Firebase

### Collections Firestore

```
/users/{userId}
  - displayName: string
  - email: string
  - familyId: string
  - createdAt: timestamp

/familles/{familleId}
  - nom: string
  - maxFoyers: number
  - membreIds: array<string>
  - createdAt: timestamp
  - invite_token: string

/gazettes/{gazetteId}
  - famille_id: string
  - mois: string (ex: "2026-02")
  - statut: "ouvert" | "ferme" | "imprime"
  - deadline: timestamp
  - createdAt: timestamp
  
  /pages/{userId}  (sous-collection)
    - layout: string
    - titre: string
    - texte: string
    - photos: array<string>
    - humeur: string
    - meilleur_chose: string
    - anticipation: string
    - moment_magique: string
    - activite: string
    - repas: string
    - soumis: boolean
    - updated_at: timestamp
```

### Storage

```
/familles/{familleId}/
  /gazettes/{gazetteId}/
    /photos/{userId}_photo_0.jpg
    /photos/{userId}_photo_1.jpg
    ...
```

---

## 💰 Business Model (prévu)

**Forfaits famille :**
- **4 foyers** : 4,99€/mois
- **6 foyers** : 6,99€/mois
- **8 foyers** : 8,99€/mois
- **10 foyers** : 9,99€/mois

Paiement unique par famille, tous les membres contribuent.

---

## 🎨 Design

- **Material Design 3**
- **Google Fonts** : Inter
- **Palette** :
  - Primary: `#1976D2` (Bleu)
  - Accent: `#FF6F00` (Orange)
  - Success: `#388E3C` (Vert)
  - Info: `#0288D1` (Bleu clair)
  - Warning: `#F57C00` (Orange foncé)
  - Error: `#D32F2F` (Rouge)

---

## 📦 Packages

```yaml
dependencies:
  # Firebase
  firebase_core: ^3.13.0
  firebase_auth: ^5.5.2
  cloud_firestore: ^5.6.6
  firebase_storage: ^12.4.4

  # State
  provider: ^6.1.2

  # UI
  google_fonts: ^6.3.0
  intl: ^0.19.0
  cached_network_image: ^3.4.1

  # PDF
  pdf: ^3.10.8
  printing: ^5.13.1
  http: ^1.2.2

  # Fichiers
  image_picker: ^1.1.2
  path_provider: ^2.1.3
  share_plus: ^10.1.2

  # Deep links
  app_links: ^6.4.0

  # Local
  shared_preferences: ^2.3.3
```

---

## 🚧 Roadmap

- [x] Auth Firebase
- [x] Création famille + invitations
- [x] Contributions mensuelles (4 layouts)
- [x] Preview gazette
- [x] Export PDF complet
- [ ] Notifications (deadline approche)
- [ ] Gabarits de mise en page supplémentaires
- [ ] Import photos depuis Google Photos
- [ ] Intégration impression (Printful, Lulu)
- [ ] Abonnements Stripe
- [ ] Version iOS

---

## 📄 Licence

Projet privé — Cenaia Labs  
Auteur : Mika (avec Stelar)

---

**Status :** ✅ v1.0 — 0 flutter analyze issues — PDF export fonctionnel — Firebase setup guide complet
