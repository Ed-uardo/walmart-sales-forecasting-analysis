# Walmart Kaggle Data Science Project

This repo pairs solid DS work with reliable DevOps/CI so you can iterate fast and safely.

## Repo infrastructure
- Dependencies: Poetry-managed `pyproject`; fast, reproducible installs via `uv`
- CODEOWNERS: Enforced reviewers and ownership
- Pull requests: Standard template, clear scope, small diffs, all checks must pass
- Quality gates: `ruff` (lint), `black` (format), `bandit` (security), `pytest` (unit/coverage)
- Pre-commit: Local lint/format/security hooks before commits
- Hygiene: Scheduled workflow to mark stale PRs/branches and auto-clean after inactivity, using least-privilege `GITHUB_TOKEN` permissions
- Ignore list: Branches listed in `ignore_branches.txt` are excluded from stale cleanup

## Working in this repo
- Create feature branches; commit often; write tests alongside code
- Run pre-commit locally before pushing
- Open PRs with a descriptive title, context, and checklist; request the right owners
- CI runs on push/PR; merges only when all gates are green

## CI/CD at a glance
- PR checks: lint, format, security scan, tests
- Main protection: required checks, CODEOWNERS reviews
- Stale cleanup: marks inactive after N days; closes PRs and prunes merged branches on schedule

## Bad PR Test
- The purpose of this PR is to test workflows locally