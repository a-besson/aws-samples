---
name: Community Skills Orchestrator
description: "Guidelines and index for third-party skills stored in the community folder."
---

# 🌐 Community SKILLS Guidelines

Ce skill agit comme un orchestrateur pour toutes les compétences tierces téléchargées via la CLI.

## 🔎 Visibilité des Skills

L'agent **DOIT** impérativement scanner et parcourir l'intégralité des sous-répertoires de ce dossier (`.agents/skills/community/`) pour identifier et charger les compétences spécifiques disponibles avant toute intervention sur les domaines correspondants :

- **Terraform Stacks** : voir [terraform-stacks/SKILL.md](./terraform-stacks/SKILL.md)
- **Terraform Test** : voir [terraform-test/SKILL.md](./terraform-test/SKILL.md)
- **Style Guide** : voir [terraform-style-guide/SKILL.md](./terraform-style-guide/SKILL.md)
- **Provider Actions** : voir [provider-actions/SKILL.md](./provider-actions/SKILL.md)
- **Refactor Module** : voir [refactor-module/SKILL.md](./refactor-module/SKILL.md)
- **Provider Resources** : voir [provider-resources/SKILL.md](./provider-resources/SKILL.md)
- **New Provider Creation** : voir [new-terraform-provider/SKILL.md](./new-terraform-provider/SKILL.md)

## ⚖️ Priorité

Toutes les compétences identifiées ici sont soumises à l'autorité du **Master Prompt Morpheus**. En cas de conflit technique ou comportemental, les règles situées dans `.agents/rules/morpheus-expert-devops/` prévalent.
