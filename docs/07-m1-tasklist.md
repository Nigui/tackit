# M1 — Local MVP: detailed task list

**Last updated**: 2026-08-10 · **Status**: planning (pre-build) · **Prereq**: M0 complete (see ADR-003)

## Goal & exit criteria (from `03-roadmap.md`)

Turn the M0 spike into an app the founder uses **every day**, local-only, no data loss.

**M1 is done when:**
- Notes persist as real **Markdown + YAML frontmatter** files, editable outside the app; survive quit/relaunch/crash with **zero data loss** (2+ weeks dogfooding).
- Unlimited notes · **⌘O** full-text search + quick-open · **⌘K** action menu · per-note metadata (icon/title/description/group/tags).
- Real note header (design-accurate) · per-window size+position persisted.
- `brew install --cask tackit` works on a clean Mac; app is **signed + notarized**; public repo with MIT + README.
- Time-to-first-keystroke stays **< 300 ms** (CI-gated).

**Legend:** size S(≤½day) · M(~1–2 days) · L(~3–5 days). `[REVIEW:X]` = addresses a finding in `docs/reviews/`.

---

## M1.0 — Foundations & review debt (no user-visible change; unblocks everything)

| ID | Task | Acceptance | Size | Deps |
|----|------|-----------|------|------|
| A1 | **Typed Swift↔JS bridge envelope** — replace fire-and-forget `metrics` channel with a versioned request/response protocol (message id, type, payload, error). Channels: `ready`, `load(noteId, doc)`, `docChanged(noteId, doc, rev)`, `saved`, `error`, `metrics`. `[REVIEW:ENG-2]` | Round-trip request→response with ids; unknown/oversized/malformed messages rejected and logged; unit-tested on both sides. No data path relies on fire-and-forget. | M | — |
| A2 | **Weak-proxy message handler** — break the `userContentController.add(self)` strong-retain so per-window owners don't leak. `[REVIEW:ENG-4]` | No retained webview after its owner is released (instruments/leak test). | S | A1 |
| A3 | **`EditorSurface` protocol seam** — app talks to an editor interface (load/save/focus/reset), not `WKWebView` directly; `WebEditorSurface` is the impl. | AppDelegate/panel reference `EditorSurface`; swapping the impl requires no call-site changes. Enables the CodeMirror fallback + tests. | M | A1 |
| A4 | **Promote `TackitCore` domain model** — `Note`, `NoteMetadata` (id, title, description, icon, group, tags, created, updated), `Group`, `Tag`; all `Codable`/`Sendable`. | Types compile in the UI-agnostic core package; unit tests for equality/coding. | S | — |

**Exit:** bridge is typed and safe, core models exist, review debt (ENG-2/ENG-4) cleared. Still just an empty editor — but now load/save can be built without silent-loss risk.

---

## M1.1 — Persistence (the keystone)

| ID | Task | Acceptance | Size | Deps |
|----|------|-----------|------|------|
| B1 | **Doc format (de)serialization** — `Note` ↔ `Markdown body + YAML frontmatter` via Yams. Frontmatter carries metadata + per-note style; body is portable Markdown. | Golden round-trip: file→Note→file is byte-stable for a fixed corpus; malformed frontmatter degrades gracefully (never crashes, never loses body). | M | A4 |
| B2 | **Note store on disk** — storage root (default `~/Library/Application Support/Tackit/Notes`, overridable later), per-note `<uuid>.md` + `<uuid>.assets/`; **atomic writes** (temp+rename), create/read/update/delete, load-all-index. | Kill -9 mid-save never corrupts a note (fault-injection test); notes are plain files openable in any editor. | L | B1 |
| B3 | **Markdown ↔ ProseMirror-JSON** (in TS) — editor loads md→PM on open, serializes PM→md on change. **vitest golden + fuzz** round-trip. `[REVIEW:SEC-F4]` sanitize on the way in (no `javascript:` hrefs, constrained inline HTML). | Fuzz corpus round-trips without drift for supported nodes; unsupported/unsafe input is neutralized, not executed. | L | A1, A3 |
| B4 | **Wire autosave** — debounced `docChanged` → PM→md → atomic write; open note → read → md→PM → `load`. Crash-safe, last-write-wins within a note. | Type → quit (or crash) → relaunch → **content is there**; measured save latency doesn't regress typing. | M | A1, B2, B3 |
| B5 | **External-change watch** *(optional M1)* — FSEvents on the notes dir; reconcile external edits into open windows. | Editing a note file in another editor updates an open sticky (or is safely deferred with a note in the doc if cut). | M | B2 |

