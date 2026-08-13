# Roadmap: blazing-fast-memo (POC → Production MVP → Beyond)

**Owner**: Alex (PM)  **Last Updated**: 2026-08-13
**Companion doc**: `02-prd.md` (features referenced by their §6 theme names)

> This roadmap is a **prioritized bet**, not a contract. Effort is relative (S/M/L) for a solo Swift dev, not a date commitment. Each milestone has an explicit exit gate; **do not start the next milestone until the current gate is met.** The two architecture decisions this roadmap was sequenced to defer are now **resolved** — see **Decisions Locked (2026-08-10)** below, which supersedes any conflicting milestone text.

---

## Decisions Locked — 2026-08-10

Founder confirmed the four gating decisions. The two architecture questions this roadmap was sequenced to defer are now **resolved**, which changes scope below. **Where this section conflicts with milestone text further down, this section wins** (that text predates the decisions).

- **[ARCH-EDITOR] → RESOLVED: embedded web editor** (TipTap/ProseMirror in a pre-warmed `WKWebView`), behind a Swift `EditorSurface` protocol. Everything else — hotkey, panels, menu bar, windows, search, sync — stays native Swift.
- **[ARCH-STORAGE] → RESOLVED: Markdown + YAML frontmatter + per-note `assets/`** on disk (canonical), ProseMirror JSON as the runtime model, SQLite/FTS5 (GRDB) as a rebuildable search index.
- **Wedge → "Raycast without ceilings"** — Persona A (the Flow Capturer) leads.
- **Multi-note → design for panes now, ship single first.** M1 commits to a **windowed-capable interaction model** even though it ships a single-note surface; the panes UI lands at M3 with no interaction-model rewrite.
- **Sync → local → CloudKit → managed freemium, M4 gated** (unchanged).

**Scope delta from the web-editor decision.** Rich formatting was parked at M3 *because native text made it hard*. With a web editor those features are low-marginal-cost once the surface exists, and market research says they're needed to occupy the whitespace. Therefore:

- **Pulled M3 → M1:** tables, text color + highlight, paste image, short/rich link chips. Gated by the same **< 300 ms time-to-first-keystroke** budget — if any one threatens it, it drops back to M3.
- **Stays M3:** multi-note *panes* UI, folders/groups, tags, note icon/description, per-note background, theme presets/import, focus mode, extended-markdown extras, non-image attachments, link unfurl.

**Resolved:** **Licence = MIT.** **AI features = out of scope** for now (revisit only on strong signal; must not dilute the speed story).

### Wireframe Review Round — 2026-08-10 (interaction-model pivot)

Founder review of the first wireframes pivots the model from a Raycast command-panel toward **Apple Stickies-style floating note windows**, keeping the modern light design. Authoritative:

- **No window chrome** — no macOS traffic-light buttons (minimize/close/maximize). Borderless.
- **Always-on-top** — an open note floats above other apps so it can't be lost behind them.
- **Default size/position** — small **sticky size, 380 px wide**, opens **top-right** by default. Position + size **configurable and persisted** across launches.
- **Global hotkey = ⌘⇧.** (Cmd-Shift-Period), rebindable. It **opens the last-opened note**, not a blank new note.
- **Per-note icon** — configurable and shown **inline while editing**.
- **Metadata inline** — note metadata visible + editable **while editing** (not only in a separate inspector).
- **Multi-note = multiple independent floating windows, not a paned app.** Each note is its own window that behaves exactly like a single note — **no sidebar, no header**. Layering = most-recently-opened/edited on top; switch windows with **⌘+number**. Search opens the selected note in the current top window; a separate hotkey opens it in a **new** window. **Ships at M3, but designed now.**
- **UX target** — Apple Stickies ergonomics + this project's modern light aesthetic.
- **Accent** — shift from "Ember" orange to a **gold / electric / lightning** hue (final shade TBD by design); fits the "blazing-fast" identity.
- **Typeface** — system font, **not user-configurable for now** (drop the font-family picker).
- **Storage** — Markdown + frontmatter **confirmed**.

**Architecture implication (addendum requested):** many always-on-top note windows, each needing the rich web editor, stresses the original "single pre-warmed WKWebView" plan — needs a webview pool/reuse + lightweight-inactive-window strategy and a memory budget. See `04-architecture.md` addendum.

