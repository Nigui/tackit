# M0 Engineering Review — Tackit

**Reviewer:** Code Reviewer (engineering pass)
**Date:** 2026-08-10
**Scope:** M0 proof-of-concept (`Sources/TackitApp/*`, `Sources/TackitCore/Note.swift`, `editor/*`, build/packaging).
**Lens:** Correctness, memory/lifecycle, concurrency, failure modes, and the Swift↔JS contract — weighted by whether it causes a real bug or blocks M1 (persistence, many windows, real content).

## Overall read

For an intentionally throwaway spike, this is **healthy, well-structured code**. Concerns are separated cleanly (pool, panel, hotkey, metrics, bridge), the bridge is defensively parsed, the hotkey layout resolution is thoughtful, and failure paths at least *log*. Nothing here is on fire. There are **no crashes or leaks that matter at M0 scale** (a couple of open windows).

The risk is entirely about **M0 patterns that become bugs when M1 multiplies windows and adds persistence**: the webview↔handler retain pattern, the fact that closed webviews are thrown away instead of recycled, a fire-and-forget bridge that has nowhere to put save/load, and silent failure of the app's primary entry point (the hotkey). None are hard to fix; the value of fixing them now is that M1 is built on the right shape.

Legend: 🔴 fix before M1 · 🟡 should fix · 💭 acceptable for a spike.

---

## 🔴 Fix before M1

### 1. WKScriptMessageHandler strong-retain pattern is a latent leak trap
**`WebViewPool.swift:36`** (`controller.add(handler, name: "metrics")`), handler = `AppDelegate` (`AppDelegate.swift:18`, `:110`).

`WKUserContentController.add(_:name:)` retains its handler **strongly**. Today the handler is `AppDelegate`, which is a global singleton (`main.swift:4`) and effectively immortal, so nothing leaks *yet* — and note the pool's `weak var messageHandler` (`WebViewPool.swift:5`) is illusory, since every webview's content controller keeps the handler alive regardless.

Why it matters for M1: the moment a per-window controller (or anything that owns its webview) also becomes the message handler, you get `owner → webview → configuration → userContentController → owner` — a classic WKWebView cycle that leaks a full webview per window. With "many always-on-top windows" this is exactly the shape M1 introduces.

Fix: establish the weak-proxy pattern **now**, while it's one call site:
```swift
final class WeakScriptMessageProxy: NSObject, WKScriptMessageHandler {
    weak var target: WKScriptMessageHandler?
    init(_ t: WKScriptMessageHandler) { target = t }
    func userContentController(_ c: WKUserContentController, didReceive m: WKScriptMessage) {
        target?.userContentController(c, didReceive: m)
    }
}
// controller.add(WeakScriptMessageProxy(handler), name: "metrics")
```
And in teardown call `removeScriptMessageHandler(forName:)` / `removeAllUserScripts()` before discarding a webview.

### 2. Closed webviews are discarded (never recycled), and `pendingFocus` retains the dead one
**`AppDelegate.swift:100-107`** (`closeSticky`), **`AppDelegate.swift:13`/`:82`** (`pendingFocus`), **`WebViewPool.swift`** (no `release`/return API).

On ⌘W the panel is removed and `panel.close()` runs, but the (expensive, pre-warmed) webview is simply dropped; the pool then rebuilds a brand-new one via `scheduleWarm`. So every open→close cycle **destroys a warm webview and pays full WKWebView creation + bundle-load cost to refill** — defeating the pre-warm pool precisely under the churn M1 users generate.

Separately, `pendingFocus` is a **strong** `WKWebView?` set on every open and never cleared. After closing the sticky whose webview was `pendingFocus`, that discarded webview stays alive (holding its content controller → handler) until the *next* open overwrites the reference. One lingering zombie webview at a time.

Fix: give `WebViewPool` a `release(_ webView:)` that resets state (`removeScriptMessageHandler`, reload blank/editor, clear content) and returns it to `warm` up to `size`; call it from `closeSticky`. Make `pendingFocus` `weak`, and clear it in `closeSticky` when it matches the closing panel's webview. Decide a recycle-vs-discard policy deliberately given the M1 memory budget the roadmap calls out.

### 3. Swift↔JS bridge is fire-and-forget — no request/response, IDs, versioning, or errors
**`editor/src/editor.ts:14-20, 34-69`**, **`AppDelegate.swift:96-98, 110-131`**.

M0's bridge only pushes metrics JS→Swift and pokes `window.focusEditor()` Swift→JS with no completion handler (`AppDelegate.swift:97`, errors silently swallowed). That's fine for a latency spike, but M1 must **load a note into the editor and get content back to persist it** — a genuine request/response with correlation IDs, an agreed content shape (ProseMirror JSON per ADR-003), schema/version tags, and error handling for "editor not ready", "save failed", "malformed doc". None of that has a home in the current one-way, untyped `{event, ...}` messages.

Why it matters: retrofitting a real protocol after content flows through the bridge means reworking every call site and risks silent data loss (a dropped save is invisible today). Define the envelope now: `{ v:1, id, type, payload }`, a `postMessage` reply channel or `evaluateJavaScript` with completion + typed decode, and reject/log unknown `v`/`type`.

### 4. Global hotkey registration failure is silently swallowed
**`GlobalHotkey.swift:18-41`**.

`InstallEventHandler` and `RegisterEventHotKey` statuses are only logged (`:41`); nothing is surfaced to `AppDelegate`, and registration proceeds even if `installStatus != noErr`. If ⌘⇧. is already claimed by another app (common for a punctuation combo) the app's **primary entry point is dead** with only a menu-bar fallback and no user-visible signal.

