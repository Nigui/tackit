# Tackit — contributor & agent working agreements

Tackit is an open-source, macOS-first, Apple Stickies-style note app. This file is read by AI coding agents (e.g. Claude Code) and by human contributors.

## Product decisions (hard rule)

**Never make product or UX decisions without the product owner's explicit approval.** Anything a user perceives — keyboard shortcuts and keymaps, interactions, layout, feature scope, naming, defaults — requires sign-off. When a technical constraint forces a change to the intended behavior, STOP and present the options with trade-offs and a recommendation; let the owner choose. Do not silently substitute a different behavior.

Implementation details (code structure, libraries, storage strategy, algorithms) are the contributor's to decide.

Corollary: keep user-facing shortcuts configurable where possible.

Corollary — **hotkey-first**: every action must be reachable and driven by a keyboard shortcut first. Avoid relying on buttons/mouse affordances; where a control is unavoidable, the hotkey path must exist and be the primary one. Chrome-less, keyboard-driven speed is the product's core.

## Orientation

- `docs/` — product & engineering docs: market research, PRD, roadmap, architecture (+ ADRs in `docs/adr/`), the interaction & keymap spec, the M1 task list, and code reviews in `docs/reviews/`.
- `Sources/TackitCore` — UI-agnostic core (models, document format, note store, search); reusable across platforms.
- `Sources/TackitApp` — the macOS app (window/panel layer, editor surface, Swift↔JS bridge, quick-open, global hotkey).
- `editor/` — the TypeScript + TipTap editor bundle (esbuild build, vitest tests).

## Build & test

- `swift build` / `swift test` — the Swift package.
- `cd editor && pnpm build` — build the editor bundle; `pnpm test` — vitest round-trip suite.
- `./scripts/run.sh` — build everything, assemble the `.app`, and launch it.

## Conventions

- Commit in logical units with Conventional Commits messages; don't batch unrelated work into one commit.
