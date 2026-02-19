# 🔥 Firebase Setup — Gazette Famille

Guide complet pour configurer Firebase pour l'app Flutter **Gazette Famille**.

---

## Prérequis

- Compte Google actif
- Flutter installé (`flutter --version`)
- Projet Flutter `gazette_famille` prêt localement

---

## Étape 1 — Créer le projet Firebase

1. Aller sur [console.firebase.google.com](https://console.firebase.google.com)
2. Cliquer **"Ajouter un projet"**
3. Nom du projet : `gazette-famille`
4. Désactiver Google Analytics (optionnel pour démarrer)
5. Cliquer **"Créer le projet"**
6. Attendre la création, puis cliquer **"Continuer"**

---

## Étape 2 — Ajouter l'application Android

1. Dans la console Firebase, cliquer l'icône **Android** (< />)
2. Renseigner :
   - **Package Android** : `com.cenaia.gazette_famille`
   - **Surnom de l'app** : `Gazette Famille`
   - **Certificat SHA-1** : laisser vide pour l'instant (à ajouter plus tard pour Auth Google)
3. Cliquer **"Enregistrer l'application"**

---

## Étape 3 — Télécharger et placer google-services.json

1. Télécharger le fichier `google-services.json` proposé par Firebase
2. Le placer dans :
   ```
   android/app/google-services.json
   ```
3. **Ne jamais commiter ce fichier dans un dépôt public** — ajouter au `.gitignore` si nécessaire :
   ```
   android/app/google-services.json
   ```

### Vérifier les fichiers Gradle

**`android/build.gradle`** — ajouter dans `dependencies` du bloc `buildscript` :
```groovy
dependencies {
    classpath 'com.google.gms:google-services:4.4.0'
}
```

**`android/app/build.gradle`** — ajouter en bas du fichier :
```groovy
apply plugin: 'com.google.gms.google-services'
```

---

## Étape 4 — Activer Authentication (Email/Password)

1. Dans la console Firebase → menu **Authentication**
2. Onglet **"Mode de connexion"**
3. Cliquer **"Email/Mot de passe"**
4. Activer le premier toggle (**Email/Mot de passe**)
5. Cliquer **"Enregistrer"**

> ✅ Les utilisateurs pourront s'inscrire et se connecter avec email + mot de passe.

---

## Étape 5 — Créer la base Firestore

1. Dans la console Firebase → menu **Firestore Database**
2. Cliquer **"Créer une base de données"**
3. Choisir **"Commencer en mode test"** *(accès libre 30 jours — à sécuriser avant prod)*
4. Sélectionner la région : **`eur3` (Europe)** recommandé
5. Cliquer **"Activer"**

### Structure de collections suggérée

```
/users/{userId}
  - displayName: string
  - email: string
  - createdAt: timestamp
  - familyId: string

/families/{familyId}
  - name: string
  - members: array
  - createdAt: timestamp

/gazettes/{gazetteId}
  - familyId: string
  - title: string
  - month: string (ex: "2026-02")
  - createdAt: timestamp
  - pages: array

/articles/{articleId}
  - gazetteId: string
  - authorId: string
  - title: string
  - content: string
  - mediaUrls: array
  - createdAt: timestamp
```

### Règles Firestore (mode test → à sécuriser)

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Mode test : accès total pendant 30 jours
    match /{document=**} {
      allow read, write: if request.time < timestamp.date(2026, 3, 21);
    }
  }
}
```

---

## Étape 6 — Activer Firebase Storage

1. Dans la console Firebase → menu **Storage**
2. Cliquer **"Commencer"**
3. Choisir **"Commencer en mode test"**
4. Sélectionner la région : **`eur3` (Europe)**
5. Cliquer **"Terminer"**

> ✅ Utilisé pour stocker les photos et médias des articles de gazette.

### Structure Storage suggérée

```
/families/{familyId}/
  /avatars/{userId}.jpg
  /gazettes/{gazetteId}/
    /covers/{cover.jpg}
    /articles/{articleId}/{media.jpg}
```

---

## Étape 7 — Dépendances Flutter

### Ajouter dans `pubspec.yaml`

```yaml
dependencies:
  flutter:
    sdk: flutter

  # Firebase core (obligatoire)
  firebase_core: ^3.0.0

  # Authentication
  firebase_auth: ^5.0.0

  # Firestore
  cloud_firestore: ^5.0.0

  # Storage
  firebase_storage: ^12.0.0

  # UI Auth (optionnel - formulaires prêts)
  # flutterfire_ui: ^0.4.0
```

### Commandes à exécuter

```bash
# Installer les dépendances
flutter pub get

# Vérifier la configuration Firebase (si FlutterFire CLI installé)
flutterfire configure

# Lancer l'app en debug
flutter run

# Vérifier qu'il n'y a pas d'erreurs de build Android
flutter build apk --debug
```

---

## Étape 8 — Initialiser Firebase dans le code

### `lib/main.dart`

```dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // généré par FlutterFire CLI

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const GazetteFamilleApp());
}
```

### Générer `firebase_options.dart` (recommandé)

```bash
# Installer FlutterFire CLI
dart pub global activate flutterfire_cli

# Configurer automatiquement
flutterfire configure --project=gazette-famille
```

Cela génère `lib/firebase_options.dart` automatiquement.

---

## Étape 9 — Test de connexion Firebase

### Test rapide dans une page Flutter

```dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Test Auth — créer un utilisateur test
Future<void> testAuth() async {
  try {
    final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: 'test@gazette.fr',
      password: 'TestPassword123!',
    );
    print('✅ Auth OK — UID: ${credential.user?.uid}');
  } catch (e) {
    print('❌ Auth Error: $e');
  }
}

// Test Firestore — écrire un document
Future<void> testFirestore() async {
  try {
    await FirebaseFirestore.instance.collection('test').add({
      'message': 'Firebase fonctionne!',
      'timestamp': FieldValue.serverTimestamp(),
    });
    print('✅ Firestore OK');
  } catch (e) {
    print('❌ Firestore Error: $e');
  }
}
```

---

## Checklist finale

- [ ] Projet Firebase créé
- [ ] App Android ajoutée (`com.cenaia.gazette_famille`)
- [ ] `google-services.json` dans `android/app/`
- [ ] Gradle configuré (classpath + plugin)
- [ ] Authentication Email/Password activée
- [ ] Firestore créé (mode test)
- [ ] Storage activé (mode test)
- [ ] `pubspec.yaml` mis à jour
- [ ] `flutter pub get` exécuté sans erreur
- [ ] `Firebase.initializeApp()` dans `main.dart`
- [ ] Test de connexion validé

---

## Ressources

- [Firebase Flutter Docs](https://firebase.google.com/docs/flutter/setup)
- [FlutterFire](https://firebase.flutter.dev/)
- [Console Firebase](https://console.firebase.google.com)
- [Firestore Rules](https://firebase.google.com/docs/firestore/security/get-started)

---

*Guide créé pour le projet Gazette Famille — Cenaia Labs*
