# CLAUDE.md

## Recommandation nette

Utilise ce fichier comme **porte d’entrée pour Claude**, mais **pas comme source unique de vérité**.
Il doit être lu **avec** les autres fichiers projet, pas à leur place.

Ordre de lecture recommandé :
1. `README.md` — vision produit, périmètre MVP, comportement cible `Start Session` / `Restore Session`
2. `PROJECT_STATUS.md` — état réel du code, ce qui marche déjà, ce qui reste fragile ou incomplet
3. `DECISIONS.md` — décisions prises, arbitrages validés, choses à ne pas rediscuter sans raison concrète
4. `ROADMAP.md` — séquencement produit et technique
5. `TODO.md` — travaux restants et critères opérationnels encore ouverts
6. `AGENTS.md` — règles d’exécution pour faire des changements propres et minimaux
7. `XCODE_SETUP.md` — ouverture projet, schéma, build
8. `CHATGPT_PROJECT_INSTRUCTIONS.md` — cadre de réponse et priorités de travail

**Règle ferme :** en cas de divergence, considère `PROJECT_STATUS.md` et `DECISIONS.md` comme plus fiables que ce résumé.

---

## Projet

**Meeting Mode** est une app macOS de barre de menu qui prépare un Mac pour une réunion, une démo, un entretien ou un partage d’écran.

But produit, volontairement étroit :
- lancer rapidement un preset de réunion
- ouvrir un petit ensemble d’apps, d’URLs et de fichiers locaux
- masquer, en best effort, les apps gênantes ou privées
- afficher un overlay de “clean screen”
- restaurer ensuite un état de travail pratique, sans promettre de magie système

Références principales :
- `README.md`
- `CHATGPT_PROJECT_INSTRUCTIONS.md`
- `AGENTS.md`

---

## État réel du projet

À la date documentée dans `PROJECT_STATUS.md` (**2026-03-15**), le projet n’est pas au stade idée : le socle MVP fonctionne déjà.

### Déjà en place
- app macOS only
- Swift + SwiftUI, avec petits ponts AppKit quand nécessaire
- vraie menu bar app en mode background-only
- implémentation runtime actuelle en `NSStatusItem` + `NSPopover`
- presets locaux avec création, édition, suppression et persistance
- sélection du preset persistée
- ouverture d’apps, d’URLs et de fichiers locaux
- masquage best effort des apps visibles hors preset actif
- overlay de clean screen simple et indépendant
- session active unique
- restore best effort limité à ce que Meeting Mode a réellement modifié
- raccourcis clavier configurables `Start Session` / `Restore Session`
- réglage `Launch at login`
- UI FR / EN avec choix explicite de langue
- tutorial léger de premier lancement
- persistance locale simple, sans dépendances tierces

### Validé explicitement
- le flux MVP de base est end-to-end depuis la menu bar
- le preset seed `Quick Test` permet de tester le flux sans setup manuel lourd
- `Restore Session` réaffiche seulement les apps réellement masquées par la session courante
- la logique de restore d’app visibilité a été revalidée sur la machine de test avec `Safari` et `Notes`

### Pas encore implémenté ou non fiabilisé
- restore des URLs ouvertes
- restore des fichiers ouverts
- gestion avancée des fenêtres
- gestion parfaite des onglets, Spaces, bureaux ou états exacts des fenêtres
- validation suffisamment fiable de fermeture automatique de certaines apps document-based lancées par la session
- multi-screen overlay

Références principales :
- `PROJECT_STATUS.md`
- `TODO.md`

---

## Périmètre produit

### Inclus en v1
- app macOS uniquement
- menu bar app
- presets
- ouverture d’apps
- masquage d’apps
- ouverture d’URLs et de fichiers locaux
- clean screen overlay
- checklist pré-call
- restore simple et fiable
- persistance locale

### Hors périmètre sauf demande explicite
- gestion avancée des fenêtres
- restauration parfaite de toutes les fenêtres et de tous les onglets
- sync cloud
- IA
- analytics
- intégrations profondes Slack / Zoom / Teams / Calendar
- grosse refonte d’architecture
- fonctionnalités vagues de productivité générale

Références principales :
- `README.md`
- `AGENTS.md`
- `CHATGPT_PROJECT_INSTRUCTIONS.md`

---

## Règles produit à respecter

Classement des priorités :
1. fiabilité
2. simplicité
3. rapidité d’usage
4. clarté du restore
5. finition visuelle