Fix: make the initializer failable or expose a `registered: Bool`/status. Guard `RegisterEventHotKey` on `installStatus == noErr`. Have `AppDelegate` react (menu-bar badge/alert, or offer rebinding — M1 wants a rebindable hotkey anyway). For M0 a visible log is borderline acceptable, but the ignored `installStatus` ordering is a straight bug regardless.

### 5. Frame autosave fights `placeTopRight`, and one autosave name can't serve many windows
**`StickyPanel.swift:52-53`** (autosave only for `index == 0`), **`AppDelegate.swift:79`** (`placeTopRight` on every open).

`setFrameAutosaveName` restores the saved frame during init, then `openNewSticky` immediately calls `placeTopRight(...)` which `setFrameOrigin` unconditionally — so **persisted position is overwritten every launch**. The roadmap explicitly requires position + size "configurable and persisted across launches", so this is a real M1 requirement that the current code structurally prevents. Also, a single shared name (`"TackitStickyM0"`) can't distinguish per-note windows in a multi-window app, and the `Bool` return (name collision) is ignored.

Fix for M1: persist frame per note id (frontmatter/app metadata, not `setFrameAutosaveName`), restore it, and only fall back to `placeTopRight` when there's no saved frame. Acceptable to leave as-is strictly within M0, but flag: don't build M1 window placement on top of autosave.

---

## 🟡 Should fix

### 6. `setValue(false, forKey: "drawsBackground")` — KVC on an undocumented property
**`WebViewPool.swift:41`**.

The transparent-background trick relies on a private-ish KVC key. If the key ever stops existing, `setValue:forKey:` raises an **Objective-C `NSException`** (uncatchable in Swift) → hard crash, not a recoverable error. It's also App-Store-incompatible, which matters at M2 (iOS/App Store) even though M1's direct-download notarization won't flag it. Acceptable for a spike; before M1 wrap it defensively or move to a supported approach (`isOpaque = false` + `underPageBackgroundColor`/CSS `background: transparent`, which the editor already sets) and verify transparency still holds.

### 7. Missing-bundle path yields a silent, blank, non-functional webview — and `run.sh` advertises a fallback that doesn't exist
**`WebViewPool.swift:43-48`**, **`scripts/run.sh:8`**.

If the editor resources aren't found, `makeWebView` logs an error and returns a blank `WKWebView` that loads nothing; the user gets empty stickies with no explanation. Worse, `run.sh:8` prints "Using fallback contenteditable editor" on web-build failure — **there is no such fallback in the code**; the message is misleading. Fix: surface a real user-facing error (or a minimal inline HTML fallback that actually exists), and delete/replace the false log line.

### 8. `acquire()` on an empty pool creates a cold webview synchronously and returns it "warm"
**`WebViewPool.swift:52-62`**.

When `warm` is empty, `acquire()` builds a WKWebView on the spot and hands it back before its bundle has loaded — reintroducing exactly the first-keystroke latency the pool exists to hide, and making focus depend on the `editorCreated`/`pendingFocus` race (`AppDelegate.swift:115-119`). At M0 pool `size = 3` masks this; M1's many-window bursts will exhaust it. Consider: signal "cold" to the caller, or defer focus until `editorCreated`, and size/refill the pool against the real window count.

### 9. Diagnostic logging is unsynchronized and reopens the file per line
**`Diag.swift:9-20`**.

Every `Diag.log` opens → seeks → writes → closes a `FileHandle` with no locking, and the fallback branch (`:18`) `write(to:)` **truncates** the whole file if the handle can't open. Today it's effectively main-thread-serial so it's fine, but M1's background work (persistence, sync) will log concurrently and can interleave/corrupt lines or truncate. Fix: serialize on a dedicated `DispatchQueue`, keep one handle open, and always append. Low urgency, trivial fix.

---

## 💭 Acceptable for a spike (note for later)

- **Stale hotkey keycode on layout change** (`KeyboardLayout.swift`, `GlobalHotkey.swift`): the physical keycode for "." is resolved once at launch; switching keyboard layout at runtime leaves it stale. Fine for M0; M1's rebindable hotkey should re-resolve on `kTISNotifySelectedKeyboardInputSourceChanged`.
- **`swiftLanguageModes: [.v5]`** (`Package.swift:20`): defers all Swift 6 strict-concurrency checking. Reasonable now, but the AppDelegate/webview main-actor assumptions are unchecked; budget for the migration before it hides a real data race.
- **`Note` is not yet wired to anything** (`Note.swift`): two independent `Date()` defaults give `createdAt != updatedAt` by microseconds (`:19-20`), and there's no defined ProseMirror-JSON ↔ Markdown-body mapping yet. Purely M1 work, not an M0 defect.
- **`toggleStickies` is toggle-all-visibility, not "open last note"** (`AppDelegate.swift:53-66`): diverges from the roadmap's "hotkey opens the last-opened note" behavior. M0-acceptable; a deliberate M1 decision, not a bug.
- **`evaluateJavaScript` without a completion handler** (`AppDelegate.swift:97`): swallows JS errors and warns on newer SDKs. Folds into finding #3.
- **Packaging double-copies the resource bundle** (`scripts/run.sh:19-22`) into both `MacOS/` and `Resources/` to satisfy `Bundle.module` resolution. Fragile dev hack; formalize the app-bundle layout for the notarized M1 build.

---

## Bottom line

No M0-blocking defects; the spike does its job and the structure is sound. The five 🔴 items are all "shape" issues — retain/recycle pattern, bridge protocol, hotkey failure handling, window-frame persistence — that are cheap now and expensive after M1 pours windows and persistence on top. Fix those five before starting M1; the 🟡s can ride along; the 💭s are correctly deferred.