---

## North Star

**Time-to-first-keystroke**, guarded relentlessly. If a feature threatens it, the feature loses. Secondary: does the founder use it every day?

---

## Milestone Ladder (at a glance)

| Milestone | Goal in one line | Effort |
|---|---|---|
| **M0 — Proof-of-Concept** | Prove the capture+edit loop *feels* instant and format-as-you-type works | S–M |
| **M1 — Local MVP** | Daily-usable, local-only, unlimited, keyboard-first, Homebrew-installable | L |
| **M2 — iOS + CloudKit** | Same notes on iPhone/iPad, Apple-only sync, no server to run | L |
| **M3 — Rich features + customization** | Multi-note, tables, media, theming — the "better than Raycast" layer | L |
| **M4 — Managed cloud freemium** | E2E-encrypted cross-platform sync + monetization (treat as "maybe/hire") | XL |

---

## M0 — Proof-of-Concept

**Goal:** Answer the only question that kills the product if wrong: *does the core loop feel great?* Smallest artifact that proves global-hotkey → instant surface → markdown-as-you-type. Throwaway-quality is fine; **this milestone exists to resolve [ARCH-EDITOR].**

**Included (PRD refs):**
- Capture: *Global hotkey → instant note*, *Sub-300ms time-to-first-keystroke* (measured, not vibes).
- Editing: *Markdown-as-you-type*, *Core inline marks*, *Headings/lists* — enough to feel the typing experience. **[ARCH-EDITOR]**
- One note, in memory or a single file. No list, no search, no persistence guarantees.

**Explicitly out of scope:** persistence/reliability, multiple notes, search, metadata, settings, packaging, any media, any sync.

**Effort:** S–M.

**Dependencies:** **[ARCH-EDITOR]** must be spiked *here*. Build the as-you-type prototype in **both** candidates enough to judge (or timebox one and fall back). Do not defer this decision past M0 — it dictates everything downstream.

**Exit criteria:**
- Hotkey → typing measured **< 300ms**, repeatably.
- "## " → H2 and core marks render live and feel natural while typing.
- A clear, written **[ARCH-EDITOR]** decision with rationale (recorded in an ADR).
- Gut check: founder says "yes, this feels better than Raycast to type in." If not, stop and rethink the engine — do not proceed to M1.

---

## M1 — Local MVP (the real target)

**Goal:** An app the founder uses **every day**, local-only, that removes Raycast Notes' ceilings that matter most (cap, ownership) while matching its speed. This is "a good v1" per PRD §7.

**Included (PRD refs):**
- Capture: *New-note-on-open*, *Quick-switch to recent note*, *Menu-bar presence* (Should).
- Editing: *Markdown-as-you-type*, *Core inline marks*, *Lists/checklists/nesting*, *Headings/quotes/code blocks*, *Keyboard-first formatting* (all Must).
- Organization: *Unlimited notes*, *Keyboard note switcher / quick-open*, *Full-text search* (Must); *Auto created/updated metadata* (Should). **[ARCH-STORAGE]**
- Viewing: *Single focused editor*, *Note list / navigator* (Must).
- Customization: *Light/dark/system theme* (Should); *Customizable shortcuts* if cheap.
- Sync: *Local-only, no backend* (Must); optionally *user-chosen storage folder* so power users can self-sync via iCloud Drive/Dropbox (Could).
- Distribution: *Signed + notarized direct download*, *Homebrew Cask*, *Open-source repo + license* (Must); *Auto-update (Sparkle)* (Should).

**Explicitly out of scope:** multi-note view, tables, colors/backgrounds, images, rich links, folders/tags/icons/description, iOS, any cloud, rich block model.

**Effort:** L.

**Dependencies:**
- **[ARCH-STORAGE]** must be decided **before** persistence work starts. M1 needs at least created/updated timestamps → pushes toward `.md` + frontmatter (or sidecar). **Recommendation: adopt "portable Markdown body + minimal frontmatter" now**; it satisfies M1, keeps files portable, and leaves room for M3 assets. Decide against a plain-`.md`-only choice only if you're willing to give up per-note metadata.
- Apple Developer account + signing/notarization pipeline (set up early, not at ship).
- Editor engine from M0.

