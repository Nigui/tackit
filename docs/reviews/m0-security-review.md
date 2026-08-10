# Tackit M0 — Application Security Review

**Scope:** M0 proof-of-concept — native Swift menu-bar agent (not sandboxed, unsigned ad-hoc build, distributed outside the App Store) hosting a pool of `WKWebView`s that load a local TipTap/ProseMirror bundle via `loadFileURL`, plus a Swift↔JS `WKScriptMessageHandler` bridge and a Carbon global hotkey.
**Reviewer:** AppSec Engineer
**Date:** 2026-08-10
**Verdict:** Nothing here is exploitable *today* because all rendered content is first-party and local. The review is almost entirely about **trajectory** — the roadmap (M1 persistence, then pasted images, rendered links/link-cards, cloud sync) turns note content into attacker-influenced input, and this webview is currently configured like a mini web browser with local-file access and no origin controls. The single cheapest, highest-leverage thing to do now is lock the webview down (CSP + no-remote-load + navigation delegate) while there is no product behavior to break.

## How to read the horizons

Every finding is tagged with when it must be resolved:

- **[M0-OK]** — acceptable for a spike; note it, don't block on it.
- **[PRE-M1]** — must be fixed **before persistence / any untrusted or synced content renders**. This is the critical band: it is cheap now and expensive to retrofit once content is untrusted.
- **[PRE-DIST]** — must be fixed **before any public/external distribution**.

Severity reflects the risk *on the trajectory*, not just today. Likelihood is the chance of exploitation once the relevant content surface ships.

---

## Findings (ranked by severity)

### F1 — WebView has no Content-Security-Policy (defense-in-depth is entirely absent) — HIGH (Critical by M1) · Horizon: PRE-M1

**Where:** `editor/src/index.html` — the document ships no `<meta http-equiv="Content-Security-Policy">`, and no CSP is applied Swift-side either. Confirmed: no CSP string exists anywhere in the repo.

**Risk.** Today the only content is the first-party bundle, so there is nothing to inject. The moment note bodies, an "inline-HTML subset for color" (per `docs/04-architecture.md` §on storage), pasted content, remote link-card HTML, or synced documents are rendered, **any injected markup executes with no safety net**: an `<img onerror>`, an inline `<script>`, a `javascript:` href, or a remote `<img>/<script>/fetch` runs in a webview that also has local-file read access. Consequences: script injection (XSS) into the editor, and **data exfiltration** of note content to an attacker origin via a remote resource load. CSP is the layer that limits the blast radius of every injection bug you have not found yet.

**Why fix now, not at M1.** A CSP added while content is trusted costs one `<meta>` tag and a few minutes tuning against the TipTap bundle. Added after untrusted content ships, it means auditing every feature (images, link cards, color HTML) against the policy and risks breaking them — retrofit, not bake-in.

**Remediation.** Add a strict, no-remote CSP to the loaded HTML now and tighten it as features land:

```
default-src 'none';
script-src 'self';
style-src 'self' 'unsafe-inline';
img-src 'self' data:;
font-src 'self';
connect-src 'none';
base-uri 'none';
form-action 'none';
object-src 'none';
frame-src 'none';
```

Notes:
- `script-src 'self'` with **no** `'unsafe-inline'` neutralizes injected inline `<script>` and inline event handlers — the dominant XSS vectors.
- `connect-src 'none'` + no remote `img-src` blocks exfiltration channels. The native `window.webkit.messageHandlers` bridge is **not** subject to CSP `connect-src`, so `'none'` will not break the metrics bridge.
- `style-src 'unsafe-inline'` is a pragmatic concession: TipTap/ProseMirror inject inline styles. Acceptable — inline style is a far weaker vector than inline script. Revisit with nonces later if desired.
- `img-src 'self' data:` supports locally-stored pasted images and data-URI thumbnails while keeping remote image loads (a classic exfil/tracking channel) off. Remote link-card images must be fetched and cached **natively** into the per-note `assets/` folder and referenced locally (see F3), never loaded remotely by the webview.

**Durable version (recommended architecture change, PRE-M1 or PRE-DIST):** migrate from `loadFileURL` to a custom `WKURLSchemeHandler` (e.g. an internal `tackit-editor://` scheme). This gives the page a **stable, non-`file://` origin** (CSP `'self'` and `connect-src` behave predictably, unlike `file://` origin quirks in WebKit), makes Swift the mediator of *every* resource the webview loads, and eliminates any temptation to enable the file-access footguns in F8. This is the single chokepoint that makes CSP, no-remote-load, and SSRF-safety all enforceable in one place.

