# Règles: Orchestration Taskfile

Cette règle définit le standard obligatoire pour l'orchestration locale des commandes.

## Standards Obligatoires

1. **Zéro Makefile** : L'utilisation et la génération de fichiers `Makefile` sont strictement interdites. L'orchestration doit se faire exclusivement via un fichier `Taskfile.yml` (voir https://taskfile.dev).
2. **Version** : Tout `Taskfile.yml` doit commencer par la structure `version: '3'`.
3. **Variables Centralisées** : Toutes les entrées globales doivent être définies proprement dans un bloc `vars:` (utilisation avec la syntaxe `{{.VAR_NAME}}`).
4. **Auto-documentation (Descriptions)** : Chaque tâche `task:` doit inclure une propriété `desc:` explicite. Ceci est essentiel pour que l'aide `task --list` soit parfaitement lisible.
5. **Dépendances Explicites** : Toujours utiliser la propriété `deps:` pour chaîner les tâches requises (`deps: [task1, task2]`) plutôt que de les appeler dans cmds.
6. **Execution Directory** : Favoriser l'usage de l'attribut `dir: <path>` dans la config de la tâche plutôt que de passer un `cd <path> && <command>` en bash.
