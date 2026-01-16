# AI_INDEX (Immutable)

This file is immutable unless Tim instructs otherwise.

Read order:
1) AI_INDEX.md
2) project/agent.md
3) project/codex.md
4) project/pj-summary.md
5) project/plan.md
6) repo code and docs

Automation guardrails:
- Do not commit or expose secrets.
- Use git for local repo operations and gh for GitHub operations.
- Ask Tim before merging PRs, pushing to long-lived branches, force-pushing, or destructive actions.
- Default branch is main; do not rename unless Tim requests it.

Branch model and merge policy:
- Long-lived: main, dev, staging
- Short-lived: feat/*, fix/*, chore/*
- Merges: feat -> dev (squash), dev -> staging (merge or rebase), staging -> main (rebase)

CI/CD contract:
- CI runs on PRs and on pushes to dev/staging/main.
- CI runs pre-commit and make ci.
- Security workflow runs gitleaks and semgrep; trivy and syft only when Docker files exist.
- Release workflow runs after staging -> main merges and uses conventional commits to update CHANGELOG.md
  and GitHub release notes with strict semver tags (no prefix unless repo already uses it).
- Auto-detection for this repo: shell scripts and system config files; no build/test toolchain detected.

One-command interface (Makefile targets):
- init, fmt, lint, test, build, scan, ci

Key files:
- Tracked: AI_INDEX.md, Makefile, .mise.toml, .pre-commit-config.yaml,
  .github/workflows/*.yml, .github/ISSUE_TEMPLATE/*.yml, .github/PULL_REQUEST_TEMPLATE.md
- Local-only (gitignored): project/agent.md, project/codex.md, project/pj-summary.md,
  project/plan.md, project/skills.md, project/runlog.md
