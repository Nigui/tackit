# ADR-003 — Editor engine: embedded web editor in a pooled WKWebView

- **Status:** Accepted (validated by the M0 proof-of-concept, 2026-08-10)
- **Deciders:** Founder, Software Architect
- **Related:** `04-architecture.md` (§ editor engine + Stickies addendum), `06-implementation-plan.md`

## Context

Tackit's core promise is sub-second, keyboard-first capture with rich formatting (tables, colors, inline images, link cards) that plain Markdown and Apple's native text stack cannot deliver cheaply. The central technical bet was **how to render the editable surface**:

- **(A) Native** — TextKit 2 / NSTextView. Best native feel, but tables/colors/inline-images have no good cross-Apple story and are very costly to build and maintain solo.
- **(B) Embedded web editor** — ProseMirror (via TipTap) in a `WKWebView`. Rich features come cheap and reuse on iOS and future platforms; risk is latency, memory (each `WKWebView` is multi-process), and native feel.

The architecture (04) recommended (B) behind an `EditorSurface` seam, with a **pool of pre-warmed webviews** to keep capture instant and memory bounded — everything else (hotkey, panels, windows, search, sync) stays native Swift.

## Decision

Adopt **(B): TipTap/ProseMirror in a pre-warmed pooled `WKWebView`**, loaded locally (no network). The M0 spike was built to falsify this bet before committing to it.

## M0 evidence (measured on Apple Silicon, Xcode 26.6, unsigned debug build)

| Metric | Result | Budget |
|---|---|---|
| Warm readiness (hotkey → editor ready to type) | **8–35 ms** | < 300 ms |
| Keystroke input → paint | **1–5 ms** (p95 ~16 ms) | "instant" |
| Memory | 10 MB launch → **~28 MB with 3 stickies + warm pool** (~5 MB/webview) | < ~700 MB @ ~10 |
| Window model | Borderless, always-on-top, non-activating panel; **types in-place without stealing focus or switching Spaces** | required |

Qualitative (founder): typing is instant; hotkey, stacking, floating, close/new all work.

Two implementation notes surfaced and were fixed during M0:
- Global hotkey must resolve the key from the **live keyboard layout** (French AZERTY "." is keycode 43, not the US-ANSI 47) — physical keycodes are not portable across layouts.
- Eager synchronous webview creation blocked the main thread at launch; warming must be **asynchronous / lazy**.

## Consequences

**Positive**
- Rich formatting (tables, colors, images, link cards) becomes tractable for a solo dev and reuses across platforms.
- Memory is far below the conservative 60–120 MB/webview estimate at M0 content levels (~5 MB/webview), so the snapshot/rehydrate complexity can likely be **deferred** until image-heavy notes exist.
- Latency budget is met with wide margin.

**Negative / risks**
- **Cold start:** the first `WKWebView` creation was highly variable (2.6 s – 13.9 s across runs) and blocks its main-thread hop shortly after launch. Suspected causes: unsigned/ad-hoc build (extra AMFI/code-sign checks on the WebContent XPC) and machine load during rebuilds. **Open — must be profiled on an idle, signed build before M1 ships.**
- The web surface is the one non-native component; native feel depends on disciplined styling and input handling.
- Rich styling (colors, per-note background) is not expressible in portable Markdown — carried as the frontmatter/inline-HTML compromise (see `05-interaction-and-keymap.md`).

**Fallback trigger (unchanged):** if signed-build cold start or steady-state latency regress below budget, evaluate **CodeMirror 6** (lighter) or a native inactive-window renderer. Not indicated by current data.

## Alternatives considered

- **TextKit 2 native editor** — rejected for M0's feature scope (no fluid cross-Apple tables; high solo-maintenance cost). Kept as the fallback lens only if the web path regresses.
- **One WKWebView per window (no pool)** — rejected on principle (multi-process cost); pooling + async warming adopted. At measured ~5 MB/webview the pressure is low, but the pool also solves warm-readiness, so it stays.
