# SPECS.md - Decision Tracking

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
