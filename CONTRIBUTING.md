# Contributing to Tackit

Thanks for helping build Tackit. This is a macOS-first, local-first, keyboard-driven note app.

## Prerequisites

- macOS 14+ (Apple Silicon), the Xcode 26 toolchain (`swift`)
- Node 20+ and `pnpm`

## Develop

```sh
./scripts/run.sh                 # build + assemble + launch (menu-bar agent, 📌)
swift test                       # TackitCore unit tests
cd editor && pnpm test           # editor md↔PM golden + fuzz + sanitization
```

`run.sh` kills any running instance and relaunches, so re-run it after changes.

## Where things live

- `Sources/TackitCore` — UI-agnostic core (models, document format, note store, search). Keep it platform-free.
- `Sources/TackitApp` — the macOS app (windows, overlays, settings, hotkeys, editor bridge).
- `editor/` — the TipTap editor bundle + vitest tests.
- `docs/` — product & engineering docs; `docs/05-interaction-and-keymap.md` is the source of truth for behavior.

## Ground rules

- **Product/UX decisions need the owner's sign-off.** Anything a user perceives — shortcuts, interactions, layout, feature scope, naming, defaults — is not yours to change unilaterally. When a technical constraint forces a behavior change, open an issue with options + a recommendation. See the full rule in `CLAUDE.md`.
- **Hotkey-first.** Every action must be reachable by keyboard; don't rely on mouse-only affordances.
- **Keep user-facing shortcuts configurable** where possible.

## Commits & PRs

- Use [Conventional Commits](https://www.conventionalcommits.org/) (`feat:`, `fix:`, `docs:`, `test:`, `chore:`…).
- Commit in logical units — don't batch unrelated work into one commit.
- Before opening a PR: `swift build`, `swift test`, and `cd editor && pnpm test` all pass. CI runs the same.
- Describe the user-visible change and how you verified it.