**Exit:** notes survive relaunch as real files. This is the M1 heart — do not proceed to UI polish until B1–B4 pass their tests.

---

## M1.2 — Search & note-switching

| ID | Task | Acceptance | Size | Deps |
|----|------|-----------|------|------|
| C1 | **Search index (GRDB / SQLite FTS5)** — schema (notes, fts, groups, tags); build from disk on launch (rebuildable derived index, not source of truth); incremental update on save/delete. | Index rebuild from N files is correct and fast; deleting the DB and rebuilding loses nothing. | M | B2 |
| C2 | **Search API** — ranked full-text + title/description match; returns note refs. | Query returns expected notes ranked sensibly; sub-50 ms on a few-thousand-note corpus. | S | C1 |
| E1 | **⌘O quick-open palette** — native panel: search field + result list; `Return` opens in current top window, `⌘Return` in a new sticky. | Keyboard-only: open, type, arrow, enter → note opens; distinct from ⌘K. | M | C2, D4 |
| D4 | **Open-last + window switching** — global hotkey restores the working set (last-focused on top); **⌘1–9** switch windows; new-note default placement. | ⌘⇧. with nothing open reopens last note(s); ⌘1–9 cycle; matches `05-interaction-and-keymap.md`. | M | B2, (M0 window layer) |

**Exit:** you can find and jump between any note by keyboard.

---

## M1.3 — Real UI (design-accurate)

| ID | Task | Acceptance | Size | Deps |
|----|------|-----------|------|------|
| D1 | **Note header** — replace the debug gold `DragStrip` with the wireframe header: icon (left) + title + description (2 lines), group chip + tag row below; the header is the drag region. | Matches v3 wireframe; dragging the header moves the window; no gold bar. | M | A4, B4 |
| D2 | **Per-window frame persistence** — `WindowStateStore` keyed by note id (frame + lastFocusedAt + isOpen); restore size/position/z-order per note. `[REVIEW:ENG-5]` | Move/resize a sticky → quit → relaunch → it reopens exactly there; many windows each remembered (single autosave name removed). | M | B2, D4 |
| E2 | **⌘K action menu** — Raycast-style list for the focused note; each row a hotkey: New (⌘N), Close (⌘W), Delete (confirm+undo), Edit metadata, Change icon, Set group, Add tag, Pin, Copy, Export. | Every action works from the menu and its hotkey; Delete is guarded. | M | B2, E3 |
| E3 | **Metadata overlay + group typeahead** — in-sticky modal (blurred content): edit icon/title/description/tags; **group typeahead** (matching dropdown, create-on-blur, empty-group GC); read-only created/updated/location. | Set group by typing → dropdown/select or create; last note leaving a group deletes it; edits persist to frontmatter. | L | B1, C1 |

**Exit:** the app looks and behaves like the approved wireframes.

---

## M1.4 — Settings & rebindable shortcut

| ID | Task | Acceptance | Size | Deps |
|----|------|-----------|------|------|
| F1 | **Settings window** — theme (light/dark/system), accent (gold), default size, **3×3 placement grid**, always-on-top toggle; persisted. | Changes apply live and survive relaunch; placement grid controls where new stickies open. | M | D2 |
| F2 | **Rebindable global shortcut** — real recorder replacing the hardcoded ⌘⇧.; layout-safe. Evaluate adopting `sindresorhus/KeyboardShortcuts` vs keeping the custom Carbon path. | User can rebind the global hotkey and it persists; AZERTY/any-layout safe. | M | (M0 hotkey), F1 |

