# SANDBOX_AUDIT.md — Meeting Mode v0.1

> Analyse statique produite le 2026-03-18. Aucun fichier modifié.
> Objectif : évaluer le coût réel d'un `ENABLE_APP_SANDBOX = YES` en vue d'une distribution App Store.

---

## 1. Audit par service

### 1.1 AppLauncherService.swift

| API exacte | Sandbox sans entitlement | Entitlement si nécessaire | Alternative sandbox-compatible | Impact produit si dégradé |
|---|---|---|---|---|
| `NSWorkspace.shared.launchApplication(at:options:configuration:)` — ligne 87 | **Partiel** — API dépréciée depuis macOS 10.15 ; fonctionne encore mais le comportement sandbox n'est pas documenté officiellement | — | `NSWorkspace.shared.openApplication(at:configuration:completionHandler:)` — API moderne, permise en sandbox | Faible : simple remplacement d'API |
| `NSWorkspace.shared.open(_ url:)` pour URLs HTTP/HTTPS — ligne 111 | **Oui** | — | Identique | Aucun |
| `NSWorkspace.shared.open(_ fileURL:)` pour fichiers locaux — ligne 126 | **Partiel** — accès accordé pendant la session NSOpenPanel uniquement ; les chemins bruts stockés en JSON **ne survivent pas** à un relaunch en sandbox | `com.apple.security.files.user-selected.read-write` + security-scoped bookmarks | Stocker `NSURL.bookmarkData(options: .withSecurityScope, ...)` à la place du chemin brut | **Moyen** : l'ouverture de fichiers depuis des presets persistés échoue silencieusement après redémarrage |
| `NSWorkspace.shared.runningApplications` — lignes 58, 178 | **Oui** | — | Identique | Aucun |
| `NSWorkspace.shared.urlForApplication(withBundleIdentifier:)` — ligne 133 | **Oui** | — | Identique (chemin recommandé en sandbox) | Aucun |
| `NSRunningApplication.terminate()` — ligne 202 | **NON** | Aucun entitlement ne couvre cela | AppleScript via `NSUserAppleScriptTask` ou `NSAppleScript` + entitlement `com.apple.security.automation.apple-events` | **Critique** : le restore ne peut plus quitter les apps lancées par la session |
| `NSRunningApplication.forceTerminate()` — ligne 211 | **NON** | Aucun | Idem ci-dessus — ou abandon de la feature | **Critique** : même que terminate() |
| `FileManager.fileExists` sur `/Applications`, `/System/Applications` — lignes 155-171 | **Oui** — lecture de métadonnées sur ces répertoires standard est autorisée en sandbox | — | Identique | Aucun |
| `fileManager.homeDirectoryForCurrentUser` pour `~/Applications` — ligne 160 | **Partiel** — accès lecture au home hors container nécessite un entitlement | `com.apple.security.files.user-selected.read-only` | Supprimer `~/Applications` du lookup ou demander entitlement | Faible : peu d'apps installées là |

**Verdict AppLauncherService** : 2 bloqueurs critiques (`terminate`, `forceTerminate`), 1 refactoring requis (security-scoped bookmarks pour les fichiers).

---

### 1.2 AppVisibilityService.swift

| API exacte | Sandbox sans entitlement | Entitlement si nécessaire | Alternative | Impact produit |
|---|---|---|---|---|
| `NSWorkspace.shared.runningApplications` — ligne 46 | **Oui** | — | Identique | Aucun |
| `NSRunningApplication.hide()` — ligne 66 | **Probablement oui** — passe par le window server (XPC), pas par un signal direct. Non documenté comme restreint par Apple. Aucun entitlement connu requis. **À vérifier impérativement sur une build sandbox réelle.** | — | Identique | **Critique si bloqué** : toute la feature masquage disparaît |
| `NSRunningApplication.unhide()` — ligne 240 | **Probablement oui** — même mécanique que hide() | — | Identique | **Critique si bloqué** : le restore de visibilité échoue |
| `NSRunningApplication.activate(options: [.activateAllWindows])` — ligne 243 | **Probablement oui** — opération window server de haut niveau, utilisée par des apps App Store | — | Identique | Moyen : restore moins fluide |
| `NSWorkspace.shared.openApplication(at:configuration:completionHandler:)` — ligne 269 (fallback restore) | **Oui** — API moderne, autorisée en sandbox | — | Identique | Aucun |
| `NSRunningApplication.isHidden` (lecture) — ligne 213 | **Oui** | — | Identique | Aucun |

