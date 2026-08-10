# 06 — Implementation → Test → Package → Deploy Plan

**Codename:** blazing-fast-memo · **Audience:** solo Swift developer (this is the execution doc)
**Date:** 2026-08-10 · **Status:** Proposed (v1)
**Reads from:** `04-architecture.md` (+ Stickies addendum), `05-interaction-and-keymap.md` (confirmed keymap/behavior)
**Licence:** MIT · **AI features:** out of scope

> Confirmed constraints this plan executes against: borderless always-on-top `NSPanel`; pooled webviews (**K=3** live + native snapshots); md+YAML-frontmatter+`assets/` storage; ProseMirror/TipTap editor loaded **locally** into `WKWebView`; keymap ⌘⇧. (show/hide all, else open last), ⌘N, ⌘K (action menu), ⌘O (quick-open), ⌘W (close), ⌘1–9 (switch).

---

## 1. Repo & project structure

### 1.1 Tooling decisions (decisive)

| Choice | Recommendation | Why |
|---|---|---|
| Repo shape | **Monorepo** (Swift + TS in one git repo) | One version, one release, shared CI; a solo dev has no team-merge cost. |
| Core logic | **SwiftPM package (`core/`)**, UI-agnostic (no AppKit/WebKit) | Reusable verbatim on iOS/later; testable headless. |
| macOS app | **Plain committed `.xcodeproj`** depending on the local `core` package, inside an Xcode **workspace** | The app needs signing, entitlements, Info.plist, Sparkle, notarization — all Xcode-native. Solo dev = no `.xcodeproj` merge pain, so a project generator is premature. |
| Project generator | **Skip Tuist/XcodeGen for now**; adopt **Tuist** only when the iOS target lands (M3) and config is shared | Avoid learning-curve tax before there are two targets to justify it. |
| Web editor build | **TypeScript + ProseMirror/TipTap**, bundled by **esbuild** to one JS + one CSS | esbuild is the simplest/fastest path to a single self-contained IIFE bundle; no dev-server needed for prod. Vite is optional later for a browser dev-harness. |
| JS package manager | **pnpm** | Fast, disk-efficient; npm works too. |
| Key Swift deps | `KeyboardShortcuts` 2.4.0 (Aug 2026), `GRDB.swift` (FTS5), `Yams` (YAML frontmatter), `Sparkle` 2.x | All verified current; each maps to one concern. |

### 1.2 Directory tree (actual)

