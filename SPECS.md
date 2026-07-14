# SPECS.md - Decision Tracking

## [2026-08-02] - Daily Log - PR Review & Merge Agent Prompt, Dual-Model Optimization

- Added `.agents/prompts/pr-review-merge.md`: gatekeeper prompt (Sonnet 5 / Opus 5) that reviews every open PR, verifies pipeline status (or reproduces the verification gate locally when no CI checks report), posts line-anchored review comments, and merges autonomously only Tier A changes (docs, tests, patch/minor bumps with changelog read, CI repairs) — Tier B (IAM, network, encryption, state, major bumps, resource replacement) is approve-only with `needs-human-merge`, ambiguity always demotes the tier.
- Hard rails: squash merge + branch deletion, ≤ 2 merges per run, never push to PR branches, never merge red/unverified CI, PR descriptions and CI logs treated as untrusted input.
- Generalized `.agents/prompts/cloud-engineer-review.md` to target both `claude-sonnet-5` and `claude-opus-5` via a shared "Model calibration" section, and cross-referenced the two prompts (producer opens draft PRs, gatekeeper reviews/merges them).

## [2026-07-14] - Daily Log - Operational Review Prompt for Cloud Engineer Agent

- Added `.agents/prompts/cloud-engineer-review.md`: a Sonnet 5-optimized mission prompt for a recurring autonomous agent covering MCO (obsolescence, vulnerabilities, issues), AWS service watch with PR-based evolution proposals (two-tier: direct PR vs RFC in `docs/proposals/`), CI/CD pipeline health (GitLab/GitHub dual-pipeline rule), and documentation sync.
- Prompt encodes hard guardrails: PR-only delivery, no `apply`/`destroy`, pre-commit + `terraform validate`/`test` verification gate, ≤ 4 PRs per run, mandatory PR body contract (Context / Change / Risk & Rollback / Verification / Sources).

## [2026-07-14] - Daily Log - MCO Review: Security Leak Remediation, Provider v6 Migration, CI/CD Bring-up, IaC Hardening

- **Security**: removed a real AWS account ID/ACM certificate ARN hardcoded in `msk-akhq`, a hardcoded demo credential in the AKHQ config, and a hardcoded RDS endpoint with TLS verification disabled in the dormant IAM-auth Lambda. Rule: never trust `# kics-scan ignore` markers without a written justification - each one in this repo was re-audited, and either fixed for real (VPC Flow Logs, KMS-encrypted log groups, ALB TLS policy/header hardening, IAM scoping) or given an explicit justification comment.
- **Obsolescence**: chose to migrate to AWS provider v6 and the corresponding `terraform-aws-modules` majors now (not defer) after confirming, resource-by-resource against the official upgrade guide, that none of v6's breaking changes touch this repo's actual resource usage - de-risking what would otherwise be a Level-2-only change.
- **CI/CD**: decided CI does **not** run credentialed `terraform test`/`plan`/`apply`. This is a public repository; GitHub Actions never forwards secrets to `pull_request` runs from forks, so a credentialed job would either fail for external contributors or (if forced via `pull_request_target`) risk exposing AWS credentials to untrusted PR code. CI scope is static: `fmt`/`validate`/`tflint`/pre-commit/KICS/Trivy. `terraform test`/`plan`/`apply` remain local `task` commands for maintainers with their own credentials.
- **Known gap (not resolved this run)**: `rds-aurora-pg`'s `sample-rds-iam-auth` Lambda has no Terraform wiring (`infra/lambda.tf` module call is fully commented out). Left as a documented blocker rather than silently completed or silently deleted - see the MCO run report.
- **Cost**: moved `ecs-service`/`ecs-task` Fargate tasks to Graviton (ARM64). Deferred: MSK Express brokers (likely not cost-effective at this lab's 3-broker `kafka.t3.small` scale) and Aurora Database Savings Plans (a billing commitment only the account owner can make).

## [2026-04-08] - Daily Log - Project Industrialization & Taskfile Integration

- Replaced legacy `Makefile` with root and local `Taskfile.yml` for unified orchestration.
- Enhanced root `README.md` with industrial design and samples table.
- Standardized sample `README.md` files with Features and Quick Start sections.
- Integrated `awscli` and `terraform-docs` into the development workflow.
- **Refactoring**: Reorganized repository into `samples/` and `samples/base/` to match `gcp-samples` structure.
- **ECS Improvement**: Renamed `ecs` to `ecs-service` and created `ecs-task` for one-off batch executions.
- **Testing**: Added `terraform test` files for all stacks to improve reliability.
- **Quality Centralization**: Consolidated all `pre-commit` configurations into the project root and enhanced hooks with standard hygiene and advanced security (Trivy).