**Verdict AppVisibilityService** : Aucun bloqueur certain. `hide()` et `unhide()` sont probablement compatibles sandbox (utilisés par des apps Mac App Store) mais **doivent être testés** dans une build sandboxée réelle avant de conclure. C'est le risque résiduel principal de ce service.

---

### 1.3 RestoreService.swift

Service orchestrateur pur — délègue à `AppLauncherService`, `AppVisibilityService`, `OverlayService`. Aucune API système directe propre. Les bloqueurs de ce service sont ceux de ses dépendances (voir 1.1 et 1.4).

---

### 1.4 HotkeyService.swift

| API exacte | Sandbox sans entitlement | Entitlement si nécessaire | Alternative | Impact produit |
|---|---|---|---|---|
| `import Carbon` — ligne 2 | **Oui** — le framework Carbon est autorisé en sandbox | — | — | Aucun |
| `GetApplicationEventTarget()` — lignes 362, 399 | **Oui** | — | — | Aucun |
| `InstallEventHandler(GetApplicationEventTarget(), ...)` — ligne 361 | **Oui** — event handler scoped à l'application | — | — | Aucun |
| `RegisterEventHotKey(...)` — ligne 395 | **Oui, confirmé** — contrairement à la note de `DECISIONS.md`, `RegisterEventHotKey` fonctionne dans les apps Mac App Store. La librairie open-source `KeyboardShortcuts` (sindresorhus, > 4000 étoiles, App Store-compatible déclarée) l'utilise en interne. La restriction sandbox couvre `CGEventTap` (monitoring clavier global via Accessibility), **pas** `RegisterEventHotKey` qui passe par le window server. | — | Si malgré tout rejeté en Review : remplacer par la lib `KeyboardShortcuts` | **Important si bloqué** : perte des raccourcis globaux |
| `UnregisterEventHotKey(...)` — ligne 417 | **Oui** | — | — | Aucun |
| `UserDefaults.standard` (persistance shortcuts) — ligne 262 | **Oui** | — | Identique | Aucun |

**Verdict HotkeyService** : Pas de bloqueur avéré. La note de `DECISIONS.md` sur Carbon/`RegisterEventHotKey` est probablement incorrecte — c'est une fausse croyance courante. La confusion vient de `CGEventTap` (bloqué en sandbox, nécessite Accessibility) vs `RegisterEventHotKey` (autorisé, passe par le window server comme une API opt-in déclarative). Si Apple Review pose un problème, la migration vers `KeyboardShortcuts` est straightforward (< 1 jour).

---

### 1.5 OverlayService.swift

| API exacte | Sandbox sans entitlement | Entitlement | Alternative | Impact produit |
|---|---|---|---|---|
| `NSScreen.screens` — ligne 22 | **Oui** | — | Identique | Aucun |
| `NSWindow` création/configuration — lignes 33-56 | **Oui** — propres fenêtres de l'app | — | Identique | Aucun |
| `window.orderFrontRegardless()` — lignes 18, 55 | **Oui** | — | Identique | Aucun |
| `window.collectionBehavior = [.canJoinAllSpaces]` — ligne 49 | **Oui** | — | Identique | Aucun |
| `NSHostingView(rootView:)` — ligne 51 | **Oui** | — | Identique | Aucun |

**Verdict OverlayService** : **100% compatible sandbox**. Aucune modification requise.

---

### 1.6 PresetStore.swift

