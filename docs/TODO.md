# TODO MVP

## Maintenant

- [x] Vérifier que le projet build depuis la racine avec `xcodebuild -scheme MeetingMode -destination 'platform=macOS' build`
- [x] Vérifier que l'app se lance comme vraie menu bar app, sans fenêtre principale inattendue
- [x] Vérifier que l'icône de barre de menu reste visible au lancement
- [x] Vérifier l'état vide `No presets yet` dans la menu bar quand aucun preset n'est disponible
- [x] Vérifier que `Start Session` n'est visible que lorsqu'un preset est sélectionnable
- [x] Vérifier que `Restore Session` reste désactivé hors session active
- [x] Vérifier le passage d'un état `inactive` vers `active`, puis retour `inactive` sans crash ni état bloqué
- [x] Garder `PermissionService` honnête : pas de fausses permissions, pas de messaging trompeur

## Ensuite

- [x] Remplacer les presets de démonstration par une source de données locale simple
- [x] Ajouter une création/édition minimale de preset, sans interface lourde
- [x] Étendre `Preset` pour couvrir proprement apps, URLs, fichiers locaux, checklist et clean screen
- [x] Simplifier la popover menu bar pour rendre l'état lisible immédiatement
- [x] Conserver le preset sélectionné après relance
- [x] Vérifier que create/edit de preset survivent proprement au redémarrage
- [x] Gérer proprement les données locales absentes ou invalides
- [x] Ajouter une suppression minimale de preset avec confirmation simple
- [x] Implémenter le masquage best effort des apps visibles qui ne font pas partie du preset actif
- [x] Définir précisément la règle de visibilité pendant la session : apps du preset visibles, apps hors preset masquées, limites macOS explicites
- [x] Étendre `SessionSnapshot` pour suivre uniquement les apps effectivement masquées par Meeting Mode
- [x] Étendre `RestoreService` pour ne réafficher que les apps effectivement masquées par Meeting Mode
- [x] Garder une seule session active à la fois, de manière explicite dans l'UI et les services
- [x] Définir un snapshot minimal de session pour préparer un restore best effort
- [x] Ouvrir apps, URLs et fichiers avec les APIs macOS les plus simples et fiables
- [x] Ajouter un clean screen overlay simple, sans gestion multi-fenêtre avancée
- [x] Ajouter un restore simple qui ne restaure que ce que Meeting Mode a changé

## Plus tard