**Exit criteria (this is the "production MVP" gate):**
- Founder has used it as primary note app for **2+ weeks** with zero data loss.
- `brew install --cask` works on a clean Mac; app is notarized and launches without Gatekeeper friction.
- Unlimited notes + full-text search + keyboard switcher all functional, no mouse required for the core loop.
- Notes are real files, readable/editable outside the app.
- Public repo live with a license and a README.

**Status / carryover (2026-08-13):** M1 is daily-usable and open-source, distributed as an **unsigned pre-release** DMG + a Homebrew tap (`brew install --cask nigui/tap/tackit`). Outstanding before the M1 distribution gate is fully met:

- **Signed + notarized release** (M1-Must) — **blocked on Apple Developer Program enrollment.** Once enrolled: add the signing + notarization secrets (and `TAP_TOKEN`), tag a stable release; CI then notarizes the DMG and auto-bumps the cask. Until then the tap serves the unsigned build and users hit Gatekeeper friction.
- **Auto-update (Sparkle)** (M1-Should) — deferred.
- **CI time-to-first-keystroke gate (< 300 ms)** — deferred.

---

## M2 — iOS + CloudKit Sync

**Goal:** The same notes on iPhone/iPad, synced across Apple devices **with no backend to operate** — the pragmatic, low-risk sync answer. Delivers the biggest single Raycast gap (no mobile).

