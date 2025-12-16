#!/usr/bin/env bash
set -euo pipefail
# WARNING: This rewrites git history. Run from a clean clone and force-push afterwards.
# Paths identified by gitleaks on 2025-12-16 (redacted). Update list as needed.

paths=(
  usenet-credentials.txt
  CLAUDE.md
  COMPLETE_DOCUMENTATION.md
  MEDIA_SERVICES_SETUP.md
  SETUP_GUIDE.md
  TEST_PLAN.md
  configure-prowlarr.sh
  docker-compose.media.yml
  scripts/configure-web-ui.py
  scripts/mcp_server.py
  scripts/setup-media-services.sh
  docs/.vitepress/cache
  docs/.vitepress/dist/assets/chunks/theme.Bcq07Bgg.js
  docs/.vitepress/dist/assets/chunks/theme.Dt78WZgd.js
  docs/.vitepress/dist/assets/chunks/theme.OB2TRhgK.js
  docs/.vitepress/dist/assets/chunks/theme.Q-hb7SII.js
  docs/.vitepress/dist/assets/chunks/theme.*.js
  docs/.vitepress/dist/assets/chunks/theme.*.js.map
  docs/.vitepress/dist/assets/chunks/theme.*.css
  docs/.vitepress/dist/assets/chunks/theme.*.css.map
  docs/.vitepress/dist/COMPATIBILITY.html
  docs/.vitepress/dist/SERVICES.html
  docs/.vitepress/dist/SWARM_QUICKSTART.html
  docs/.vitepress/dist/TODO-komics-stack.html
  docs/.vitepress/dist/advanced
  docs/.vitepress/dist/cli
  docs/.vitepress/dist/comics-gap-plan.html
  docs/.vitepress/dist/faq.html
  docs/.vitepress/dist/getting-started
  docs/.vitepress/dist/images
  docs/.vitepress/dist/index.html
  docs/.vitepress/dist/komga.html
  docs/.vitepress/dist/ops-runbook.html
  docs/.vitepress/dist/reading-stack.html
  docs/.vitepress/dist/runbook
  docs/.vitepress/dist/secrets.html
  docs/.vitepress/dist/usenet-onboarding.html
  docs/.vitepress/dist/usenet-primer.html
  docs/.vitepress/dist/vnext-cluster-plan.html
)

for p in "${paths[@]}"; do
  opts+=(--path "$p")
done

git filter-repo --force --invert-paths "${opts[@]}"

cat <<NOTE
History rewritten. Next steps:
1) git remote remove origin && git remote add origin <url>  # optional if needed
2) git push --force --all
3) git push --force --tags
4) Re-run gitleaks: gitleaks detect --no-banner --redact
NOTE