- [ ] Ajouter un messaging de permissions plus précis si l'automation inter-apps devient réelle
- [x] Renforcer la persistance locale : snapshot de session persisté sur disque (active_session.json), rechargement au relaunch après crash, overlayWasShown corrigé au rechargement
- [x] Ajouter un sélecteur de fichiers local (NSOpenPanel pour apps et fichiers dans l'éditeur de preset, au lieu de saisie manuelle)
- [x] Faire une passe de polish UI minimale sur la menu bar et Settings (bouton delete discret, bouton restore disabled plus lisible, footer plus discret, plan detail sur 2 lignes)
- [ ] Étendre la couverture de tests aux services restants (RestoreService, AppVisibilityService, OverlayService) via les protocoles déjà en place
- [ ] Injecter une Clock testable dans SessionRunner pour couvrir les tâches async différées (scheduleVisibilityConfirmation, scheduleRestoreVisibilityConfirmation)
- [ ] Préparer la distribution : sandbox (ou justification de l'absence), signature, notarization
- [ ] Distribution App Store : implémenter security-scoped bookmarks (fichiers + apps), migrer `launchApplication` → `openApplication`, retirer `terminate`/`forceTerminate` (voir `docs/SANDBOX_AUDIT.md` — ~10 jours, à faire après la distribution DMG)

## Risques / points de vigilance

- [ ] Ne pas promettre de restore parfait en v1
- [ ] Ne pas fermer de force toutes les apps visibles pour simuler un “grand nettoyage”
- [ ] Accepter qu'une app document-based lancee par la session puisse rester ouverte apres une demande de quit poli
- [ ] Ne pas implémenter de gestion avancée des fenêtres ou des onglets
- [ ] Ne pas dépendre d'automations inter-apps fragiles sans feedback utilisateur clair
- [ ] Ne pas bloquer les flux simples derrière des permissions non encore nécessaires
- [ ] Ne restaurer que les actions réellement déclenchées par Meeting Mode
- [ ] Ne pas masquer ou réafficher des apps hors du scope réellement touché par Meeting Mode
- [ ] Garder le seed `Quick Test` minimal : un seul preset par défaut tant que l'utilisateur n'en crée pas d'autres
- [ ] Garder le périmètre sans cloud, sans IA et sans intégrations profondes
- [ ] Garder la documentation synchronisée avec l'état réel du code

## Définition de terminé pour le socle actuel

- [x] Le projet ouvre dans Xcode et build sans erreur
- [x] L'app fonctionne comme menu bar app macOS uniquement
- [x] Les états vides sont explicites et propres
- [x] La session active / inactive est visible et réversible dans l'UI
- [x] Le flux `Quick Test` permet de tester `Start Session`, l'overlay et le restore UI de bout en bout
- [x] La popover sépare clairement preset, session et actions
- [x] Le preset sélectionné survit à une relance
- [x] La création, l'édition et la suppression minimale de preset survivent à une relance
- [x] Les données locales absentes ou invalides retombent sur un état sûr
- [x] Revalider dans le flux UI réel que le démarrage d'une session masque bien les apps hors preset sans rendre le restore ambigu
- [x] Le snapshot de session distingue les apps lancées par Meeting Mode des apps seulement masquées par Meeting Mode
- [x] `Restore Session` ne réaffiche que les apps effectivement masquées par la session courante
- [ ] La fermeture automatique d'une app document-based lancée par Meeting Mode est suffisamment fiable pour être considérée comme validée
- [x] Les permissions restent en stub, sans faux comportement système
- [x] Les docs décrivent fidèlement ce qui est implémenté et ce qui reste en stub
- [x] PresetStore est couvert par 8 tests unitaires isolés
- [x] SessionRunner est couvert par 9 tests unitaires avec mocks
- [x] Les textes du tutoriel n'utilisent plus de jargon développeur (MVP, v1, règles MVP)


## V2 — Fermeture best effort des URLs et fichiers

### À faire

- [ ] Étendre `SessionSnapshot` pour tracer les URLs et fichiers ouverts par la session
- [ ] Distinguer dans le snapshot ce qui a été ouvert dans une app déjà en cours d'exécution vs une app lancée par Meeting Mode
- [ ] Réutiliser le scope de quit existant pour fermer les apps lancées par la session qui servent de support à une URL ou un fichier
- [ ] Ne pas tenter de fermer un onglet précis dans un navigateur déjà ouvert
- [ ] Ne pas tenter de fermer un document précis dans une app déjà ouverte
- [ ] Afficher dans le résultat de restore trois états séparés : fermé, resté ouvert, non fermable proprement
- [ ] Mettre à jour les textes FR + EN pour ne pas promettre de fermeture parfaite
- [ ] Ajouter des tests unitaires ciblés sur la nouvelle logique de snapshot et de restore
- [ ] Documenter explicitement la limite produit dans `README.md`, `DECISIONS.md` et `PROJECT_STATUS.md`

### Critère de terminé V2

- [ ] Les URLs et fichiers ouverts pendant la session sont tracés dans le snapshot
- [ ] Le restore ferme les apps lancées par Meeting Mode quand elles sont le support de ces ouvertures
- [ ] Le restore n'annonce jamais à tort qu'un onglet ou document précis a été fermé
- [ ] Le résultat utilisateur distingue clairement les cas réellement restaurés des limites macOS

## V3 — Release App Store

### À faire

- [ ] Créer une cible / configuration de validation sandboxée (`ENABLE_APP_SANDBOX = YES`)
- [ ] Migrer `launchApplication(at:...)` vers `openApplication(at:configuration:completionHandler:)`
- [ ] Ajouter les entitlements App Store nécessaires pour fichiers sélectionnés par l'utilisateur
- [ ] Refactorer `Preset` et `PresetApp` pour stocker des security-scoped bookmarks au lieu de chemins bruts
- [ ] Ajouter une migration locale depuis les presets existants basés sur chemins
- [ ] Appeler `startAccessingSecurityScopedResource()` / `stopAccessing...` au bon moment
- [ ] Retirer `terminate()` / `forceTerminate()` du restore dans la variante App Store
- [ ] Réécrire le messaging produit pour indiquer que le restore App Store ne ferme plus les apps tierces
- [ ] Vérifier `hide()` / `unhide()` / `activate()` sur une vraie build sandboxée
- [ ] Vérifier les raccourcis globaux dans la build sandboxée
- [ ] Valider ouverture d'apps et fichiers après relance avec bookmarks persistants
- [ ] Préparer signature, archive, notarization et soumission App Store
- [ ] Mettre à jour `SANDBOX_AUDIT.md`, `DECISIONS.md`, `PROJECT_STATUS.md` et `README.md` avec l'état réel

### Critère de terminé V3

- [ ] La build sandboxée couvre le flux réel start / hide / overlay / restore simple
- [ ] Les presets persistés restent utilisables après relance grâce aux bookmarks
- [ ] Le restore App Store ne tente plus de quitter d'app tierce
- [ ] La documentation décrit exactement les compromis de la version App Store
- [ ] L'archive App Store est prête sans divergence entre code, entitlements et doc
