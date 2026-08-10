# Tackit ⚡📌

An extremely fast, keyboard-driven, local-first note app for macOS — Apple Stickies ergonomics with a modern editor. Pin a thought in under a second, keep it always-on-top, never lose it.

> Status: **M0 proof-of-concept.** This milestone exists to answer one question: does hotkey → borderless always-on-top sticky → typing feel instant (< 300 ms), using a pooled WKWebView editor, at an acceptable memory cost? See `docs/06-implementation-plan.md`.

## What M0 proves

- Global hotkey **⌘⇧.** opens a borderless, non-activating, always-on-top sticky (top-right, resizable, frame persisted).
- The editor surface is **TipTap (ProseMirror)** running in a **pre-warmed WKWebView pool**, not one webview per window.
- It prints objective **latency** (hotkey → editor ready; keystroke → paint) and **memory** (physical footprint) numbers so the go/no-go is data-driven.

## Requirements

- macOS 14+ on Apple Silicon
- Xcode 26 toolchain (`swift`, `swiftc`)
- Node 20+ and `pnpm`

## Run it

```sh
./scripts/run.sh
```

This builds the TipTap editor bundle, compiles the Swift app, wraps it in a real `.app`, and launches it as a menu-bar agent (no Dock icon). Then:

1. Press **⌘⇧.** anywhere to open a sticky. Press again to hide all.
2. Type. Press ⌘⇧. again to open more stickies (they stack top-right).
3. Read the numbers:

```sh
log stream --predicate 'eventMessage CONTAINS "[Tackit]"' --style compact
```

Look for `readiness (hotkey->editor focused)`, `keystroke input->paint`, and `memory (phys_footprint)`. Hand those back to decide M0 go/no-go.

## Layout

```
core/ ................ (TackitCore) UI-agnostic model/store — grows into the reusable iOS core
Sources/TackitCore ... Swift package: models (Note, ...)
Sources/TackitApp .... macOS spike: NSPanel window layer, webview pool, hotkey, metrics
editor/ .............. TypeScript + TipTap editor bundle (esbuild)
docs/ ................ product + engineering docs (research, PRD, roadmap, architecture, interaction, plan)
```

## License

MIT — see `LICENSE`.
