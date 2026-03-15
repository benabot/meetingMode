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
- [x] Garder les services `AppLauncherService`, `OverlayService`, `RestoreService` et `SessionRunner` simples et lisibles
- [x] Mettre à jour `PROJECT_STATUS.md` et `DECISIONS.md` à chaque changement de comportement visible

## Ensuite

- [x] Remplacer les presets de démonstration par une source de données locale simple
- [ ] Ajouter une création/édition minimale de preset, sans interface lourde
- [ ] Étendre `Preset` pour couvrir proprement apps, URLs, fichiers locaux, checklist et clean screen
- [ ] Garder une seule session active à la fois, de manière explicite dans l'UI et les services
- [ ] Définir un snapshot minimal de session pour préparer un restore best effort
- [ ] Ouvrir apps, URLs et fichiers avec les APIs macOS les plus simples et fiables

## Plus tard

- [ ] Ajouter un clean screen overlay simple, sans gestion multi-fenêtre avancée
- [ ] Ajouter un restore simple qui ne restaure que ce que Meeting Mode a changé
- [ ] Ajouter un messaging de permissions plus précis si l'automation inter-apps devient réelle
- [ ] Ajouter une persistance locale robuste pour les presets et le preset sélectionné
- [ ] Faire une passe de polish UI minimale sur la menu bar et Settings

## Risques / points de vigilance

- [ ] Ne pas promettre de restore parfait en v1
- [ ] Ne pas implémenter de gestion avancée des fenêtres ou des onglets
- [ ] Ne pas dépendre d'automations inter-apps fragiles sans feedback utilisateur clair
- [ ] Ne pas bloquer les flux simples derrière des permissions non encore nécessaires
- [ ] Ne restaurer que les actions réellement déclenchées par Meeting Mode
- [ ] Garder le périmètre sans cloud, sans IA et sans intégrations profondes
- [ ] Garder la documentation synchronisée avec l'état réel du code

## Définition de terminé pour le socle actuel

- [ ] Le projet ouvre dans Xcode et build sans erreur
- [ ] L'app fonctionne comme menu bar app macOS uniquement
- [ ] Les états vides sont explicites et propres
- [ ] La session active / inactive est visible et réversible dans l'UI
- [ ] Les permissions restent en stub, sans faux comportement système
- [ ] Les docs décrivent fidèlement ce qui est implémenté et ce qui reste en stub
