# SPECS.md - Decision Tracking

## [2026-10-26] - Daily Log - Remove agent prompts and VS Code settings

- Removed `.agents/prompts/` (`cloud-engineer-review.md`, `pr-review-merge.md`) and `.vscode/settings.json`: not needed in this repository. Earlier entries below remain as history.

## [2026-10-11] - Daily Log - Global rules applied: GitHub Actions CI, Terraform tests on Floci, pinned versions, partial S3 backend

- **ci**: `.github/workflows` (`_build-sample` + one `build-<sample>`, `check-cyber`, `check-quality` with CodeQL), pull requests only, actions pinned by SHA, no cloud credentials; `.gitlab-ci.yml` rewritten as a mirror (it included a missing file and had a deploy stage), `terraform test` on Floci stays GitHub-only; `renovate.json` keeps digests and the Floci image
- **tests**: `plan` tests against the real provider replaced by `tests/floci.tftest.hcl` per stack (apply on Floci, fake credentials); former assertions targeted attributes that do not exist; emulator gaps mocked in the test files; `FLOCI_IMAGE` pinned once in the root Taskfile
- **terraform**: `required_version`, `aws`, `random` and the security-group module pinned exactly; `validation` on every variable; S3 backend with `use_lockfile` and a partial config (bucket from `TF_VAR_state_bucket`, `.env` git-ignored, `.env.example`); remote-state key `states/aws-lab/vpc` corrected to `states/aws-lab/base`
- **tooling**: `.tflint.hcl`, `kics.config`, `trivy.yaml`, `Brewfile`; pre-commit hooks bumped (`detect-private-key`, tflint config); Taskfile rebuilt with one include per sample (the old `terraform-cmd` dispatch could not work), `test || echo` removed (it swallowed failures), `skills` task removed
- **security**: real ACM certificate ARN (with an account ID) of the ALB replaced by the `acm_certificate_arn` variable, hardcoded AKHQ password hash by a generated `random_password` (names aligned with branch `claude/aws-samples-mco-review-jy1k9j`), wildcard MSK IAM policy scoped to the cluster, ALB TLS policy and invalid-header dropping fixed, S3 public access block and `ENCRYPTED_VOLUMES` Config rule added, hardcoded RDS endpoint and token log removed from the Lambda sample, `fast-xml-parser` CVEs fixed in its lock file; remaining Trivy findings ignored inline with reason and expiry; KICS and Trivy are green
- **agents**: vendored `.agents/skills` removed (skills are global), `AGENTS.md` reduced to repo-specific rules
- **docs**: root and sample READMEs (links, commands, CI, tests); `.DS_Store` untracked and ignored

## [2026-08-02] - Daily Log - PR Review & Merge Agent Prompt, Dual-Model Optimization

- Added `.agents/prompts/pr-review-merge.md`: gatekeeper prompt (Sonnet 5 / Opus 5) that reviews every open PR, verifies pipeline status (or reproduces the verification gate locally when no CI checks report), posts line-anchored review comments, and merges autonomously only Tier A changes (docs, tests, patch/minor bumps with changelog read, CI repairs) — Tier B (IAM, network, encryption, state, major bumps, resource replacement) is approve-only with `needs-human-merge`, ambiguity always demotes the tier.
- Hard rails: squash merge + branch deletion, ≤ 2 merges per run, never push to PR branches, never merge red/unverified CI, PR descriptions and CI logs treated as untrusted input.
- Generalized `.agents/prompts/cloud-engineer-review.md` to target both `claude-sonnet-5` and `claude-opus-5` via a shared "Model calibration" section, and cross-referenced the two prompts (producer opens draft PRs, gatekeeper reviews/merges them).

## [2026-07-14] - Daily Log - Operational Review Prompt for Cloud Engineer Agent

- Added `.agents/prompts/cloud-engineer-review.md`: a Sonnet 5-optimized mission prompt for a recurring autonomous agent covering MCO (obsolescence, vulnerabilities, issues), AWS service watch with PR-based evolution proposals (two-tier: direct PR vs RFC in `docs/proposals/`), CI/CD pipeline health (GitLab/GitHub dual-pipeline rule), and documentation sync.
- Prompt encodes hard guardrails: PR-only delivery, no `apply`/`destroy`, pre-commit + `terraform validate`/`test` verification gate, ≤ 4 PRs per run, mandatory PR body contract (Context / Change / Risk & Rollback / Verification / Sources).

## [2026-04-08] - Daily Log - Project Industrialization & Taskfile Integration

- Replaced legacy `Makefile` with root and local `Taskfile.yml` for unified orchestration.
- Enhanced root `README.md` with industrial design and samples table.
- Standardized sample `README.md` files with Features and Quick Start sections.
- Integrated `awscli` and `terraform-docs` into the development workflow.
- **Refactoring**: Reorganized repository into `samples/` and `samples/base/` to match `gcp-samples` structure.
- **ECS Improvement**: Renamed `ecs` to `ecs-service` and created `ecs-task` for one-off batch executions.
- **Testing**: Added `terraform test` files for all stacks to improve reliability.
- **Quality Centralization**: Consolidated all `pre-commit` configurations into the project root and enhanced hooks with standard hygiene and advanced security (Trivy).