Règles fermes :
- ne pas promettre un restore parfait
- ne restaurer que ce que Meeting Mode a réellement changé
- ne pas simuler un “grand nettoyage” en fermant tout
- ne pas dériver vers un gestionnaire de fenêtres
- garder une seule session active à la fois
- rester honnête sur les limites macOS et les permissions

Références principales :
- `README.md`
- `DECISIONS.md`
- `CHATGPT_PROJECT_INSTRUCTIONS.md`

---

## Architecture attendue

Préférence technique :
- **SwiftUI d’abord**
- **AppKit seulement si nécessaire**
- services séparés pour launch, overlay, restore et permissions
- persistance locale simple avant toute sophistication
- pas de dépendance externe sans raison solide

Structure logique attendue :
- `Models/`
- `Services/`
- `Views/`
- `Utilities/`
- `Resources/`
- `docs/`

Services typiques cohérents avec le projet :
- `PresetStore`
- `SessionRunner`
- `RestoreService`
- `OverlayService`
- `PermissionService`
- `AppLauncherService`
- `HotkeyService`
- `AppLanguageService`

Références principales :
- `AGENTS.md`
- `CHATGPT_PROJECT_INSTRUCTIONS.md`
- `DECISIONS.md`

---

## Comportement fonctionnel visé

### Start Session
Quand l’utilisateur lance une session, le comportement visé est :
1. lancer les apps du preset
2. ouvrir les URLs et fichiers du preset
3. masquer en best effort les apps visibles hors preset
4. afficher l’overlay de clean screen si demandé
5. marquer la session comme active et enregistrer un snapshot minimal de ce que l’app a réellement changé

### Restore Session
Quand l’utilisateur restaure, le comportement visé est :
1. masquer l’overlay
2. restaurer seulement ce que Meeting Mode a réellement changé pendant la session courante
3. quitter en best effort uniquement les apps lancées par Meeting Mode si elles entrent dans le scope de restore
4. réafficher uniquement les apps que Meeting Mode a effectivement masquées
5. vider l’état de session active

Important :
- restore best effort seulement
- pas de promesse sur fenêtres, onglets, Spaces ou minimisation exacte
- pas de magie système cachée

Références principales :
- `README.md`
- `PROJECT_STATUS.md`
- `DECISIONS.md`

---

## Décisions techniques déjà prises

Ne reviens pas dessus sans raison concrète.

### Forme de l’app
- `MenuBarExtra` n’est pas la solution retenue pour le runtime actuel
- l’implémentation actuelle repose sur `NSStatusItem` + `NSPopover`
- l’app est `LSUIElement = YES` et reste hors du Dock une fois lancée
- le target MVP n’est **pas sandboxé** pour l’instant afin de garder un comportement de launch / hide / restore prévisible pendant le développement

### Persistance
- persistance locale simple
- JSON local pour les presets
- `UserDefaults` ou équivalent léger pour sélection courante et préférences simples
- pas de Core Data, pas de SwiftData à ce stade

### Hotkeys
- deux raccourcis seulement : `Start Session` et `Restore Session`
- capture dans `Settings`
- conflit évident bloqué : les deux actions ne peuvent pas partager le même raccourci
- les hotkeys doivent appeler les mêmes entry points que l’UI, sans logique parallèle

### Localisation
- seulement FR et EN dans cette passe
- choix de langue explicite dans `Settings`
- persistance locale du choix
- toutes les chaînes visibles importantes doivent suivre ce choix

### Restore
- scope strictement limité aux changements réellement faits pendant la session en cours
- les apps déjà ouvertes avant la session ne doivent pas être fermées par restore
- le restore de visibilité tente d’abord l’app exacte trackée, puis fallback plus large seulement pour compatibilité / anciens snapshots
- URLs et fichiers sont ouverts simplement, mais pas refermés en v1

Références principales :
- `DECISIONS.md`
- `PROJECT_STATUS.md`

---

## Séquencement roadmap à respecter

Le projet a déjà acté cet ordre :
1. raccourcis clavier configurables
2. multilingue FR + EN
3. passe visuelle “liquid glass” minimale

Consigne importante : le polish visuel ne doit jamais passer avant la stabilité fonctionnelle et la clarté d’état.

Références principales :
- `ROADMAP.md`
- `PROJECT_STATUS.md`
- `DECISIONS.md`

---

## Contraintes macOS à traiter honnêtement

Quand une limite vient du système, il faut la dire clairement.

Points sensibles :
- permissions macOS
- automation inter-apps potentiellement fragile
- visibilité réelle des apps pas toujours parfaitement contrôlable
- comportement de quit sur certaines apps document-based
- restore jamais parfaitement garanti

