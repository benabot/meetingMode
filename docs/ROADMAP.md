# Roadmap Technique

## Base actuelle

Le socle MVP courant est considéré comme assez stable pour arrêter les grosses corrections structurelles sur :

- menu bar app
- presets locaux
- start session
- masquage best effort des apps hors preset
- clean screen overlay
- restore best effort limité au scope réellement modifié

La suite a été réalisée dans cet ordre :

1. ~~raccourcis clavier~~ ✓
2. ~~multilingue FR + EN~~ ✓
3. ~~passe visuelle plus “liquid glass”~~ ✓
4. ~~onboarding, icône d'app, launch at login~~ ✓
5. ~~testabilité et tests unitaires (PresetStore + SessionRunner)~~ ✓
6. ~~nettoyage des textes du tutoriel~~ ✓

## Principes de suite

- garder une seule session active à la fois
- rester SwiftUI d'abord, AppKit seulement si nécessaire
- ne pas ajouter de dépendance externe
- ne pas rouvrir le chantier des fenêtres avancées, Spaces ou plein écran
- garder des changements petits, testables et réversibles
- ne pas faire de polish visuel qui cache des états ambigus

## Étape 1 — Raccourcis clavier configurables ✓

**Objectif**
- Ajouter deux raccourcis clavier configurables dans `Settings` :
- un pour `Start Session`
- un pour `Restore Session`
- garder une solution petite et robuste, sans système de commandes complexe

**Fichiers concernés**
- `MeetingMode/Views/Settings/SettingsView.swift`
- `MeetingMode/MeetingModeApp.swift`
- `MeetingMode/Services/SessionRunner.swift`
- `MeetingMode/Services/`
- `MeetingMode/Utilities/`
- `docs/DECISIONS.md`
- `docs/PROJECT_STATUS.md`

**Dépendances éventuelles**
- Aucune dépendance externe
- AppKit / Carbon seulement si nécessaire pour des hotkeys globaux fiables
- Persistance simple via `UserDefaults` ou couche locale déjà existante

**Critère de validation**
- L'utilisateur peut définir un raccourci `Start Session`
- L'utilisateur peut définir un raccourci `Restore Session`
- Les deux raccourcis survivent à une relance
- Les collisions évidentes sont bloquées ou refusées proprement
- `Start Session` ne s'exécute pas si une session est déjà active
- `Restore Session` ne s'exécute pas s'il n'y a pas de session active
- Aucune dépendance externe n'est ajoutée

**Hors périmètre explicite**
- Mapping complexe de raccourcis par preset
- Système de commandes avancé
- Personnalisation riche du clavier au-delà des deux actions MVP

## Étape 2 — Multilingue FR + EN ✓

**Objectif**
- Rendre l'app entièrement multilingue en FR et EN
- Extraire proprement toutes les chaînes visibles
- Ajouter un choix explicite de langue dans `Settings`
- Éviter toute localisation partielle

**Fichiers concernés**
- `MeetingMode/MeetingModeApp.swift`
- `MeetingMode/Views/MenuBar/MenuBarContentView.swift`
- `MeetingMode/Views/Settings/SettingsView.swift`
- `MeetingMode/Views/Session/CleanScreenOverlayView.swift`
- `MeetingMode/Views/Presets/`
- `MeetingMode/Services/SessionRunner.swift`
- `MeetingMode/Resources/`
- `docs/DECISIONS.md`
- `docs/PROJECT_STATUS.md`

**Dépendances éventuelles**
- Étape 1
- Extraction centralisée des chaînes visibles avant toute passe visuelle
- Choix simple de persistance de langue locale

**Critère de validation**
- Toutes les chaînes visibles de l'app existent en FR et en EN
- Aucune chaîne visible importante ne reste en dur hors système de localisation
- L'utilisateur peut choisir explicitement FR ou EN dans `Settings`
- Le choix de langue survit à une relance
- La popover, Settings, l'overlay et l'éditeur de preset restent cohérents dans une seule langue

**Hors périmètre explicite**
- Plus de deux langues dans cette passe
- Localisation partielle ou opportuniste
- Refactor massif de structure UI uniquement pour la localisation

## Étape 3 — Passe visuelle “liquid glass” minimale ✓

**Objectif**
- Ajouter une finition visuelle plus “liquid glass”
- Rester subtil, lisible et compatible avec les états métier
- Ne pas dégrader la clarté des actions `Start Session` et `Restore Session`

**Fichiers concernés**
- `MeetingMode/Views/MenuBar/MenuBarContentView.swift`
- `MeetingMode/Views/Settings/SettingsView.swift`
- `MeetingMode/Views/Session/CleanScreenOverlayView.swift`
- `MeetingMode/Utilities/`
- `docs/DECISIONS.md`
- `docs/PROJECT_STATUS.md`

**Dépendances éventuelles**
- Étape 1 terminée
- Étape 2 terminée
- Textes et états déjà figés avant la passe visuelle

**Critère de validation**
- L'UI gagne en qualité perçue sans perdre en lisibilité
- Les états `Ready`, `Active`, `Restored` restent immédiatement compréhensibles
- Les actions principales restent visibles et évidentes
- La popover reste compacte et stable
- Aucun recul de clarté entre FR et EN

**Hors périmètre explicite**
- Refonte lourde de navigation
- Refonte complète du layout
- Animation sophistiquée ou décorative qui gêne l'usage
- Nouveau système de design étendu à tout le produit

## Résumé de séquencement

1. ~~Stabiliser les raccourcis clavier configurables~~ ✓
2. ~~Stabiliser toutes les chaînes visibles et la langue FR / EN~~ ✓
3. ~~Faire seulement ensuite la passe visuelle~~ ✓
4. ~~Onboarding, icône d'app, launch at login~~ ✓
5. ~~Testabilité SessionRunner + tests unitaires PresetStore et SessionRunner~~ ✓
6. ~~Nettoyage des textes du tutoriel (ton utilisateur, pas développeur)~~ ✓

Les 6 étapes de la roadmap initiale sont terminées. La suite se concentre sur l'extension de la couverture de tests et le polish restant.
