# Todo list


## Evolution de la structure du projet

Je veux reprendre la même structure que le projet gcp-samples

Tu dois créer un dossier `samples/` à la racine du projet.

Qui contiendra tous les exemples actuels (aurora-pg, ecs, msk-akhq, vpc).

Chaque exemple doit avoir sa propre structure avec un README.md et un TFDOCS.md et un Taskfile.yml.

Déplace les projets vpc et config dans un dossier base/ qui contiendra toutes les ressources qui peuvent être réutilisées par d'autres projets (vpc, config, etc...).

Ajoute des tests sur chaque stack.

Renome le projet ecs en ecs-service, et créé un projet ecs-task qui déploiera une ecs task definition et qui pourra être lancé via la console ou la cli comme un batch (task ecs).