Ne contourne pas ces limites avec des promesses produit irréalistes.

Références principales :
- `README.md`
- `AGENTS.md`
- `DECISIONS.md`
- `CHATGPT_PROJECT_INSTRUCTIONS.md`

---

## Règles de travail pour Claude

Quand tu proposes un changement :
1. lis les fichiers du projet concernés avant de conclure
2. reste strictement dans le périmètre demandé
3. fais le plus petit changement correct
4. préfère une solution robuste, réversible et testable
5. évite les abstractions prématurées
6. n’ajoute pas de dépendance sans justification solide
7. dis explicitement ce qui est validé, ce qui est hypothétique et ce qui dépend de macOS

Quand tu réponds :
- commence par la recommandation nette
- sépare **produit**, **technique** et **limites**
- évite le blabla
- classe les options si plusieurs existent
- pour le code, donne de petits extraits directement réutilisables
- explique où va chaque fichier

Références principales :
- `AGENTS.md`
- `CHATGPT_PROJECT_INSTRUCTIONS.md`

---

## Quand on te demande une roadmap

Réponds par petites étapes séquentielles avec, pour chaque étape :
- objectif
- fichiers concernés
- dépendances éventuelles
- critère de validation

Références principales :
- `ROADMAP.md`
- `CHATGPT_PROJECT_INSTRUCTIONS.md`
- `TODO.md`

---

## Quand on te demande du code

Avant de générer beaucoup de code :
- propose d’abord la structure minimale
- garde la solution testable
- évite les abstractions prématurées
- n’invente pas de comportements non demandés

Références principales :
- `AGENTS.md`
- `CHATGPT_PROJECT_INSTRUCTIONS.md`
- `DECISIONS.md`

---

## Fichiers de référence et usage attendu

### `README.md`
À utiliser pour :
- comprendre le but produit
- connaître le périmètre MVP
- retrouver le comportement fonctionnel visé

### `PROJECT_STATUS.md`
À utiliser pour :
- savoir ce qui est vraiment implémenté aujourd’hui
- éviter de parler au futur d’une fonctionnalité déjà faite
- identifier ce qui reste partiel, fragile ou explicitement non validé

### `DECISIONS.md`
À utiliser pour :
- connaître les arbitrages déjà pris
- éviter de rouvrir inutilement des choix stabilisés
- comprendre les compromis sur runtime, persistance, restore et UX

### `ROADMAP.md`
À utiliser pour :
- proposer les prochaines étapes dans le bon ordre
- ne pas pousser du polish ou de nouveaux sujets avant les fondations

### `TODO.md`
À utiliser pour :
- voir ce qui reste ouvert
- vérifier la définition de terminé du socle actuel
- ne pas inventer des travaux déjà listés autrement

### `AGENTS.md`
À utiliser pour :
- guider la manière de modifier le code
- rester minimal, réversible et reviewable
- garder le projet dans sa forme MVP

### `XCODE_SETUP.md`
À utiliser pour :
- ouvrir le bon projet
- lancer les bonnes commandes de build
- éviter les erreurs de chemin ou de scheme

### `CHATGPT_PROJECT_INSTRUCTIONS.md`
À utiliser pour :
- respecter le ton et le cadre de réponse attendus
- garder les priorités produit et techniques visibles
- structurer les roadmaps et propositions de code

---

## Commandes utiles

Découvrir le projet / schémas :
```bash
xcodebuild -list
```

Build macOS :
```bash
xcodebuild -scheme MeetingMode -destination 'platform=macOS' build
```

Chemin projet documenté :
```bash
open /Users/benoitabot/Sites/meetingMode/MeetingMode.xcodeproj
```

Référence :
- `XCODE_SETUP.md`

---

## Résumé opérationnel pour Claude

Meeting Mode n’est pas un “workspace manager”.
C’est un petit utilitaire macOS de menu bar centré sur un flux unique :
**préparer une session, nettoyer visuellement l’écran, puis restaurer de façon compréhensible ce que l’app a réellement modifié.**

La bonne direction n’est pas d’ajouter de la magie.
La bonne direction est de rendre le flux actuel plus fiable, plus explicite et plus honnête vis-à-vis des limites de macOS.

Et surtout :
- lis les fichiers de référence avant de proposer un changement
- prends `PROJECT_STATUS.md` pour l’état réel
- prends `DECISIONS.md` pour les choix déjà actés
- traite ce `CLAUDE.md` comme un résumé de travail, pas comme la seule source de vérité