---

### F2 — No `WKNavigationDelegate`: the editor can be navigated to arbitrary remote or `file://` targets — HIGH (Critical by M1) · Horizon: PRE-M1

**Where:** `Sources/TackitApp/WebViewPool.swift` `makeWebView()` sets no `navigationDelegate`. No navigation is filtered.

**Risk.** With no navigation policy, a link click, a `window.location = …`, a `<meta refresh>`, or a form submission inside note content can navigate the webview away from the local bundle to **an attacker's https origin** (which then runs with whatever access the webview has) or to **another `file://` path** (traversal / reading unintended local files depending on read-access scope). Combined with F1's absence of CSP, this is the "your editor is now a browser pointed at attacker content, on the user's machine, unsandboxed" scenario. Today there are no links to click, so likelihood is low; it becomes High the moment rendered links ship.

**Remediation.** Add a navigation delegate that pins the webview to exactly the local editor document and refuses everything else:

- Allow the **initial** editor-document load only.
- For any other main-frame navigation: **cancel** it. If the target is `http(s)`, open it in the user's default browser via `NSWorkspace.shared.open(url)` instead of navigating in-app (this is also how link-cards/links should behave — the note surface never becomes a web browser).
- Cancel all `file://` navigations after the initial load (no traversal).
- Implement `decidePolicyFor navigationAction` (scheme + URL allowlist) and `decidePolicyFor navigationResponse`. Set `webView.allowsLinkPreview = false` and, on macOS, consider `configuration.limitsNavigationsToAppBoundDomains` with a `WKAppBoundDomains` entry as belt-and-suspenders.

Doing F1 + F2 together is the "bake it in now" posture the rest of this review keeps referring to.

---

### F3 — Server-Side Request Forgery via link unfurling (design-time risk) — HIGH · Horizon: PRE-untrusted-content (before the link-card phase)

**Where:** Not yet built. `docs/04-architecture.md` describes rich link cards with cached OG metadata/images. Whatever component performs the unfurl (must be **native/Swift**, never the webview) is an SSRF sink.

**Risk.** A link is attacker-controlled data (typed by the user, pasted, or arriving via sync). If the unfurler blindly fetches the URL, a note containing `http://169.254.169.254/latest/meta-data/…`, `http://localhost:…`, `http://[::1]`, or an internal `http://10.x/…` turns every user's machine into an SSRF pivot — hitting cloud metadata endpoints, localhost admin services, or the user's LAN, and exfiltrating the response into the note card.