| API exacte | Sandbox sans entitlement | Entitlement | Alternative | Impact produit |
|---|---|---|---|---|
| `FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)` — ligne 141 | **Oui** — en sandbox, retourne automatiquement `~/Library/Containers/<bundleID>/Data/Library/Application Support/` | — | Identique | Aucun |
| `FileManager.default.createDirectory(at:...)` — ligne 113 | **Oui** — dans le container | — | Identique | Aucun |
| `Data(contentsOf: storageURL)` — ligne 127 | **Oui** — fichier dans le container | — | Identique | Aucun |
| `data.write(to: storageURL, options: .atomic)` — ligne 256 | **Oui** — dans le container | — | Identique | Aucun |
| `UserDefaults.standard` — ligne 18 | **Oui** — UserDefaults est sandboxé proprement | — | Identique | Aucun |
| Migration `legacySandboxURL` — lignes 139-155 | **Note** : le chemin hardcodé `~/Library/Containers/fr.beabot.meetingmode/...` est précisément le container sandbox — cette migration est prévue pour le cas où l'app devient sandboxée après avoir fonctionné sans. La logique est correcte. | — | — | Aucun |

**Verdict PresetStore** : **100% compatible sandbox**. La migration vers le container est déjà anticipée dans le code.

---

### 1.7 LaunchAtLoginService.swift

| API exacte | Sandbox sans entitlement | Entitlement | Alternative | Impact produit |
|---|---|---|---|---|
| `SMAppService.mainApp` — ligne 47 | **Oui** — `SMAppService` a été spécifiquement conçu pour remplacer les anciens mécanismes non-sandbox-compatibles | — | Identique | Aucun |
| `appService.register()` — ligne 71 | **Oui** | — | Identique | Aucun |
| `appService.unregister()` — ligne 73 | **Oui** | — | Identique | Aucun |

**Verdict LaunchAtLoginService** : **100% compatible sandbox**. `SMAppService` est la voie moderne recommandée par Apple pour les apps sandboxées.

---

### 1.8 PresetEditorView.swift — NSOpenPanel