```
blazing-fast-memo/                     # git root · MIT
├── LICENSE  README.md  CONTRIBUTING.md  CHANGELOG.md  CODE_OF_CONDUCT.md
├── .editorconfig  .gitignore  Makefile
├── .github/
│   ├── workflows/{ci.yml, release.yml}
│   ├── ISSUE_TEMPLATE/{bug_report.yml, feature_request.yml}
│   └── PULL_REQUEST_TEMPLATE.md
├── core/                              # UI-agnostic Swift package (SwiftPM)
│   ├── Package.swift
│   ├── Sources/
│   │   ├── MemoModel/                 # Note, NoteID(UUID), Metadata, Group, PerNoteStyle
│   │   ├── MemoStore/                 # DocumentStore port + FileSystemStore, Frontmatter(Yams),
│   │   │                              #   AssetStore, atomic writes, FileWatcher(DispatchSource)
│   │   ├── MemoSearch/                # SearchIndex port + GRDBSearchIndex (FTS5) + rebuildFromDisk
│   │   ├── MemoSync/                  # SyncEngine port + NoOpSync (P1)
│   │   └── MemoSettings/              # Settings, Keymap, PerNoteStyle, placement grid model
│   └── Tests/{MemoStoreTests, MemoSearchTests, MemoSettingsTests}/
├── editor/                            # web editor (TypeScript)
│   ├── package.json  tsconfig.json  esbuild.mjs
│   ├── src/
│   │   ├── index.ts                   # boot; expose window.MemoEditor API; post `ready`
│   │   ├── schema.ts                  # nodes/marks: heading, list, table, image, codeblock,
│   │   │                              #   linkcard; marks: color, highlight
│   │   ├── bridge.ts                  # webkit.messageHandlers <-> editor commands/events
│   │   ├── serialize.ts               # doc(JSON) <-> markdown body (prosemirror-markdown + ext.)
│   │   ├── inputrules.ts              # `##`->H2, etc.
│   │   └── extensions/…
│   ├── public/index.html              # CSP: block all network; loads editor.js/.css locally
│   ├── test/                          # vitest: round-trip + fuzz; (optional) playwright
│   └── dist/                          # BUILD OUTPUT (gitignored): editor.js, editor.css, index.html
├── mac/                               # macOS app
│   ├── BlazingFastMemo.xcworkspace
│   ├── BlazingFastMemo.xcodeproj
│   ├── App/
│   │   ├── App.swift                  # @main, LSUIElement accessory, pool warm-up on launch
│   │   ├── Capture/                   # KeyboardShortcuts registration + hotkey routing
│   │   ├── Windows/                   # StickyPanel(NSPanel), WindowManager, WindowStateStore
│   │   ├── EditorBridge/              # WebViewPool(K=3), WebEditorView, MemoAssetSchemeHandler,
│   │   │                              #   JSMessage protocol (Swift side)
│   │   ├── Snapshot/                  # inactive-window native renderer + rehydrate
│   │   ├── Palette/                   # ⌘K action menu, ⌘O quick-open
│   │   ├── Config/                    # metadata overlay (modal-in-sticky), group typeahead
│   │   ├── Settings/                  # settings UI, shortcut recorder, 3x3 placement grid
│   │   └── Theme/                     # light/dark/system + accent gold
│   ├── Resources/editor/              # <- editor/dist copied here at build (gitignored)
│   ├── Info.plist                     # LSUIElement=YES, SUFeedURL, SUPublicEDKey, versions
│   └── BlazingFastMemo.entitlements   # hardened runtime; NO app sandbox
├── scripts/
│   ├── bootstrap.sh                   # pnpm install; resolve SPM
│   ├── build-editor.sh               # pnpm --dir editor build  (esbuild -> editor/dist)
│   ├── sign-notarize.sh  make-dmg.sh  sparkle-appcast.sh  release.sh
└── homebrew-tap/                      # (separate repo) Casks/blazing-fast-memo.rb
```

### 1.3 How the JS bundle reaches WKWebView (locally, no network)

1. **Build:** `scripts/build-editor.sh` runs esbuild → `editor/dist/{editor.js, editor.css, index.html}`.
2. **Xcode hook:** a **Run Script build phase** on the app target (ordered *before* "Copy Bundle Resources") runs `build-editor.sh` and syncs `editor/dist` → `mac/Resources/editor`. Declare **input file lists** (`editor/src/**`, `editor/package.json`) and **output files** (`Resources/editor/editor.js` …) so Xcode skips the step when nothing changed (esbuild is <1s anyway). `editor/dist` and `Resources/editor` are gitignored — CI and local both build them; documented in CONTRIBUTING.
3. **Load locally:**
   ```swift
   let dir = Bundle.main.resourceURL!.appendingPathComponent("editor")
   webView.loadFileURL(dir.appendingPathComponent("index.html"), allowingReadAccessTo: dir)
   ```
   `index.html` carries a strict CSP (`default-src 'self'; connect-src 'none'`) so the editor can never hit the network.
4. **Assets:** serve pasted images via a **`WKURLSchemeHandler`** (`memo-asset://<noteid>/<hash>.png`) reading from the note's `assets/` folder — cleaner than widening file read-access, and it keeps asset access explicit.

### 1.4 Swift ↔ JS ownership split (decisive)

- **Frontmatter (metadata + per-note style):** owned by **Swift** (`MemoStore` + Yams). Fully testable headless.
- **Body markdown ↔ ProseMirror JSON:** owned by **JS** (`serialize.ts`, prosemirror-markdown + color/highlight/table extensions). The editor is web on every platform anyway, so duplicating a converter in Swift buys nothing and risks drift. **Round-trip/fuzz authority lives in vitest** (§4).
- **On save:** JS posts `{docJSON, markdownBody, plainText}`; Swift writes `frontmatter + markdownBody` to the `.md` file and indexes `plainText`.
- **On open:** Swift splits frontmatter (Swift) from body (string), hands body markdown to JS to parse.

**Bridge message protocol (define once, freeze early):**

| Direction | Message | Payload |
|---|---|---|
| Swift→JS | `loadDoc` | `{ markdownBody, style }` |
| Swift→JS | `exec` | `{ command, args }` (bold, insertTable, setColor, setHighlight, …) — drives ⌘K actions |
| Swift→JS | `setEditable` / `focus` / `applyStyle` | booleans / style |
| Swift→JS | `requestSave` | `{}` → JS replies `saved` |
| JS→Swift | `ready` | editor booted (pool marks webview hot) |
| JS→Swift | `firstInput` | signpost for latency measurement |
| JS→Swift | `docChanged` (debounced) | `{ docJSON, markdownBody, plainText }` |
| JS→Swift | `saved` | `{ docJSON, markdownBody, plainText }` |
| JS→Swift | `pasteImage` | `{ bytesBase64, mime }` → Swift writes asset, returns `memo-asset://…` |
| JS→Swift | `openLink` | `{ url }` → Swift opens externally / builds link card natively |

---

## 2. M0 PoC plan (rescoped per the Stickies addendum)

**Goal:** de-risk the single biggest bet — that a **pooled** web editor inside a borderless always-on-top non-activating panel can hit the interaction budget. Throwaway spike on branch `spike/m0`; not productionized.

**Timebox: 5 working days.** If not conclusive by day 5, that itself is a signal (favor the lighter fallback).

### 2.1 Deliverable (must demonstrate all five)

1. **⌘⇧.** global hotkey (via `KeyboardShortcuts` 2.4.0) → shows a **visually-borderless, non-activating, `.floating`** `NSPanel` at **top-right**, **resizable**, with **frame persisted** across relaunch (custom store keyed by a note id).
2. **First-keystroke < 300 ms**, measured hotkey-down → first char painted, served from a **warm pool spare** (a pre-loaded webview taken from the pool), **not** one dedicated always-alive webview. A replacement spare is warmed asynchronously afterward.
3. **≥ 2 simultaneous stickies**, each an independent window, with a **live memory readout** of each WebContent process + the app.
4. **Snapshot → rehydrate:** blur a sticky (release its webview to the pool, show a native snapshot), refocus (rehydrate from pool) — **no visible flash**.
5. **⌘1 / ⌘2** switching and **open-last-note** when the target window was previously closed.

### 2.2 Instrumentation

- **Latency:** `os_signpost` intervals across `hotkeyDown → panelOnScreen → webviewAttached → editorFocused → firstInput(JS)`. Run **20 trials**, report **P50/P95** in Instruments (Points of Interest). Budget = P95(`hotkeyDown → firstInput`) < 300 ms **on the dev's real Mac**.
- **Memory:** sample `phys_footprint` (via `proc_pid_rusage`/`task_info`) for the app + each WebContent process; tabulate at **1, 2, 3, 5, 10** stickies (10 = K live + snapshots).
- **Focus/Space behavior:** manual verification that typing never activates the app or switches Spaces, and ⌘-Tab still cycles other apps while stickies stay on top.

### 2.3 Go / No-Go exit criteria

**GO if all hold on real hardware:**
- P95 first-keystroke **< 300 ms** via the warm-spare path.
- With **K=3** live webviews + snapshots, total footprint at ~10 stickies stays within budget (**target: app + web processes < ~700 MB**; per live editor ≈ 60–120 MB as estimated — confirm).
- Snapshot→rehydrate shows **no visible flash**.
- Non-activating + key-to-type + all-Spaces behavior works cleanly.

**NO-GO / data-driven fallback triggers:**
- P95 > 300 ms even with a warm spare → **switch editor to CodeMirror 6** (much lighter bundle, faster boot) and re-measure before committing to ProseMirror/TipTap.
- Per-live-webview footprint ≫ estimate (e.g. > 150 MB) so K=3 blows budget → **reduce K** and/or make the **inactive renderer fully native** (render markdown natively, hydrate a webview only on active edit).
- Non-activating key-focus can't be made reliable → revisit the window approach before building M1 on it.

**Output:** a one-page decision note (`docs/decisions/ADR-003-m0-results.md`) recording the numbers and the editor/K decision.

---

## 3. M1 build breakdown (sequenced, grouped by module, with dependencies)

Legend: **[C]** core package · **[A]** app · **[E]** editor JS. Arrows = depends-on.

### Phase A — Foundations (build first; everything depends on these)
1. **[C] Package + CI skeleton** — `core` builds & tests green in CI; lint wired. *(dep: none)*
2. **[C] MemoModel** — `Note`, `NoteID (UUID)`, `Metadata`, `Group`, `PerNoteStyle`. *(dep: 1)*
3. **[E] Editor bundle MVP + serialize.ts** — TipTap boot, `##`→H2 input rules, `docChanged`/`ready`, **markdown↔JSON serialization** + its vitest round-trip tests. *(dep: none; parallelizable with 1–2)*
4. **[C] MemoStore / FileSystemStore** — dir layout (`notes/`, `assets/`, `.index/`), **frontmatter parse/serialize (Yams)**, **atomic writes** (temp-file + `rename`), **AssetStore** (content-hash dedupe), **FileWatcher** (`DispatchSource`/FSEvents) to reconcile external edits. *(dep: 2)*
5. **[C] MemoSearch / GRDBSearchIndex** — `notes` table + **FTS5** external-content virtual table (unicode61+porter, bm25), index-on-save, **rebuildFromDisk**, corrupt/missing-DB recovery. *(dep: 2,4)*
6. **[C] MemoSettings + MemoSync(NoOp)** — settings model, keymap defaults, placement-grid model; `SyncEngine` port with `NoOpSync`. *(dep: 2)*

### Phase B — Window & editor shell (consumes M0 learnings)
7. **[A] StickyPanel + WindowManager + WindowStateStore** — `NSPanel` subclass (§ below), 380px default, top-right placement, resize, always-on-top; **WindowStateStore** keyed by NoteID: `{frame(+screen), lastFocusedAt, isOpen}`; z-order = order by `lastFocusedAt`; `shouldCascadeWindows=false`; new-note offset if slot occupied. *(dep: 6)*
8. **[A] WebViewPool (K=3) + WebEditorView + Snapshot** — shared `WKProcessPool`, warm spare, LRU recycle; snapshot on blur (`WKWebView.takeSnapshot` or native render) + rehydrate on focus; `MemoAssetSchemeHandler`. *(dep: 7, and M0)*
9. **[A]↔[E] Editor bridge** — implement the frozen message protocol both sides; wire `docChanged`/`saved` → MemoStore + MemoSearch; `pasteImage` → AssetStore. *(dep: 3,4,5,8)*
10. **[A] Capture** — `KeyboardShortcuts` registration; **⌘⇧.** show/hide-all (else open-last), **⌘N** new note at default placement, pool warm-up at launch. *(dep: 7,8,9)*

### Phase C — Navigation & note actions
11. **[A] ⌘O quick-open** — search palette over MemoSearch (fuzzy title/desc/body); `Return` = open in top window, `⌘Return` = new sticky. *(dep: 5,7,9)*
12. **[A] ⌘K action menu** — Raycast-style list scoped to focused note; rows show hotkeys; actions: New (⌘N), Close (⌘W), **Delete (confirm + undo)**, Configure, Change icon, Set group, Add tag, Pin, Copy, Export → many dispatch `exec` to the editor. *(dep: 9,10)*
13. **[A] ⌘W close** — remove from open set (file untouched); update WindowStateStore. *(dep: 7)*

### Phase D — Metadata, settings, theming
14. **[A] Metadata config overlay** — modal-in-sticky (content blurred behind), edit icon/title/description/group/tags; read-only created/updated/sync-status/source. *(dep: 4,12)*
15. **[A] Group typeahead + empty-group GC** — dropdown of existing groups; blur-to-create; **auto-delete empty groups** when last note leaves. *(dep: 4,14)*
16. **[A] Settings** — global hotkey + full shortcut list via `KeyboardShortcuts.Recorder`; default size; **3×3 placement grid**; always-on-top toggle; theme (light/dark/system) + **accent gold** (`#F0B90B`/`#FFD21A`). *(dep: 6)*
17. **[A] Theming** — apply theme/accent across panels + editor (push to JS via `applyStyle`); focused-sticky accent border/shadow. *(dep: 8,16)*

### NSPanel spec (from `04` addendum, restated for the coder)
`NSPanel` subclass · styleMask `[.nonactivatingPanel, .titled, .fullSizeContentView, .resizable, .closable, .miniaturizable]` → then `titlebarAppearsTransparent=true`, `titleVisibility=.hidden`, hide the 3 standard buttons, `isMovableByWindowBackground=true` (visually borderless but keeps key-ness + edge resize; pure `.borderless` returns `canBecomeKey=false`). `level=.floating`; `becomesKeyOnlyIfNeeded=true`; `collectionBehavior` default `.moveToActiveSpace` (option: `[.canJoinAllSpaces,.fullScreenAuxiliary]`); app is `LSUIElement`.

---

## 4. Testing strategy

| Layer | Tool | What it guards |
|---|---|---|
| Core unit | Swift Testing / XCTest | **File round-trip** (write→read a note preserves frontmatter+body+assets), **frontmatter parse** (Yams edge cases), **search** (index → query → ranked hits, rebuildFromDisk, corrupt-DB recovery). |
| **Markdown ↔ ProseMirror-JSON** | **vitest** (JS) | **Golden round-trip** on a fixture corpus (headings, tables, colors, highlights, images, code, link cards) + **property/fuzz** (generate random valid docs → serialize → parse → assert deep-equal). This is the #1 correctness guardian for portability; authority lives here because serialization is JS-owned (§1.4). |
| Editor behavior | vitest (+ optional **Playwright** headless) | input rules (`##`→H2), commands (`exec`), paste-image path, schema invariants. |
| Integration / UI | **XCUITest** | **hotkey → type → persist → reopen** shows same content; ⌘O open; ⌘W close; ⌘1/⌘2 switch; metadata overlay. |
| **Latency gate** | custom perf harness | Instrumented Release build runs the pooled-open path N times, records P95(`hotkeyDown→firstInput`). **On the dev's Mac: absolute < 300 ms.** **On CI (virtualized, noisier): regression detector** — compare to a committed baseline, fail if > +20%. Never gate a hard 300 ms on CI hardware. |
| Memory smoke | custom harness | UI-drive N stickies (1,3,10), sample `phys_footprint`, assert < budget; nightly, not per-PR. |

CI-runner caveat noted: GitHub macOS runners are VMs — treat perf/memory numbers as **trends**, validate absolutes locally.

---

## 5. Packaging & distribution

**Pipeline (verified current Aug 2026):** Developer ID sign → notarize (`notarytool`) → staple → DMG → Sparkle appcast (EdDSA) → Homebrew cask.

### 5.1 Sign + notarize + DMG
1. **Cert:** *Developer ID Application* (not App Store). **Hardened runtime** on; entitlements file with **no app sandbox** (we rely on non-sandboxed global hotkey).
2. **Sign inside-out:** sign embedded frameworks (Sparkle) first, then the app, all with `--options runtime --timestamp`. Verify: `codesign --verify --deep --strict` + `spctl -a -vvv`.
3. **DMG:** build with `create-dmg`; place the already-signed `.app` inside.
4. **Notarize the DMG:**
   ```
   xcrun notarytool store-credentials MEMO_NOTARY --apple-id … --team-id … --password <app-specific>   # once, or use an App Store Connect API key (--key) in CI
   xcrun notarytool submit BlazingFastMemo.dmg --keychain-profile MEMO_NOTARY --wait
   xcrun stapler staple BlazingFastMemo.dmg
   ```

### 5.2 Sparkle 2.x auto-update (out-of-App-Store)
- **Keys:** `Sparkle/bin/generate_keys` → **EdDSA (ed25519)** keypair (DSA-only is unsupported). Public key → Info.plist `SUPublicEDKey`; private key → Keychain / CI secret.
- Info.plist: `SUFeedURL` → hosted `appcast.xml`; embed & sign Sparkle in the app.
- **Appcast:** `Sparkle/bin/generate_appcast <dir-of-updates>` signs each update (EdDSA) and writes `appcast.xml`. Host `appcast.xml` + the DMG on **GitHub Releases** (or a CDN).
- Sparkle coexists with Developer ID + notarization — the delivered DMG is the same notarized artifact.

### 5.3 Homebrew Cask (personal tap)
- Separate repo **`<user>/homebrew-tap`** (avoids homebrew-cask acceptance/notability criteria for a new app). Users: `brew install <user>/tap/blazing-fast-memo`.
- Cask stanza: `version`, `sha256`, `url` (GitHub release DMG), `app "BlazingFastMemo.app"`, **`auto_updates true`** (verified: casks whose app self-updates via Sparkle must set this so `brew upgrade` doesn't fight Sparkle), and `livecheck` with the **`:sparkle`** strategy pointing at the appcast.
- **Versioning:** SemVer. `CFBundleShortVersionString` = marketing (e.g. `0.3.1`); **`CFBundleVersion` = monotonic integer** build number (Sparkle compares this). Tag `v0.3.1`.

### 5.4 Release steps (happy path)
`bump version → tag v* → CI: build editor+app (Release) → sign → DMG → notarize → staple → Sparkle sign + generate_appcast → GitHub Release (DMG+appcast) → bump cask sha256/version in tap`.

---

## 6. CI/CD (GitHub Actions, macOS runners)

**Runner:** pin **`macos-15`** or **`macos-26`** explicitly (do **not** use `macos-latest`). *(Verified: `macos-26` GA 2026-02-26, native arm64 + Intel, Xcode 26.x incl. 26.4.1 default; becomes `macos-latest` from 2026-06-15. `macos-15` still supported but newest Xcode may be absent due to disk limits.)* Select Xcode via `xcode-select`/`xcodes`.

### 6.1 `ci.yml` (on PR + push to main)
1. Checkout; setup **pnpm + Node**; setup Swift/Xcode.
2. **Editor:** `pnpm install`, `pnpm build`, `pnpm test` (vitest round-trip+fuzz), ESLint + Prettier `--check`.
3. **Core:** `swift build`, `swift test`; **SwiftLint** + **SwiftFormat `--lint`**.
4. **App:** `xcodebuild build-for-testing` + **XCUITests** (unsigned/dev-signed).
5. **Latency gate** (regression vs committed baseline) + **memory smoke** — best-effort/nightly, not a hard PR blocker.

### 6.2 `release.yml` (on tag `v*`)
1. Build editor + app (Release).
2. **Import signing cert:** decode `DEVELOPER_ID_P12` (base64 secret) → temp keychain, unlock, import, set partition list; **clean up keychain** in a trailing `always()` step.
3. Sign (inside-out) → `create-dmg` → **notarize** (App Store Connect API key secrets: `NOTARY_KEY`, `NOTARY_KEY_ID`, `NOTARY_ISSUER`) `--wait` → `stapler staple`.
4. **Sparkle:** sign update with EdDSA (`SPARKLE_ED_PRIVATE_KEY` secret) → `generate_appcast`.
5. Create **GitHub Release**, upload DMG + `appcast.xml`.
6. **Bump cask** in `homebrew-tap` (push/PR via `HOMEBREW_TAP_TOKEN`): new `version` + `sha256`.

**Secrets inventory:** `DEVELOPER_ID_P12`, `P12_PASSWORD`, `KEYCHAIN_PASSWORD`, `NOTARY_KEY`/`NOTARY_KEY_ID`/`NOTARY_ISSUER` (or Apple-ID + app-specific password + team-id), `SPARKLE_ED_PRIVATE_KEY`, `HOMEBREW_TAP_TOKEN`.

---

## 7. OSS repo hygiene

- **LICENSE** — MIT (© 2026 <author>). State MIT + "AI features out of scope" in README scope.
- **README** — one-paragraph what/why; screenshot/GIF of the sticky flow; **install** (`brew install <user>/tap/blazing-fast-memo`) + **build-from-source** (pnpm + Xcode steps); keymap table; roadmap (P1 local → P2 CloudKit → P3 backend).
- **CONTRIBUTING** — dev setup (Node/pnpm + Xcode versions), `make bootstrap`, how the JS bundle builds into the app, code style (SwiftLint/SwiftFormat, ESLint/Prettier), commit convention, DCO sign-off.
- **CODE_OF_CONDUCT** (Contributor Covenant), **issue templates** (bug/feature YAML forms), **PR template** (checklist: tests, lint, changelog).
- **SemVer** + **CHANGELOG.md** (Keep a Changelog format), `.editorconfig`.

---

## 8. Risks + first-week checklist

### 8.1 Top execution risks & mitigations
| Risk | Mitigation |
|---|---|
| **Pooled-webview latency/memory** miss the budget | M0 answers it before any real build; CodeMirror-6 / native-inactive-renderer fallback pre-defined. |
| **Markdown↔PM round-trip fidelity** (color, tables, per-note style) | vitest golden + **fuzz from day one** (task A3); non-standard color as HTML-valid spans that degrade gracefully. |
| **Non-activating panel focus/Spaces** correctness across macOS versions | Verified in M0; use the transparent-titlebar `NSPanel` (not pure borderless) to keep `canBecomeKey`. |
| **Signing/notarization/Sparkle pipeline friction** (notoriously fiddly) | De-risk **early**: ship a throwaway "hello-world" notarized + Sparkle-updating DMG in week 1, before feature work depends on it. |
| **Solo-dev dual-stack (Swift+TS) drift** | Freeze the bridge protocol early; keep the JS surface small behind one API; CI covers both stacks. |
| CI runner perf noise misreads latency | Absolute 300 ms validated locally; CI gate is a **regression** detector only. |

### 8.2 First-week checklist (concrete, day-by-day)
- **Day 1 — Scaffold.** git init (MIT LICENSE, README/CONTRIBUTING stubs); monorepo tree; `core` SwiftPM package builds; `editor` esbuild builds a hello bundle; `ci.yml` green (build+lint both stacks).
- **Day 2 — M0 window layer.** `KeyboardShortcuts` ⌘⇧. → transparent-titlebar non-activating `.floating` `NSPanel`, top-right, resizable, frame persisted; verify typing doesn't steal focus/Space, ⌘-Tab works.
- **Day 3 — M0 pooled editor.** WebViewPool K=3 + warm spare; load TipTap locally; instrument `os_signpost`; measure P95 first-keystroke over 20 trials.
- **Day 4 — M0 multi + memory + rehydrate.** ≥2 stickies with `phys_footprint` readout at 1/2/3/10; snapshot→rehydrate no-flash; ⌘1/⌘2 + open-last-note.
- **Day 5 — Decision + pipeline de-risk.** Record `ADR-003-m0-results.md` with numbers + GO/NO-GO (editor engine, K); **in parallel**, stand up the hello-world **signed + notarized + Sparkle** DMG to prove the release pipeline before M1.

---

## Appendix — verified facts (Aug 2026)
- `KeyboardShortcuts` **2.4.0** — global hotkeys, no Accessibility permission for a plain hotkey, built-in SwiftUI recorder.
- **Sparkle 2.x** — EdDSA (ed25519) required; DSA-only unsupported; coexists with Developer ID + notarization.
- **notarytool** — `store-credentials` / `submit --wait` / `xcrun stapler staple`; App Store Connect API key usable in CI.
- **Homebrew cask** — Sparkle-updating apps set **`auto_updates true`**; `livecheck` `:sparkle` reads the appcast; personal tap avoids core-cask acceptance criteria.
- **GitHub macOS runners** — `macos-26` GA **2026-02-26** (arm64+Intel, Xcode 26.x), default `macos-latest` from **2026-06-15**; `macos-15` still available. Pin explicitly.
- **GRDB.swift** — FTS5 virtual tables + custom tokenizers; system `libsqlite3` ships FTS5 enabled (no custom SQLite build).
