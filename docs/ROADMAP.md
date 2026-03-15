# Roadmap Technique

## Principes de découpage

- Une seule session active à la fois
- Restore en best effort uniquement
- Pas de gestion avancée des fenêtres en v1
- Pas de restore parfait des fenêtres, onglets ou Spaces
- Pas de cloud, pas d'IA, pas d'intégrations profondes en MVP
- SwiftUI d'abord, AppKit seulement si nécessaire
- Persistance locale simple avant toute sophistication

## Étape 1 — Socle menu bar app

**Objectif**
- Stabiliser l'entrée d'application, la présence en barre de menu et l'accès à Settings.

**Fichiers concernés**
- `MeetingMode/MeetingModeApp.swift`
- `MeetingMode/Views/MenuBar/MenuBarContentView.swift`
- `MeetingMode/Views/Settings/SettingsView.swift`
- `MeetingMode.xcodeproj/project.pbxproj`

**Dépendances éventuelles**
- Aucune

**Critère de validation**
- L'app build
- L'app se lance sans fenêtre principale
- L'icône apparaît dans la barre de menu
- Settings reste accessible

**Hors périmètre explicite**
- Édition de presets
- Automation réelle
- Overlay réel

## Étape 2 — Modèles et stubs de services

**Objectif**
- Garder des modèles simples et des services séparés, sans logique métier avancée.

**Fichiers concernés**
- `MeetingMode/Models/Preset.swift`
- `MeetingMode/Models/ChecklistItem.swift`
- `MeetingMode/Models/SessionSnapshot.swift`
- `MeetingMode/Services/PresetStore.swift`
- `MeetingMode/Services/SessionRunner.swift`
- `MeetingMode/Services/AppLauncherService.swift`
- `MeetingMode/Services/OverlayService.swift`
- `MeetingMode/Services/RestoreService.swift`
- `MeetingMode/Services/PermissionService.swift`

**Dépendances éventuelles**
- Étape 1

**Critère de validation**
- Les services compilent ensemble
- Les responsabilités restent lisibles
- Aucun service ne simule une logique système non réelle

**Hors périmètre explicite**
- Persistance réelle
- Contrôle inter-apps avancé

## Étape 3 — Presets et état vide

**Objectif**
- Poser une gestion minimale des presets, y compris le cas “aucun preset”.

**Fichiers concernés**
- `MeetingMode/Models/Preset.swift`
- `MeetingMode/Services/PresetStore.swift`
- `MeetingMode/Views/MenuBar/MenuBarContentView.swift`
- `MeetingMode/Views/Presets/`

**Dépendances éventuelles**
- Étape 2

**Critère de validation**
- Le menu affiche un preset sélectionnable quand des données existent
- Le menu affiche un état vide clair quand il n'y a aucun preset
- L'UI ne propose pas de démarrer une session sans preset

**Hors périmètre explicite**
- CRUD complet complexe
- Import / export

## Étape 4 — Session active / inactive

**Objectif**
- Rendre explicite le cycle de vie d'une session, sans comportement métier profond.

**Fichiers concernés**
- `MeetingMode/Models/SessionSnapshot.swift`
- `MeetingMode/Services/SessionRunner.swift`
- `MeetingMode/Views/MenuBar/MenuBarContentView.swift`
- `MeetingMode/Views/Session/`

**Dépendances éventuelles**
- Étape 3

**Critère de validation**
- Une seule session active à la fois
- L'UI distingue clairement `inactive`, `active`, `restored`
- `Restore Session` revient à un état stable

**Hors périmètre explicite**
- Gestion de plusieurs sessions
- Historique complexe de sessions

## Étape 5 — Ouverture d'apps, URLs et fichiers en mode simple

**Objectif**
- Ajouter les actions d'ouverture les plus fiables avec les APIs macOS simples.

**Fichiers concernés**
- `MeetingMode/Models/Preset.swift`
- `MeetingMode/Services/AppLauncherService.swift`
- `MeetingMode/Services/SessionRunner.swift`
- `MeetingMode/Views/MenuBar/MenuBarContentView.swift`

**Dépendances éventuelles**
- Étape 4