**Included (PRD refs):**
- Sync: *CloudKit sync (macOS ↔ iOS)* (Won't-yet→now).
- Distribution: *iOS App Store build* (app + widgets + App Intents/Siri per the locked native-Apple plan).
- Capture (iOS): widget / App Intent / Siri entry point mirroring the "instant capture" ethos on mobile.
- Re-use the M1 editor and storage on iOS.

**Explicitly out of scope:** non-Apple platforms, managed/cross-platform sync, accounts/billing, most M3 rich features (bring only what's trivially portable).

**Effort:** L. (CloudKit conflict handling, schema/migration, and a second platform's UI are each non-trivial.)

**Dependencies:**
- **[ARCH-STORAGE]** is load-bearing here: the storage/format chosen at M1 must map cleanly to CloudKit records. A pure "loose `.md` files in a folder" model syncs awkwardly via CloudKit (vs a structured store). **This is a strong reason to lock a structured-but-exportable format at M1** rather than plain files. Flag to architect: *if M1 shipped plain files, M2 may force a storage migration.*
- Apple Developer Program (already in place from M1).
- CloudKit container setup; conflict-resolution strategy (last-writer-wins vs merge).

**Exit criteria:**
- A note created on Mac appears on iPhone (and vice versa) within seconds, offline-tolerant, with sane conflict handling and no data loss across 2+ weeks of real use.
- iOS app in the App Store (or TestFlight for a soft launch) with at least one instant-capture entry point (widget/Siri).

---

## M3 — Rich Features + Customization

**Goal:** Layer on the "*better* than Raycast" surface — the features that turn a fast-capture tool into a place people want to live. Deliberately **after** the core loop and sync are rock-solid, because these are where scope creep and the plain-`.md` tension bite hardest.

**Included (PRD refs):**
- Viewing: *View multiple notes at once* (the headline differentiator), *Detachable/floating windows*, *Focus/zen mode*.
- Editing: *Tables*, *Extended markdown*, *Text colors/highlights*, *Slash/command palette*. **[ARCH-EDITOR][ARCH-STORAGE]**
- Media & Links: *Paste photos*, *Rich/short link rendering*, *Drag-drop*, *link preview/unfurl*. **[ARCH-STORAGE]** (asset storage)
- Organization: *Folders/groups*, *Note description & icon*, *Tags*, *Pinning*. **[ARCH-STORAGE]** (frontmatter/metadata)
- Customization: *Font family & size*, *Accent/UI color*, *Per-note background*, *Theme presets/import*. **[ARCH-STORAGE]** (app-layer metadata)

**Explicitly out of scope:** rich block model / Notion-style blocks unless a specific feature (e.g. callouts) demands it *and* the storage format already supports it; real-time collaboration (permanent non-goal); AI features (separate decision).

**Effort:** L (spread over time; ship these incrementally, not as one big-bang release).

**Dependencies:**
- **[ARCH-STORAGE]** fully exercised: this is where images, colors, backgrounds, icons, and tables all demand a home. If M1/M2 chose plain `.md`, M3 forces the migration to `markdown+frontmatter+assets` (or a block model). **Best outcome: M1 already chose the extensible format, so M3 is additive, not a rewrite.**
- **[ARCH-EDITOR]** stressed by tables and rich-link chips — the hardest editor craft. Validate the engine can do these *before* committing (a late discovery that the engine can't do fluid tables is expensive).
- Multi-note view depends on the app being windowed, not single-panel — an interaction-model shift (PRD §8). Prototype and validate demand first.

**Exit criteria:**
- Multi-note view ships and is used without regressing capture speed.
- Paste-photo and rich-link render round-trip correctly through storage and (if M2 shipped) sync.
- Customization (font/size/theme) persists per user and syncs.
- No feature in this milestone degraded time-to-first-keystroke below the M0 budget.

---

## M4 — Managed Cloud Freemium (the "maybe / hire" milestone)

**Goal:** E2E-encrypted, cross-platform sync behind a freemium model — the vision's end state and the monetization moment.

**Included (PRD refs):**
- Sync: *Managed freemium sync (E2E, cross-platform)*.
- Accounts, billing/subscriptions, key management, server ops, support, and (eventually) non-Apple clients.

**Explicitly out of scope for now:** everything, effectively — this should **not** be actively scoped until M1–M3 have real users pulling for it.

**Effort:** XL.

**Dependencies:** a working E2E-crypto and account/billing architecture (architect + likely additional help); sustained user demand; a business decision to run infrastructure.

**Exit criteria (gate to even *start*):**
- Demonstrated demand: a meaningful cohort asking for cross-platform/non-Apple sync that CloudKit can't serve.
- A credible operating plan (who runs the servers, handles support, owns compliance).
- Honest capacity check: solo-dev bandwidth or a plan to add help.

> **PM position:** M4 is a *company*, not a *feature*. For a solo dev, **CloudKit (M2) is realistically the end state for a long time.** Keep M4 on the roadmap as direction, but do not let it pull scope or complexity into M1–M3. Revisit only when M2/M3 have proven demand.

---

## Prioritization Rationale — Impact vs Effort (contentious features)

| Feature | Impact | Effort | Verdict & why |
|---|---|---|---|
| **Multi-note view** | High (loudest anti-Raycast claim) | High (forks interaction model, windowing) | **M3, not M1.** High-impact but high-risk to the capture model. Ship the fast single panel first, add multi-note as a *mode* once the core is loved. Don't let the differentiator destabilize the foundation. |
| **CloudKit sync** | High (kills "no mobile" — Raycast's #1 gap) | High but bounded (no server) | **M2.** Best impact-per-risk sync option; Apple-native (locked strategy); no ops burden. The right first sync. |
| **Managed E2E freemium** | High *if it grows*, speculative now | XL (a whole business) | **M4 / maybe.** Impact is real only at scale; effort is enormous for one person. Gate hard. |
| **Tables** | Medium (frequently wanted) | High (hardest editor craft) | **M3.** Wanted, but the classic scope-creep trap. Validate the engine can do it fluidly before committing. |
| **Paste photos** | Medium | Medium (forces asset storage) | **M3.** Cheap UX, expensive architecture — it's a primary driver of the plain-`.md` decision. Defer until storage is settled. |
| **Colors / per-note backgrounds** | Low–Medium (aesthetic, Persona C) | Medium (non-md metadata) | **M3, Could.** Nice, not a wedge. Only build once the extensible storage format exists; otherwise it corrupts the portability promise. |
| **Rich block model** | Medium (enables callouts/toggles) | High (biggest storage commitment, lock-in) | **Won't-yet / avoid.** Fights local-first + portability. Adopt only if a must-have feature genuinely requires it. |
| **Auto created/updated metadata** | Medium (table stakes, cheap) | Low | **M1.** Cheap, high-utility, and it's the forcing function to pick `.md`+frontmatter early — which pays off at M2/M3. |
| **Homebrew + notarization** | High (it's the distribution promise) | Medium (one-time pipeline) | **M1, must.** Non-negotiable for the "installable via Homebrew, not App Store" positioning. |
