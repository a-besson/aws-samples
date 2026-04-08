# Règles: Pre-commit & Qualité

Cette règle impose des vérifications de qualité et de sécurité locales inviolables sur chaque projet de l'entreprise.

## Standards Obligatoires

1. **Usage Systématique** : Tout dossier de projet (et particulièrement Terraform) doit impérativement être contrôlé via `pre-commit`.
2. **Configuration Standard** : Un fichier `.pre-commit-config.yaml` doit être présent à la racine du projet, reprenant tes standards DevOps.
3. **Hooks Exigés** :
   - *Général* : `check-yaml`, `check-added-large-files`, `check-json`, `trailing-whitespace`, `detect-private-key`
   - *Sécurité (Tolérance Zéro)* : `gitleaks` (Impératif absolu pour ne laisser passer aucun secret en clair)
   - *Terraform* : `terraform_fmt`, `terraform_validate`, `terraform_docs` (pour la génération automatique d'un `TFDOCS.md`), `terraform_tflint`
4. **Validation avant Finition** : Aucune tâche de code ne peut être annoncée comme "terminée" tant que la commande `pre-commit run --all-files` n'est pas exécutée et ne passe pas avec succès.
