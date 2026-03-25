# Roadmap Technique

## Base actuelle

Le socle MVP courant est considéré comme assez stable pour arrêter les grosses corrections structurelles sur :

- menu bar app
- presets locaux
- start session
- masquage best effort des apps hors preset
- presentation background overlay
- restore best effort limité au scope réellement modifié

La suite a été réalisée dans cet ordre :

1. ~~raccourcis clavier~~ ✓
2. ~~multilingue FR + EN~~ ✓
3. ~~passe visuelle plus “liquid glass”~~ ✓
4. ~~onboarding, icône d'app, launch at login~~ ✓
5. ~~testabilité et tests unitaires (PresetStore + SessionRunner)~~ ✓
6. ~~nettoyage des textes du tutoriel~~ ✓
7. ~~fiabilisation : persistance snapshot sur crash, correction état overlay au relaunch, multi-screen overlay~~ ✓

## Principes de suite

- garder une seule session active à la fois
- rester SwiftUI d'abord, AppKit seulement si nécessaire
- ne pas ajouter de dépendance externe
- ne pas rouvrir le chantier des fenêtres avancées, Spaces ou plein écran
- garder des changements petits, testables et réversibles
- ne pas faire de polish visuel qui cache des états ambigus
- garder le wording principal sur `Préparer le Mac` et `Rétablir le Mac`
- garder le fond de présentation local et simple: aucun, fond uni, ou image locale; Photos reste hors scope pour l'instant
- pour le test manuel externe, l'artifact de référence est le Release `.app` local; la signature, la notarization et le DMG restent pour plus tard
- la Release externe préparée pour le test manuel doit démarrer vide quand aucun preset utilisateur n'existe, et le tutorial doit encore s'ouvrir une fois sur la première ouverture de cette build
- la Release externe préparée pour le test manuel doit démarrer vide quand aucun preset utilisateur n'existe, et le tutorial doit encore s'ouvrir une fois sur la première ouverture de cette build

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

## Étape 7 — Fiabilisation et correctifs ✓

**Objectif**
- Persister le snapshot de session sur disque pour survivre à un crash ou force quit
- Corriger l'état de l'overlay au relaunch (overlayWasShown forcé à false car la fenêtre est perdue)
- Étendre l'overlay à tous les écrans connectés au moment du start

**Fichiers concernés**
- `MeetingMode/Services/SessionRunner.swift`
- `MeetingMode/Services/OverlayService.swift`
- `docs/DECISIONS.md`
- `docs/PROJECT_STATUS.md`

**Dépendances éventuelles**
- Protocoles de testabilité déjà en place (OverlayProviding, SessionRestoring)

**Critère de validation**
- Un force quit pendant une session active permet de restaurer via `Restore Session` au relaunch
- L'UI ne revendique pas un overlay visible après un relaunch
- L'overlay couvre tous les écrans connectés au démarrage de la session

**Hors périmètre explicite**
- Surveillance dynamique des changements d'écran pendant la session
- Restauration de l'overlay après relaunch

## Étape 8 — Distribution élargie

**Objectif**
- Finaliser plus tard une distribution élargie fiable hors App Store
- Signer et notariser sans rouvrir le périmètre produit
- Garder le restore actuel explicite : apps lancées par la session seulement, pas de promesse sur URLs et fichiers
- Le chemin manuel externe court terme reste le Release `.app` local

**Fichiers concernés**
- `MeetingMode.xcodeproj`
- `docs/DECISIONS.md`
- `docs/PROJECT_STATUS.md`
- `docs/SANDBOX_AUDIT.md`

**Dépendances éventuelles**
- Choix confirmé : distribution directe prioritaire
- Validation build signée + notarized

**Critère de validation**
- L'app peut être signée et notarisée sans erreur quand on active cette voie
- Le flux MVP complet fonctionne dans la build Release locale
- Les limites de restore restent documentées honnêtement

**Hors périmètre explicite**
- Migration App Store
- Refactor sandbox
- Fermeture précise d'onglets ou de documents déjà ouverts dans d'autres apps

## V2 — Attribution du contenu ouvert ✓

**État validé**
- Le socle V2 est en place: snapshot structuré, attribution cible au moment de l'ouverture, et restore strict pour les apps lancées par Meeting Mode.
- Le tracking enregistre au moment de l'ouverture l'URL ou le fichier, le bundle identifier cible si connu, et si l'app cible a été lancée par Meeting Mode.
- Le restore ne revendique une fermeture propre que lorsque le contenu est porté par une app lancée par Meeting Mode.
- Une URL ou un fichier ouvert dans une app déjà en cours d'exécution ne doit pas être présenté comme proprement fermable si cela implique de viser un onglet ou un document arbitraire.
- L'idée d'une fenêtre Safari dédiée, séparée du contexte Safari préexistant, reste une exploration UX future et non un comportement validé aujourd'hui.

**Suite éventuelle**
- Garder le wording des actions principales sur `Préparer le Mac` et `Rétablir le Mac`.
- Explorer plus tard l'idée Safari d'une fenêtre dédiée séparée du contexte préexistant, comme piste UX et non comme comportement validé.

**Fichiers concernés**
- `MeetingMode/Models/SessionSnapshot.swift`
- `MeetingMode/Services/SessionRunner.swift`
- `MeetingMode/Services/AppLauncherService.swift`
- `MeetingMode/Services/RestoreService.swift`
- `MeetingMode/Views/MenuBar/MenuBarContentView.swift`
- `MeetingMode/Resources/`
- `docs/DECISIONS.md`
- `docs/PROJECT_STATUS.md`
- `docs/README.md` si le dépôt garde la doc sous `docs/`