**Critère de validation**
- Une app configurée peut être lancée
- Une URL configurée peut être ouverte
- Un fichier local configuré peut être ouvert
- Un échec ne casse pas la session ni l'UI

**Hors périmètre explicite**
- Scripts complexes
- Gestion avancée des fenêtres après ouverture

## Étape 6 — Overlay simple

**Objectif**
- Introduire un clean screen overlay minimal et réversible.

**Fichiers concernés**
- `MeetingMode/Services/OverlayService.swift`
- `MeetingMode/Services/SessionRunner.swift`
- `MeetingMode/Views/Session/`
- `MeetingMode/Utilities/`

**Dépendances éventuelles**
- Étape 4

**Critère de validation**
- L'overlay peut être activé et retiré proprement
- L'overlay n'empêche pas le retour à l'état inactif
- Le comportement reste compréhensible dans l'UI

**Hors périmètre explicite**
- Gestion multi-écran avancée
- Effets visuels complexes

## Étape 7 — Restore simple

**Objectif**
- Mettre en place un restore best effort limité à ce que l'app a réellement modifié.

**Fichiers concernés**
- `MeetingMode/Models/SessionSnapshot.swift`
- `MeetingMode/Services/RestoreService.swift`
- `MeetingMode/Services/SessionRunner.swift`
- `MeetingMode/Services/OverlayService.swift`

**Dépendances éventuelles**
- Étape 5
- Étape 6

**Critère de validation**
- Le restore ferme l'overlay si présent
- Le restore remet la session à `inactive`
- Le restore ne promet pas de remettre le Mac dans un état parfait

**Hors périmètre explicite**
- Restore exact de fenêtres, onglets et bureaux
- Rejeu complexe d'état système

## Étape 8 — Permissions et messaging

**Objectif**
- Exposer clairement les limites macOS et guider l'utilisateur sans fake behavior.

**Fichiers concernés**
- `MeetingMode/Services/PermissionService.swift`
- `MeetingMode/Views/Settings/SettingsView.swift`
- `MeetingMode/Views/MenuBar/MenuBarContentView.swift`
- `docs/DECISIONS.md`
- `docs/PROJECT_STATUS.md`

**Dépendances éventuelles**
- Étape 5
- Étape 7

**Critère de validation**
- Les textes n'annoncent que des permissions réellement nécessaires
- Les statuts affichés restent honnêtes
- L'UI explique clairement les limites de l'automation inter-apps

**Hors périmètre explicite**
- Wizard d'onboarding complexe
- Demande de permissions non justifiée

## Étape 9 — Persistance locale

**Objectif**
- Sauvegarder les presets et le preset sélectionné avec une approche simple et robuste.

**Fichiers concernés**
- `MeetingMode/Models/Preset.swift`
- `MeetingMode/Services/PresetStore.swift`
- `MeetingMode/Utilities/`
- `docs/DECISIONS.md`

**Dépendances éventuelles**
- Étape 3
- Étape 5

**Critère de validation**
- Les presets survivent à une relance
- Le preset sélectionné est restauré
- Une donnée corrompue échoue proprement sans bloquer l'app

**Hors périmètre explicite**
- Core Data
- SwiftData
- Sync cloud

## Étape 10 — Finition MVP

**Objectif**
- Finaliser une version petite, fiable et démontrable du MVP.

**Fichiers concernés**
- `MeetingMode/MeetingModeApp.swift`
- `MeetingMode/Views/MenuBar/MenuBarContentView.swift`
- `MeetingMode/Views/Settings/SettingsView.swift`
- `docs/TODO.md`
- `docs/PROJECT_STATUS.md`
- `docs/XCODE_SETUP.md`

**Dépendances éventuelles**
- Étapes 1 à 9

**Critère de validation**
- Le build Xcode est stable
- Les états clés sont couverts : vide, session active, restore
- Le flux principal tient dans la menu bar sans complexité inutile
- La documentation reflète exactement le périmètre livré

**Hors périmètre explicite**
- Refactor d'architecture
- Fonctionnalités de productivité générale
- Intégrations profondes Slack / Zoom / Teams / Calendar
