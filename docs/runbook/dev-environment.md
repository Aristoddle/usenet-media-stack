# Developer Environment (reference)

Use the dotfiles bootstrap for a consistent CLI across hosts (zsh/p10k, op/gh wiring, agent-ready MCP config).

- Repo: `Aristoddle/beppe-system-bootstrap` (local path: `~/Documents/Code/dotfiles/beppe-system-bootstrap`)
- Docs: `http://localhost:5173/beppe-system-bootstrap/` (dev server) or build with `npm run docs:build` in that repo.
- One-line apply: `chezmoi init --apply https://github.com/Aristoddle/beppe-system-bootstrap.git`
- Secrets: 1Password templating; do not commit tokens here. Use `op item get ... --reveal` at runtime.
- Platform notes: see `docs/USING_BAZZITE.md`, `BAZZITE_BOOTSTRAP.md`, `PLATFORM_DIFFERENCES.md` in the dotfiles repo.
- Troubleshooting/Recovery: `TROUBLESHOOTING.md`, `RECOVERY_QUICK_REFERENCE.md` in the dotfiles repo.

Keep this stack self-contained: we only link to the dotfiles repo; we do not vendor configs or secrets. When onboarding a new dev box, apply dotfiles first, then run the media stack as documented here.