**Dépendances éventuelles**
- Étape 8 terminée
- Snapshot de session persistant déjà en place
- Aucun ajout de dépendance externe

**Critère de validation**
- Le snapshot ou le tracking associé enregistre les URLs et fichiers ouverts par la session courante avec le contexte cible utile
- Le restore ne revendique une fermeture propre que quand le contenu est porté par une app lancée par Meeting Mode
- Le restore reste honnête sur les URLs qui peuvent rester ouvertes
- Le restore reste honnête sur les fichiers locaux qui ne peuvent pas encore être fermés proprement
- Aucun glissement vers la gestion avancée des fenêtres, onglets ou documents arbitraires

**Hors périmètre explicite**
- Fermeture fiable d'un onglet ou d'un document précis dans une app déjà ouverte
- Restore parfait de l'état de navigation ou de documents
- AppleScript profond, ScriptingBridge, automation inter-apps profonde

## V3 — Release App Store

**Recommandation nette**
- Faisable, mais c'est une vraie V3 de distribution, pas une simple formalité. Le compromis produit principal est clair : en sandbox App Store, le restore ne doit plus tenter de quitter des apps tierces via `terminate()` / `forceTerminate()`.

**Objectif**
- Rendre l'app publiable sur le Mac App Store
- Conserver le cœur produit : presets, launch, hide, overlay, restore simple
- Adapter explicitement le produit aux contraintes sandbox

**Décision produit**
- Le restore App Store devient : réafficher ce que Meeting Mode a masqué, retirer l'overlay, nettoyer l'état de session
- La fermeture automatique d'apps tierces lancées par la session est retirée de la promesse produit App Store
- L'ouverture persistante d'apps et fichiers sélectionnés par l'utilisateur repose sur des security-scoped bookmarks

**Approche technique recommandée**
1. activer une branche de travail sandboxée et valider le flux réel dans une build `ENABLE_APP_SANDBOX = YES`
2. migrer `launchApplication(at:...)` vers `openApplication(at:configuration:completionHandler:)`
3. refactorer le modèle `Preset` pour stocker des security-scoped bookmarks pour :
   - fichiers locaux
   - apps sélectionnées via `NSOpenPanel`
4. ajouter la résolution et l'accès `startAccessingSecurityScopedResource()` au moment de l'ouverture
5. retirer `terminate()` / `forceTerminate()` du restore App Store et ajuster la copie UI
6. tester explicitement `hide()` / `unhide()` / `activate()` dans une build sandboxée réelle
7. préparer la fiche de release App Store avec wording exact sur les permissions et limites

**Fichiers concernés**
- `MeetingMode.xcodeproj`
- `MeetingMode/*.entitlements`
- `MeetingMode/Models/Preset.swift`
- `MeetingMode/Models/PresetApp.swift`
- `MeetingMode/Services/PresetStore.swift`
- `MeetingMode/Services/AppLauncherService.swift`
- `MeetingMode/Services/RestoreService.swift`
- `MeetingMode/Views/Presets/`
- `MeetingMode/Views/MenuBar/MenuBarContentView.swift`
- `docs/SANDBOX_AUDIT.md`
- `docs/DECISIONS.md`
- `docs/PROJECT_STATUS.md`

**Dépendances éventuelles**
- V2 cadrée ou explicitement repoussée si elle dépend encore du quit d'apps tierces
- Entitlements App Store validés
- Migration de données locale pour presets existants stockés en chemins bruts

**Critère de validation**
- Build sandboxée fonctionnelle avec `ENABLE_APP_SANDBOX = YES`
- Les presets existants migrent ou échouent proprement vers le nouveau format bookmark
- Les apps et fichiers sélectionnés par l'utilisateur s'ouvrent encore après relance
- Le masquage / réaffichage fonctionne réellement dans la build sandboxée
- Le restore App Store ne tente plus d'envoyer de quit interdit à des apps tierces
- L'app passe signature, notarization, archive et préparation App Store sans incohérence documentaire

**Hors périmètre explicite**
- Contournement via AppleScript pour retrouver un quit automatique complet
- Gestion avancée des fenêtres
- Sync cloud ou autres élargissements de scope profitant du chantier sandbox

## Résumé de séquencement

1. ~~Stabiliser les raccourcis clavier configurables~~ ✓
2. ~~Stabiliser toutes les chaînes visibles et la langue FR / EN~~ ✓
3. ~~Faire seulement ensuite la passe visuelle~~ ✓
4. ~~Onboarding, icône d'app, launch at login~~ ✓
5. ~~Testabilité SessionRunner + tests unitaires PresetStore et SessionRunner~~ ✓
6. ~~Nettoyage des textes du tutoriel (ton utilisateur, pas développeur)~~ ✓
7. ~~Fiabilisation : persistance snapshot sur crash, correction état overlay au relaunch, multi-screen overlay~~ ✓
8. Build Release local stable pour test manuel externe
9. V2 : attribution du contenu ouvert, puis restore plus honnête sur les URLs et fichiers
10. V3 : migration sandbox et release App Store

La suite recommandée est donc : **Release `.app` local d'abord pour le test manuel externe**, **V2 ensuite pour élargir le restore sans magie**, puis **V3 App Store** avec compromis produit explicites.
