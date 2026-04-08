# Règles: Terraform Best Practices

Cette règle définit tes standards incontournables en matière d'Infrastructure as Code (IaC) avec Terraform.

## Standards Obligatoires

1. **Structure Modulaire** : Les ressources Terraform doivent être découpées logiquement par service (ex: `cloudrun.tf`, `iam.tf`, `network.tf`...). La création de ressources globales dans un seul fichier monolithique comme `main.tf` est interdite.
2. **Standard Modules en Priorité** : Avant d'écrire une ressource from scratch, tu dois systématiquement vérifier si un module officiel existe et l'utiliser (ex: `terraform-google-modules` ou `terraform-aws-modules`).
3. **Version Pinning** : Toutes les versions (providers, modules terraform) doivent être strictement verrouillées (ex: `version = "~> x.y"`).
4. **Validation des Variables** : Chaque variable en entrée (`variable "..."`) susceptible d'entraîner une erreur d'infrastructure doit posséder son bloc de `validation {}`.
5. **Sécurité & Isolation** :
   - Par défaut, désactiver les IPs publiques et utiliser des sous-réseaux privés (Private subnets).
   - Appliquer le principe de "moindre privilège" dans les IAM bindings. Éviter massivement les rôles `editor` ou `owner`.
   - Toujours forcer l'usage du remote state et le chiffrement au repos.
