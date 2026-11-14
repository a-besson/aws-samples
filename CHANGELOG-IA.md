# CHANGELOG-IA.md - Decision Tracking

## [2026-11-14] - Daily Log - CHANGELOG-IA rename, global review: toolchain, CI supply chain and sample fixes

- Renamed `SPECS.md` to `CHANGELOG-IA.md` (history preserved) to match the naming convention used in sibling repositories; updated the one reference in `AGENTS.md`.
- Removed `NOTES.md` (a one-off personal todo list from before the `samples/` refactor, already fully actioned, no longer referenced anywhere).
- **toolchain**: Terraform pinned to 1.17.2 (was 1.16.5) in every stack and in CI, the version the workstation runs: with an exact pin, any other local binary refuses `init`. 1.17.2 was 3 days old, below the 7-day minimum release age: exception approved by the user (patch release, bug fixes only).
- **ci**: `.gitlab-ci.yml` removed, GitHub Actions is the only CI; `AGENTS.md` (sync rule) and `README.md` aligned.
- **security**: `check-cyber` pins Trivy v0.76.2: without `version`, trivy-action v0.36.0 ran v0.70.0, affected by GHSA-mcj4-mphf-j9ff (CVE-2026-55092, HIGH), GHSA-8rc5-4fr6-64pw and GHSA-q3fv-x8vg-qqm4.
- **deps**: Floci 2.2.0 → 2.4.0 and KICS v2.1.20 → v2.2.0, both pinned by tag and digest in the root Taskfile (single source, now also read by `check-cyber`), Renovate regex extended to the KICS image and to digests. Floci ≥ 2.3 rejects a listener certificate the account does not have: the `msk-akhq` test imports a throwaway self-signed certificate (`tests/fixtures/acm`) instead of passing a fake ARN; KICS reads its key reference as a literal private key (false positive, ignored inline with the reason).
- **ci**: the KICS SARIF of `check-cyber` was written to `RUNNER_TEMP`, outside the workspace that `hashFiles()` searches, so the upload never ran (code scanning has no `kics` analysis since the workflow exists); the report now goes to `kics-results/` in the workspace.
- **deps**: `actions/setup-python` v7.1.0, `github/codeql-action` v4.39.3, `pre-commit` 4.7.0, `pre-commit-terraform` v1.109.4, `conventional-pre-commit` v4.5.0, TFLint AWS ruleset 0.50.0; TFLint pinned to v0.65.0 in CI (`setup-tflint` installed `latest`). Releases younger than 7 days (terraform-docs 0.25.1, pre-commit-terraform v1.109.5, KICS v2.2.1, TFLint v0.66.0) are left for later.
- **naming**: `local.name = "lab-${basename(path.cwd)}"` always resolved to `lab-infra` (every command runs in `infra/`), so `ecs-task` and `msk-akhq` both created the IAM role `lab-infra-task-role`; each stack now has a literal name (`lab-<sample>`) and a literal `Stack` tag. No stack is deployed (confirmed by the user), so the renames replace nothing; the test asserts on the names follow.
- **versions**: Aurora PostgreSQL 16.4 is no longer in the supported minor versions (the `aws_rds_engine_version` lookup cannot resolve it): 16.15, end of standard support 2028-02-28. MSK Kafka 3.5.1 reached end of support on 2025-10-23 (MSK auto-upgrades such clusters without notice): 3.9.x, the version MSK recommends.
- **images**: task definitions no longer use `:latest`: amazonlinux `2023.12.20261102.0` and nginx `1.30.6` pinned by tag and ECR Public digest, AKHQ `0.28.0` (private ECR copy, README `crane cp` aligned; the ECR registry region now follows `aws_region`).
- **ecs-service**: the nginx image listens on 80 (`ExposedPorts 80/tcp`) and has no `/health` route, but the task mapped 8080 and probed `/health`: container port 80 and health check on `/`.
- **rds-aurora-pg**: `random_password.master` removed (dead code since `manage_master_user_password = true`, its KICS ignore and its test assertion with it, plus the then unused `random` provider); `db_subnet_group_name` outputs the name instead of the whole resource.
- **lambda (rds-aurora-pg)**: the connection is closed in `finally` and awaited (it leaked when the query failed), the `pg_roles` rows are no longer logged (row count only), unused imports removed, `main` points to `index.mjs`, dependencies pinned to the versions already resolved by the lock file (`@aws-sdk/rds-signer` 3.1079.0, `pg` 8.13.1), and the unused `rds-ca-2019-root.pem` (expired 2024-08-22) deleted. TLS verification (`ssl: 'no-verify'`) is a proposal in the review.
- **msk-akhq**: `awsDebugCreds=true` removed from the AKHQ SASL config (debug option of the MSK IAM client that logs the identity used at every authentication).
- **docs**: the sample READMEs carried a frozen, outdated `BEGIN_TF_DOCS` block (`>= 1.9.0`, `~> 5.4`, module `9.11.0`) or empty markers, while pre-commit generates `infra/TFDOCS.md`: replaced by a link to it; stray ` Linda` line removed from the msk-akhq README.
- **msk-akhq**: the target group spoke HTTPS to AKHQ, which serves plain HTTP on 8080 (the health check already used HTTP), so every forwarded request failed the TLS handshake (502): it now uses HTTP, TLS still ends at the HTTPS listener.
- **rds-aurora-pg**: `deletion_protection` off: it made `task destroy-all` fail on a lab cluster that has no data to keep and already skips the final snapshot; Trivy AWS-0343 (MEDIUM) ignored inline with the reason.
- **finops (base)**: the interface endpoints (5 × 3 AZ, about 120 $/month idle) now sit in the first private subnet only and can be turned off with `enable_interface_endpoints` (default `true`, the ECS samples need them); the `rds` endpoint is removed, no caller uses the RDS API from the VPC (IAM auth tokens are signed locally). 4 endpoints in 1 AZ: about 32 $/month.
- **tests**: Floci is published on `127.0.0.1:4566` only, locally and in CI: it has no authentication and drives the Docker socket (past advisories were unauthenticated RCEs on that port). The containers it starts reach it over the Docker network, not the published port; `task test-all` stays 5/5.
- **ci**: with the upload now running, code scanning rejected the KICS v2.2.0 SARIF (`taxonomies[1].taxa contains duplicate item`: some CWE taxa are written twice): a `jq` step keeps the first copy of each before the upload; results reference CWE taxa by id, the rest of the report is unchanged.
- **ecr (base, ecs-service, ecs-task)**: the private subnets have no NAT gateway and `public.ecr.aws` has no VPC endpoint, so the nginx and amazonlinux images could not be pulled. `base` adds an ECR Public pull through cache rule (prefix `ecr-public`, output `ecr_public_pull_through_prefix`), the task definitions pull through it via the ECR interface endpoints, and the execution roles get `ecr:BatchImportUpstreamImage` and `ecr:CreateRepository` on `repository/ecr-public/*` only. AWS documents that the first pull through a PrivateLink endpoint may need an internet route: the base README makes a warm-up pull from the workstation, with a check of the pinned digest, a prerequisite.
- **kms (base)**: single customer managed key of the samples (requested by the user): `terraform-aws-modules/kms` 3.1.1 (the last line for aws 5.x; 4.x needs aws >= 6), alias `lab-samples`, rotation on, 7-day deletion window, output `kms_key_arn`. Key policy: default account statement, plus CloudWatch Logs (`kms:EncryptionContext:aws:logs:arn` limited to the account and region) and AWS Config delivery (`aws:SourceAccount`), as documented by AWS (checked against the documentation, Floci does not evaluate key policies). The AWS Config bucket moves from SSE-S3 to SSE-KMS with a bucket key, and the delivery channel sets `s3_kms_key_arn`; the Trivy AWS-0132 ignore and its "costs more for no gain" reason are gone.

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