| API exacte | Sandbox sans entitlement | Entitlement | Alternative | Impact produit |
|---|---|---|---|---|
| `NSOpenPanel()` — lignes 357, 374 | **Oui** — conçu pour sandbox | — | Identique | Aucun |
| `panel.directoryURL = URL(fileURLWithPath: "/Applications")` — ligne 360 | **Oui** — le panel peut pointer n'importe où | — | Identique | Aucun |
| `panel.runModal()` — lignes 368, 382 | **Oui** | — | Identique | Aucun |
| `panel.urls` → `url.path` stocké comme `String` dans le Preset — ligne 527 | **Bloqueur** — En sandbox, l'accès à un fichier hors container est accordé temporairement pendant la session NSOpenPanel. Stocker le chemin brut signifie que l'accès est **perdu après relaunch**. Il faut stocker un security-scoped bookmark (`Data`) et appeler `url.startAccessingSecurityScopedResource()` à chaque ouverture. | `com.apple.security.files.user-selected.read-write` (requis pour persister l'accès) | Stocker `url.bookmarkData(options: .withSecurityScope, ...)` dans le modèle `PresetApp.bundlePath` (pour les apps) et dans `filesToOpen` (pour les fichiers) | **Critique** : les fichiers et apps sélectionnés dans les presets ne sont plus accessibles après relaunch |
| `Bundle(url: url)` pour lire `CFBundleDisplayName` — ligne 570 | **Oui** — pendant la session panel | — | Identique | Aucun |

**Verdict NSOpenPanel** : La sélection elle-même est compatible sandbox. Le vrai problème est en aval : les paths bruts (`String`) doivent devenir des security-scoped bookmarks (`Data`) dans le modèle `Preset`.

---

## 2. Résumé par fonctionnalité produit

| Fonctionnalité | API(s) utilisée(s) | Impact sandbox |
|---|---|---|
| **Lancer des apps** | `NSWorkspace.shared.launchApplication(at:...)` (déprécié) → remplacer par `openApplication(at:...)` | Compatible après remplacement d'API. Les paths d'apps venant de NSOpenPanel nécessitent security-scoped bookmarks pour survivre au relaunch. |
| **Masquer des apps** | `NSRunningApplication.hide()` | Probablement compatible (window server, pas signal). **Doit être testé en sandbox.** |
| **Quitter des apps (restore)** | `NSRunningApplication.terminate()` + `forceTerminate()` | **BLOQUÉ** — impossible d'envoyer des signaux à des processus tiers en sandbox. Feature perdue ou remplacée par AppleScript. |
| **Ouvrir URLs** | `NSWorkspace.shared.open(_ url:)` | Compatible sans restriction. |
| **Ouvrir fichiers locaux** | `NSWorkspace.shared.open(_ fileURL:)` + chemins bruts | Compatible pendant la session. Chemins bruts non persistables → nécessite security-scoped bookmarks. Entitlement `com.apple.security.files.user-selected.read-write`. |
| **Hotkeys globaux** | Carbon `RegisterEventHotKey` | Compatible sandbox (confirmé par apps App Store tierces). Pas de migration requise. |
| **Overlay** | `NSWindow`, `NSScreen.screens` | **100% compatible**. Aucun changement requis. |
| **Persistance locale** | JSON dans Application Support, `UserDefaults` | **100% compatible**. Le container sandbox accueille ces données sans modification. |
| **NSOpenPanel** | `NSOpenPanel.runModal()` → paths bruts | NSOpenPanel OK. Les paths bruts deviennent security-scoped bookmarks : refactoring modèle requis. |
| **Launch at login** | `SMAppService.mainApp` | **100% compatible**. API spécifiquement sandbox-native. |

---

## 3. Trois scénarios

### Scénario A — Sandbox strict, aucune temporary exception

**Ce qui survit :**
- Overlay → intact
- Launch at login → intact
- Hotkeys globaux → intact (probablement)
- Masquage d'apps → probablement intact (hide/unhide à vérifier)
- Ouverture d'URLs → intact
- Persistance presets/settings → intact
- NSOpenPanel (sélection) → intact pour la session courante

**Ce qui est perdu ou cassé :**
- Quit apps on restore → perdu (`terminate`/`forceTerminate` bloqués)
- Ouverture de fichiers après relaunch → cassé (paths bruts sans security-scoped bookmarks)
- Ouverture d'apps après relaunch si stocké par path uniquement → potentiellement cassé si l'accès au path n'est plus garanti (apps dans `~/Applications` notamment)

**Résultat produit :** La fonctionnalité principale (masquer des apps + overlay) survit probablement. Le restore est dégradé (plus de quit d'apps). Les fichiers dans les presets sont cassés entre sessions. Pas viable en l'état.

---

### Scénario B — Sandbox avec temporary exceptions

Les temporary exceptions pertinentes pour Meeting Mode :

| Exception | Usage | Probabilité d'acceptation Apple Review |
|---|---|---|
| `com.apple.security.files.user-selected.read-write` | Accès persistent aux fichiers sélectionnés via NSOpenPanel | **Élevée** — entitlement standard, très fréquent sur App Store |
| `com.apple.security.automation.apple-events` | Envoyer des events AppleScript pour quitter des apps tierces | **Moyenne** — accepté si chaque app cible est déclarée dans `Info.plist` sous `NSAppleEventsUsageDescription`. Apple demande une justification. Utilisé par Terminal, Script Editor, etc. |
| `com.apple.security.files.bookmarks.app-scope` | Stocker des security-scoped bookmarks persistants | **Élevée** — entitlement standard documenté |

**Ce que ces exceptions permettent de récupérer :**
- `user-selected.read-write` + `bookmarks.app-scope` → Fichiers persistants entre sessions
- `apple-events` → Quit des apps via AppleScript à la place de `terminate()`, **mais uniquement les apps explicitement déclarées dans Info.plist**

**Ce qui reste perdu même avec ces exceptions :**
- `forceTerminate()` → aucune exception ne couvre un kill brutal d'apps tierces
- L'énumération dynamique des apps à quitter (les apps changent selon le preset) complexifie la déclaration `NSAppleEventsUsageDescription`

**Effort :** 2–3 semaines. Refactoring modèle `Preset` (bookmarks), remplacement de `terminate()` par AppleScript, déclaration des cibles dans Info.plist.

**Risque Review :** `apple-events` peut être questionné par Apple si la liste des apps cibles est ouverte ou dynamique. Apple préfère des targets déclarés statiquement.

---

### Scénario C — Refactoring vers APIs sandbox-compatibles

Changements requis (sans temporary exceptions) :

| Changement | Fichier(s) concerné(s) | Effort | Compromis produit |
|---|---|---|---|
| Remplacer `launchApplication(at:...)` par `openApplication(at:configuration:completionHandler:)` | `AppLauncherService.swift` | 1h — simple remplacement d'API | Aucun |
| Implémenter security-scoped bookmarks pour les fichiers dans les presets | `PresetStore.swift`, `PresetEditorView.swift`, `AppLauncherService.swift`, modèle `Preset.swift` | **3–5 jours** — refactoring du modèle + migration des données existantes | Aucun visible utilisateur |
| Implémenter security-scoped bookmarks pour les apps sélectionnées par path | `PresetEditorView.swift`, modèle `PresetApp.swift`, `AppLauncherService.swift` | **2–3 jours** — similaire aux fichiers | Aucun visible utilisateur |
| Supprimer `terminate()` / `forceTerminate()` du restore | `AppLauncherService.swift`, `RestoreService.swift` | 2h — supprimer le code | **Restore ne quitte plus les apps lancées.** L'utilisateur doit les fermer manuellement. |
| Vérifier `hide()`/`unhide()`/`activate()` sur une build sandbox | `AppVisibilityService.swift` | 1 jour de test | Aucun si ça fonctionne |
| Carbon hotkeys — aucun changement requis *a priori* | `HotkeyService.swift` | 0 | Aucun |

**Effort total estimé : ~10 jours** de développement + tests.

**Compromis produit :**
- Le restore ne quitte plus les apps lancées par la session. C'est une vraie dégradation fonctionnelle : l'utilisateur voit ses "session apps" rester ouvertes après restore.
- Toutes les autres fonctionnalités (masquage, overlay, hotkeys, fichiers, launch at login) survivent intactes ou avec changements transparents.

---

## 4. Recommandation nette

**Scénario C est le plus réaliste**, avec l'acceptation d'un compromis sur le quit des apps.

Voici pourquoi :

1. **`DECISIONS.md` a déjà tranché** : la distribution est directe (DMG), hors App Store, précisément à cause de ces contraintes. Cette décision est documentée et justifiée. Rouvrir ce sujet a un coût non nul.
2. **Le bloqueur technique le plus dur est `terminate()`** : aucun entitlement standard ne le couvre. Le workaround AppleScript (Scénario B) est complexe, dynamiquement difficile à déclarer dans Info.plist, et soumis à l'humeur de l'App Review. La probabilité de refus n'est pas négligeable.
3. **Les autres APIs sont soit compatibles sandbox, soit facilement migrables** : `RegisterEventHotKey` est un faux bloqueur. `hide()`/`unhide()` sont probablement ok. `SMAppService` et `OverlayService` sont déjà parfaits. Seuls les security-scoped bookmarks représentent un vrai chantier, mais c'est un refactoring propre sans compromis visible.
4. **Le compromis produit réel est limité** : "les apps lancées par la session ne se quittent pas automatiquement au restore" est une limitation claire et honnête, cohérente avec la philosophie "best effort" du projet.

**Si la distribution App Store devient un objectif explicite**, la séquence recommandée est :

```
Étape 1 (0,5j) — Activer ENABLE_APP_SANDBOX=YES sur une branche de test
Étape 2 (1j)   — Vérifier que hide()/unhide()/activate() fonctionnent réellement
Étape 3 (1j)   — Migrer launchApplication → openApplication
Étape 4 (3-5j) — Implémenter security-scoped bookmarks pour fichiers et apps
Étape 5 (0,5j) — Retirer terminate()/forceTerminate(), documenter la limite dans le tutorial
Étape 6 (1j)   — Tests de non-régression sur le flux complet en sandbox
```

**Durée totale estimée : ~10 jours.** Compatible avec la roadmap après la distribution DMG actuelle.

---

*Rapport basé sur une lecture statique du code — aucune build sandbox n'a été exécutée. Les points marqués "probablement" (notamment `hide()`/`unhide()`) doivent être vérifiés expérimentalement sur une build avec `ENABLE_APP_SANDBOX=YES` avant de conclure.*