**Exit:** the app is configurable; no hardcoded shortcut.

---

## M1.5 — Package, sign & ship

| ID | Task | Acceptance | Size | Deps |
|----|------|-----------|------|------|
| G1 | **Buildable/signable project** — real bundle id (`app.tackit.mac` or chosen), app icon; decide committed `.xcodeproj` vs SwiftPM+assembly (impl plan leans `.xcodeproj` for entitlements/signing). | `xcodebuild` produces a runnable, signable `.app`; JS bundle built via a build phase. | M | — |
| G2 | **Developer ID signing + notarization** — `codesign` (hardened runtime) + `notarytool submit --wait` + `stapler staple`; ship a signed `.dmg`. `[REVIEW:SEC-F5]` | Clean Mac launches the `.dmg` with no Gatekeeper block. | M | G1 |
| G3 | **Sparkle auto-update** — appcast + **EdDSA** signing; in-app update channel. `[REVIEW:SEC-F5]` | App updates itself from a signed appcast; tampered updates rejected. | M | G2 |
| G4 | **Homebrew cask** — tap repo + cask stanza (`auto_updates true`, `:sparkle` livecheck). | `brew install --cask tackit` installs and launches. | S | G2 |
| G5 | **CI (GitHub Actions, `macos-26` pinned)** — build, Swift + vitest tests, SwiftLint/ESLint, **<300 ms latency gate**, memory smoke; release automation (tag→build→notarize→appcast→cask bump). | PRs run tests+lint+latency gate; a tag produces a notarized, cask-bumped release. | L | G2, H1–H4 |
| G6 | **OSS hygiene + public repo** — README, CONTRIBUTING, issue/PR templates, SemVer, CHANGELOG; **trademark/name spot-check before going public** (Tackit); flip repo public. | Repo is public, documented, MIT; name cleared. | S | — |

**Exit:** anyone can `brew install --cask tackit`; releases are automated and signed.

---

## Testing (cross-cutting — build alongside, TDD where practical)

| ID | Task | Covers |
|----|------|--------|
| H1 | Core unit tests | frontmatter parse (B1), store atomicity (B2), search (C2), models (A4) |
| H2 | vitest golden + fuzz | Markdown↔PM round-trip + sanitization (B3) |
| H3 | XCUITest end-to-end | hotkey→type→persist→relaunch zero-loss (B4, D2) |
| H4 | CI perf gates | <300 ms first-keystroke + memory smoke for N stickies (G5) |

---

## Deferred beyond M1 (tracked, not in scope)

- **SEC-F3 SSRF guards** — only when link-unfurl/previews ship (M3). Rule to keep now: the webview makes no outbound requests; Swift does any fetching.
- **Snapshot/rehydrate webview pooling** — not needed at measured ~5 MB/webview; revisit when notes carry images (M3).
- **Rich formatting** (tables/colors/paste-image/link-cards), **multi-note panes UI**, **iOS + CloudKit**, **managed cloud** — M2/M3/M4 per roadmap.
- **First-access resource-bundle cold start** — profile on a signed/idle build during G1–G2; likely a non-issue once signed.

---

## Recommended critical path

```
A1 ─┬─ A3 ─┬─ B3 ─┐
A4 ─┘      │      ├─ B4 ──► (notes persist)  ─┬─ C1 ─ C2 ─ E1
B1 ─ B2 ───┴──────┘                            ├─ D1
                                               ├─ D2 ─ F1 ─ F2
                                               └─ E3 ─ E2
G1 (start early, parallel) ─ G2 ─┬─ G3 ─ G4
                                 └─ G5 (needs H1–H4)  ─ G6 ─► ship
```

**Build order:** M1.0 → **M1.1 (stop-and-verify: zero data loss)** → M1.2 → M1.3 → M1.4 → M1.5. Start G1 early (parallel) so signing isn't a last-minute surprise; wire H1–H4 as each feature lands.