**Remediation (design the fetcher safely from the first line):**
- Native fetch only; the webview must never make the outbound request (`connect-src 'none'` from F1 enforces this).
- Scheme allowlist: `https` (and maybe `http`) only. Reject everything else.
- Resolve DNS and **block** loopback, private (RFC 1918), link-local `169.254.0.0/16` (incl. `169.254.169.254`), ULA/`::1`, and other non-routable ranges — re-check after DNS resolution to defeat DNS rebinding.
- Disable automatic redirect following, or re-run the allowlist/IP check on **every** hop.
- Cap response size, set aggressive timeouts, strip credentials, send a distinct non-browser User-Agent.
- Rasterize/re-encode cached OG images natively before writing to `assets/`; never trust the remote content type. Store by content hash (matches the architecture's dedupe plan).

---

### F4 — No defined sanitization boundary for untrusted content (HTML color subset, pasted SVG, `javascript:` links) — HIGH · Horizon: PRE-untrusted-content (PRE-M1 to define, enforce as each feature lands)

**Where:** `editor/src/editor.ts` uses `StarterKit` only today (no Link/Image extensions yet). The architecture calls for a "small, documented inline-HTML subset for color," pasted images, links, and synced HTML.

**Risk.** ProseMirror's schema is *itself* a decent sanitizer — pasted/loaded HTML is coerced into allowed nodes/marks — **but only as long as the schema stays tight and the extensions added are safe**. Three concrete footguns on the roadmap:
1. **`javascript:` / `data:` link hrefs.** When the Link extension is added, TipTap/ProseMirror have a documented history of `javascript:`-URL XSS. An href is attacker data.
2. **Inline-HTML color subset.** Any path that injects raw HTML (rather than schema-validated marks) to achieve color reopens full HTML injection.
3. **Pasted SVG images.** SVG is active content — it can embed `<script>`. If pasted images can be SVG and are rendered inline, that is script execution.

**Remediation.**
- Treat everything from disk, paste, and sync as **untrusted**; sanitize to the ProseMirror schema at that boundary (Core/Swift side preferably, so the trust boundary is native, not JS).
- Link extension: enforce a scheme allowlist (`http`, `https`, `mailto`) via TipTap's `validate`/`isAllowedUri` option; reject `javascript:`, `data:`, `vbscript:`.
- Implement "color" as a constrained **mark with an enumerated/validated value** (hex or named palette), never as raw inline HTML. If raw inline HTML is truly required, run it through an allowlist sanitizer (DOMPurify) with a tiny tag/attr allowlist and no event handlers.
- Disallow SVG as an inline image type, or rasterize on paste. Restrict image sources to the local `assets/` folder + `data:` (aligned with F1's `img-src`).
- This boundary is exactly where CSP (F1) is the backstop for the bugs the sanitizer misses. Defense in depth: schema + sanitizer + CSP.

---

### F5 — Unsigned/un-notarized distribution, placeholder identity, and no update-integrity design — HIGH · Horizon: PRE-DIST

**Where:** `scripts/run.sh` (assembles `Tackit.app` by copying an unsigned `tackit` binary; no `codesign`, no notarization, no stapling). `packaging/Info.plist` uses placeholder `com.example.tackit`. Future Sparkle updater not yet present.

**Risk.**
- **Gatekeeper bypass training.** An unsigned/un-notarized app forces users to right-click-open or run `xattr -d com.apple.quarantine` — teaching your users to disable the OS's malware defense for your app. That habit is itself the vulnerability.
- **No tamper-evidence.** Without a code signature, the bundled `bundle.js` and binary can be silently swapped by any local process or a compromised download mirror. A signed+notarized app with Hardened Runtime makes resources tamper-evident.
- **Update channel = the biggest future RCE surface.** An auto-updater that is not cryptographically verified is a SolarWinds-class remote-code-execution channel into every install.
- **Placeholder bundle ID** `com.example.tackit` must become a real, owned identifier before any signing/notarization/iCloud entitlement work (Phase 2 CloudKit depends on a real App ID).

**Remediation (PRE-DIST):**
- Developer ID sign + notarize + staple; enable **Hardened Runtime**; ensure `get-task-allow` is false in release; request only entitlements actually needed.
- Real bundle identifier under a domain you control.
- **Sparkle 2 with EdDSA (Ed25519) signed appcasts served over HTTPS only**; ship `SUPublicEDKey`; verify signatures before applying; never accept an unsigned or plaintext-HTTP appcast. Design this in before the first shipped auto-update, not after.
- Fix the assembly script structure: `run.sh` copies the resource bundle into **both** `Contents/MacOS/` and `Contents/Resources/`. A resource bundle under `Contents/MacOS/` is non-standard and will break code signing's code/resource separation. Put resources only under `Contents/Resources/`. **[M0-OK to defer, but PRE-DIST to fix.]**

---

### F6 — Swift↔JS bridge: no schema validation, no origin/frame check; single "metrics" channel is fine now but the pattern will not scale safely — MEDIUM · Horizon: PRE-M1 (before the bridge carries any privileged operation)

**Where:** `Sources/TackitApp/AppDelegate.swift` `userContentController(_:didReceive:)`; channel registered in `WebViewPool.makeWebView()` as `"metrics"`.

**Assessment (current).** Low blast radius today: the handler only reads `event` (String) and `latency` (Double), records metrics, logs a fixed string, and requests editor focus. It does not pass message data into any file, shell, eval, or query sink, and it does not reflect content back. Malformed input is dropped by the `guard`/`as?` casts. So a compromised page could at most pollute latency metrics and the log — not touch the native side meaningfully. **[The current bridge is M0-OK.]**

**Risk (trajectory).** The design pattern — "cast `body` to `[String:Any]`, `switch` on a stringly-typed `event`, read fields ad hoc" — is exactly the shape that becomes dangerous when the bridge grows to carry save/load/delete, file paths, or document payloads (which M1 requires: "Swift owns saving, indexing, and sync"). There is no message schema, no versioning, no size bound, and no verification of **which frame/origin** sent the message.

**Remediation (before the bridge does anything privileged):**
- Decode messages through a typed, validated model (e.g. `Codable`/enum with associated values), not `[String:Any]` + `switch`-on-string. Reject unknown events, over-long strings, and oversized payloads.
- Check `message.frameInfo.isMainFrame` and validate `message.frameInfo.securityOrigin` before honoring any privileged command, so a future embedded iframe / injected frame cannot drive the native side.
- Keep channels **least-privilege and segregated**: a low-trust `metrics` channel stays telemetry-only; privileged operations (save/open/delete) go on a separate channel with strict validation. Never let one broad channel do both.
- Every command that names a path or note ID must be authorized/normalized native-side (no path traversal into other notes) — enforce a per-note scope.

---

### F7 — Private-API access via KVC: `setValue(false, forKey: "drawsBackground")` — LOW/MEDIUM (stability & compatibility) · Horizon: PRE-DIST

**Where:** `Sources/TackitApp/WebViewPool.swift:41`.

**Risk.** `drawsBackground` is an undocumented `WKWebView` property poked via KVC. Not a memory-safety issue, but: (a) App Store rejection — **not a target here, noted per the brief**; (b) **runtime fragility** — if a future macOS renames/removes the key, KVC throws `NSUnknownKeyException` and the app crashes at webview creation (i.e., on launch), and this is unsigned/unsandboxed code with no review gate to catch it. It is a supported-surface and reliability concern more than a security one.

**Remediation.** Prefer the supported transparent-background path (`webView.underPageBackgroundColor = .clear` on macOS 12+, combined with the page's existing `background: transparent` CSS in `index.html`). If the KVC hack is still needed for full transparency, isolate it and fail safe: guard so that a KVC failure degrades to an opaque background rather than crashing the app, and pin/verify the behavior per macOS release. Low urgency for M0; clean it up before shipping.

---

### F8 — File-access scope is correct today; keep the WebKit file-access footguns off and keep read-access minimal per note — LOW (informational / keep-good-posture) · Horizon: PRE-M1

**Where:** `Sources/TackitApp/WebViewPool.swift:45` — `loadFileURL(indexURL, allowingReadAccessTo: editorDir)`.

**Assessment.** This is **done right** and worth protecting: read access is scoped to the `editor` resource subdirectory, **not** the home directory or `/`. Equally important, the dangerous WebKit preferences — `allowFileAccessFromFileURLs` and `allowUniversalAccessFromFileURLs` — are **not** set, so they remain at their safe `false` defaults. No universal file access, no arbitrary-JS-into-native path.

**Risk (trajectory).** When M1 introduces the per-note `assets/` folder, the tempting shortcut is to widen `allowingReadAccessTo` to the whole notes directory. Combined with F1 (no CSP) and F2 (no nav delegate), that would let a malicious note `fetch()`/`<img>` sibling notes and assets via `file://` and exfiltrate them. And never enable `allowFileAccessFromFileURLs`/`allowUniversalAccessFromFileURLs` to "make images load" — that reintroduces universal local-file read into untrusted content.

**Remediation.** Keep read-access **as narrow as possible** — ideally per-note (grant only the single note's `assets/` folder), or better, serve assets through the custom scheme handler (F1) so no raw `file://` read scope is exposed to the page at all. Add a code comment / lint asserting the two file-access prefs stay `false`. (Requested exception to the no-comments rule: this one is a security guardrail — confirm before adding.)

---

### F9 — Logging: blanket `privacy: .public`, unbounded plaintext file log, placeholder subsystem — LOW (now) / MEDIUM (as content grows) · Horizon: PRE-M1

**Where:** `Sources/TackitApp/Diag.swift`.

**Assessment (current).** Today the log carries only metadata — window rects, key codes, timings, memory, "editor bundle loaded", "hotkey fired". **No note content is logged today.** So no leak currently. **[M0-OK.]**

**Risk (trajectory).** Two design smells that leak once content flows through debugging:
1. `logger.notice("\(message, privacy: .public)")` marks **everything** public in the unified log — persisted, and readable via Console/`log stream`. The first time someone logs a note title, body, or file path to debug a save, it lands in the system log in the clear.
2. The custom file at `~/Library/Logs/tackit-m0.log` is plaintext, **written unconditionally (incl. release), never rotated or size-capped** → unbounded growth, and a durable plaintext sink for whatever gets logged.
3. Subsystem is the placeholder `com.example.tackit`.

**Remediation (before persistence):** Establish a logging policy: never pass user/note content to `Diag`; default dynamic interpolation to `.private` and mark only known-safe metadata `.public`; gate the file log (and verbose logging) behind a debug flag; add rotation + a size cap; use the real subsystem id. Add a redaction helper so content-bearing values can't accidentally be logged public.

---

### F10 — Build/supply-chain hygiene — LOW · Horizon: PRE-DIST (some PRE-M1)

**Where:** `scripts/run.sh`, `scripts/build.sh`, `editor/` (pnpm).

**Observations & remediation.**
- **Positives:** `pnpm-lock.yaml` is committed (versions pinned); `build/` is git-ignored so no compiled binary is committed (verified — working tree clean, `build/` in `.gitignore`).
- `run.sh`/`build.sh` run `pnpm install --silent` — use `pnpm install --frozen-lockfile` in any release/CI build to prevent silent lockfile drift or dependency substitution; drop `--silent` in CI so integrity failures are visible.
- `run.sh`'s "Using fallback contenteditable editor" message is **misleading** — no such fallback exists in the tree, so a failed web build silently ships a stale or absent `bundle.js`. Make a failed editor build a hard error for release.
- Before distribution: add `pnpm audit` (SCA) to CI and produce an SBOM. The app is majority third-party JS (TipTap/ProseMirror/StarterKit/esbuild); their advisories are your advisories (see F4 re: TipTap link XSS history).
- Non-standard bundle placement in `run.sh` (also noted in F5) will break code signing — fix as part of the signing work.

---

### F11 — Global hotkey / input handling — INFORMATIONAL (no action) · Horizon: all

**Where:** `Sources/TackitApp/GlobalHotkey.swift`, `KeyboardLayout.swift`, `editor/src/editor.ts` keydown handler.

**Assessment.** No concern, and worth recording so it isn't re-litigated:
- Carbon `RegisterEventHotKey` registers a **single specific chord** (Cmd+Shift+.). It is **not** a keylogger and, unlike `CGEventTap`, requires **no Accessibility (TCC) permission** — the app cannot observe other keystrokes. The handler only toggles UI.
- `KeyboardLayout` uses TIS/`UCKeyTranslate` to read the current layout — no permission, no input capture.
- The web-side `keydown` listener in `editor.ts` posts **timing only** (`latency`), never `event.key`/keystroke content — good; keep it that way. No keystroke content should ever cross the bridge or hit logs.

---

## Positives to preserve (don't regress these)

- Minimal `loadFileURL` read scope (editor dir only) — F8.
- WebKit file-access footgun prefs left at safe `false` defaults — F8.
- `WKWebView` runs content in a **separate WebContent process** — the native side already has a process boundary against renderer compromise. As sync/untrusted content lands, keep untrusted notes on a **non-persistent `WKWebsiteDataStore`** and consider per-untrusted-note process isolation.
- Bridge is read-only telemetry today — F6.
- Keystroke handler leaks no key content — F11.
- Lockfile pinned; no binary committed — F10.

---

## The one thing to do now

**Bake in the locked-down webview posture — F1 + F2 together — before any untrusted content renders.** Concretely, while content is still trusted and there is nothing to break:

1. Add the strict, **no-remote-load** CSP (F1) to `index.html` (or via the response when you move to a scheme handler).
2. Add a `WKNavigationDelegate` (F2) that pins the webview to the local editor document and routes every external link to the system browser.
3. Adopt the design rule that **the webview never makes an outbound network request** — Swift performs all remote fetches (link unfurls, OG images) with SSRF protections (F3) and hands back locally-cached, sanitized assets.

That trio is a few hours of work today and is the difference between "the untrusted-content phases are a configuration change" and "the untrusted-content phases are a security retrofit."

## Suggested sequencing

- **Before M1 merges (untrusted content boundary):** F1, F2, F6, F8, F9. Define F4's sanitization boundary even if extensions aren't in yet.
- **Before the link-card / remote-fetch phase:** F3, and enforce F4 as Link/Image/color extensions land.
- **Before any public distribution:** F5, F7, F10.
- **Track to closure with SLAs:** High = 30 days once the enabling feature is in flight; design-time items (F3, F4) resolved *before* the feature branch opens, not after.
