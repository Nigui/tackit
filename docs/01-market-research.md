# blazing-fast-memo — Market & Competitor Research

_Research date: 2026-08-10. Facts are current as of research; pricing and version-specific claims are dated inline where they matter. Sources are linked inline; uncertainty is flagged explicitly._

## Executive summary

The note-taking market splits into two camps that rarely overlap: **fast, keyboard-driven quick-capture tools** (Raycast Notes, Drafts, Heynote, Apple Quick Note) that are shallow on formatting and organization, and **rich knowledge bases** (Obsidian, Notion, Craft, Bear, UpNote) that are powerful but heavier to open and navigate. Raycast Notes — the primary inspiration — owns "capture in <1s from a global hotkey" but is deliberately minimal: text-only (no image paste, no tables), one note visible at a time, sync locked behind Raycast Pro, and Mac/iOS/Windows only inside Raycast's ecosystem. The clear whitespace is a tool that keeps Raycast's sub-second launch and keyboard-first flow **while adding the rich-content and multi-note capabilities of Bear/Craft (tables, colors, image paste, link previews, panes/tabs) on top of open, local-first Markdown files that the user owns** — something no single competitor delivers today. This document profiles ~18 products against the spec dimensions, then synthesizes the gap, the risks, and concrete takeaways.

---

## Methodology & caveats

- Sources are a mix of official product pages/docs, Wikipedia, and reputable reviews. Where only third-party reviews were available, facts are labeled accordingly.
- Pricing is volatile. All prices below were reported for 2025-2026; **re-verify before quoting externally.**
- Some vendor claims (e.g., "unlimited," "local-first") are marketing; I note where the reality is more nuanced.
- Feature depth was prioritized for the products closest to the product vision (Raycast Notes, Bear, Craft, Obsidian, UpNote, Drafts, Heynote).

---

## Product deep dives

### 1. Raycast Notes — the primary inspiration

**One-liner / positioning:** "Fast, light and frictionless note-taking" that lives one hotkey away as a floating window above your apps ([Raycast blog](https://www.raycast.com/blog/raycast-notes), [core-features/notes](https://www.raycast.com/core-features/notes)).

**Target user:** Mac power users already in the Raycast launcher ecosystem; developers, PMs, founders who want zero-friction scratch capture.

**Capture speed / hotkey:** Best-in-class. A single global hotkey toggles the Notes window; `Create Note` opens a fresh note instantly. Auto-sizing floating window that sits above other apps. This is the reference standard for "capture in flow" ([manual](https://manual.raycast.com/notes)).

**Formatting model:** Markdown-driven with four input paths — Markdown syntax, keyboard shortcuts, Action Panel (`⌘K`), and an on-screen Format Bar. Supports headings (1-3), bold/italic/strikethrough/underline, inline code, code blocks, blockquotes, ordered/bullet/task lists, horizontal rules, links, emoji picker ([manual](https://manual.raycast.com/notes)). **No tables. No text colors.** Historically **text-only, no inline image paste** ([search-sourced summary of Raycast Notes limitations](https://www.raycast.com/blog/raycast-notes)); an "attachment" feature was referenced around v1.86 but inline image/photo rendering is not a confirmed, first-class capability — **treat image support as absent/uncertain and verify.**

**Style/theme customization:** Inherits Raycast's global theme; no per-note styling, fonts, or colors.

**Multi-note viewing:** "A notepad with multiple pages" — **one note visible at a time.** You pin notes (`⌘0`–`⌘9`) and navigate back/forward, but there are **no tabs, panes, or multi-note windows** ([manual](https://manual.raycast.com/notes)). This is a major UX limitation vs. Obsidian/Bear.

**Image/photo paste:** Not a first-class feature (see formatting). Key gap.

**Link rendering:** Standard Markdown links; no rich/short link previews (unfurled cards).

**Metadata:** Minimal — title, pinning slots, browsing history. **No tags, notebooks, folders, icons, or descriptions** as first-class organizers. Search is by title/content.

**Note-count limits:** **Free = 5 notes; unlimited requires Raycast Pro** ([core-features/notes](https://www.raycast.com/core-features/notes)).

**Custom shortcuts:** Deep keyboard control via Action Panel; **Quicklinks** let you jump to a specific note from anywhere with one keystroke ([blog](https://www.raycast.com/blog/raycast-notes)).

**Storage model:** Notes stored in an **encrypted local database** (not user-visible plain files). Export per-note to plain text, Markdown, or HTML; can share to Apple Notes ([reported](https://www.raycast.com/core-features/notes)).

**Sync model:** **Raycast Cloud Sync, end-to-end encrypted, Pro-only.** Free plan is local/single-machine. Cloud Sync (public beta) now spans macOS, Windows, and iOS ([Cloud Sync manual](https://manual.raycast.com/cloud-sync), [Windows changelog](https://www.raycast.com/changelog/windows)).

**Platforms + roadmap:** macOS (mature); **iOS shipped 2025** (the "Raycast: AI, Notes and more" App Store app includes Notes, Snippets, Quicklinks, AI) ([Raycast for iOS](https://www.raycast.com/ios)); **Windows public beta from 2025-11-20**, with Notes/AI arriving on Windows "in coming months" ([Windows blog](https://www.raycast.com/blog/raycast-for-windows), [Windows changelog](https://www.raycast.com/changelog/windows)).

**iOS widgets/Siri/Shortcuts:** Raycast iOS exists but Notes-specific widgets/Siri/Shortcuts depth is limited; not a strength.

**Open source:** **No — proprietary core.** Only the Extensions API/extensions are open ([Wikipedia](https://en.wikipedia.org/wiki/Raycast_(software))).

**Pricing:** Raycast free tier (5 notes); **Raycast Pro ~$8/mo annual, ~$10/mo monthly (2026)** unlocks unlimited notes + Cloud Sync ([pricing](https://www.raycast.com/pricing)).

**Install:** Direct download / Homebrew cask (`raycast`); iOS via App Store.

**Does WELL:** Instant global-hotkey capture; keyboard-first everything; clean minimal editor; Quicklinks to jump to notes; tight launcher integration. **Does POORLY:** no tables/colors/images; single-note view (no panes/tabs); no tags/notebooks; sync + unlimited paywalled behind a broader Pro bundle; not local files you own; not open source; locked to the Raycast app rather than a standalone note experience.

---

### 2. Drafts — "where text starts" (quick-capture benchmark)

**Positioning:** Capture text instantly, then send it anywhere via Actions ([getdrafts.com](https://getdrafts.com/)). **Target:** Apple-ecosystem power users, automation nerds. **Capture:** Opens to a blank note with keyboard/dictation ready; menu-bar + global shortcut on Mac; excellent lock-screen/widget capture on iOS. **Formatting:** Markdown/plain text with syntax-aware editor; not WYSIWYG; no tables/colors as rich objects. **Multi-note:** Drafts list + workspaces, single editor pane. **Images:** limited; text-first tool. **Metadata:** tags, flags, workspaces. **Shortcuts:** the standout — 50+ Apple Shortcuts actions, deep Action scripting (JavaScript) ([MacStories review](https://www.macstories.net/reviews/drafts-5-mac/)). **Storage/sync:** own store, fast iCloud-based sync across iPhone/iPad/Mac/Watch. **Platforms:** **Apple-only** (no Windows/Android/web). **Pricing:** free tier; **Drafts Pro $1.99/mo or $19.99/yr** ([Drafts Pro](https://docs.getdrafts.com/draftspro)). **Open source:** No. **MacStories 2025 App of the Year.** **WELL:** frictionless capture + unmatched automation/Shortcuts. **POORLY:** thin rich formatting; Apple-only; not local Markdown files; automation has a learning curve.

### 3. Heynote — developer scratchpad (fast-capture benchmark, OSS)

**Positioning:** "A dedicated scratchpad for developers/power users" — one persistent buffer ([heynote.com](https://heynote.com/), [GitHub](https://github.com/heyman/heynote)). **Capture:** global hotkey to a persistent buffer; near-instant. **Formatting model:** buffer split into **blocks, each with its own language** (Markdown, JSON, JS...) with syntax highlighting; **Math blocks** act as a calculator with variables/units/currency. **Images:** **supports inline images via paste or drag-and-drop.** **Multi-note:** default Scratch buffer + create unlimited buffers (`⌘N`), move block to new buffer (`⌘S`). **Metadata:** minimal (buffers, blocks). **Storage:** local files. **Sync:** none built-in (bring your own folder sync). **Platforms:** macOS, Windows, Linux (desktop only; no mobile). **Open source:** **Yes** (CodeMirror/Vue/Electron/Math.js). **Pricing:** free/OSS. **WELL:** ultra-fast, block-language model, math, images, truly local, free. **POORLY:** no mobile, no sync, no tables/colors, developer-niche UX, no organization beyond buffers.

### 4. Bear — closest "beautiful Markdown" competitor

**Positioning:** Beautiful, flexible Markdown notes for Apple users ([bear.app](https://bear.app/)). **Target:** writers, students, Apple-first users wanting polish without Notion complexity. **Capture:** fast native app; Apple Shortcuts integration; no cross-app global-hotkey capture as central as Raycast's. **Formatting:** polished Markdown with live styling; **tables, checklists, code blocks with 150+ language syntax highlighting, LaTeX math**, Apple Pencil sketching ([ClickUp review](https://clickup.com/blog/bear-vs-evernote/)). **Theme customization:** strong — multiple themes, typography, focus mode (a differentiator). **Multi-note:** single main editor; nested tags in sidebar; no true multi-pane. **Images/PDF:** yes, inline; **OCR search inside photos/PDFs (Pro).** **Link rendering:** WikiLinks and note-to-note linking. **Metadata:** **nested/hashtag tags** (its signature), pinning, encryption per note. **Storage:** **SQLite database** (accessible on macOS, sandboxed on iOS) — **not portable plain files** ([Bear FAQ](https://bear.app/faq/where-are-bears-notes-located/)). **Sync:** **iCloud (CloudKit)** only. **Platforms:** **Apple-only** (macOS/iOS/iPadOS); no web/Windows/Android as of 2026 ([Wikipedia](https://en.wikipedia.org/wiki/Bear_(app))). **iOS widgets/Shortcuts:** yes. **Open source:** No. **Pricing:** free single-device; **Pro $2.99/mo or $29.99/yr** for sync + premium ([ClickUp](https://clickup.com/blog/bear-vs-evernote/)). **Install:** App Store. **WELL:** best-looking Markdown editor, tags, themes, tables, OCR. **POORLY:** Apple-only lock-in; DB not portable files; not open source; capture not as instant/global as Raycast; no multi-pane.

### 5. Craft — rich, block-based, native documents

**Positioning:** Beautiful native block-based docs with real-time collaboration ([MacStories](https://www.macstories.net/reviews/craft-review-a-powerful-native-notes-and-collaboration-app/)). **Target:** teams, writers wanting Notion polish with native speed. **Capture:** fast native apps; daily-note calendar; widgets/Shortcuts for quick add. **Formatting:** rich blocks (text, images, video/audio embeds), Markdown support, styling, page nesting, backlinks. **Multi-note:** documents + sidebar; card/preview navigation. **Images/media:** first-class embeds. **Link rendering:** rich linking between docs. **Metadata:** documents, links, daily notes. **Storage/sync:** proprietary cloud sync (not user-owned plain files). **Platforms:** Mac, iPhone, iPad, **Windows, Android, web** ([research.com](https://research.com/software/reviews/craft-docs)). **iOS widgets/Shortcuts:** **yes — Quick Open / Recent Documents widgets + Apple Shortcuts** ([Craft help](https://support.craft.do/hc/en-us/sections/15275577889948-Shortcuts-and-Widgets)). **Open source:** No. **Pricing:** free = 1,500 blocks; **Plus ~$8/mo annual** ([research.com](https://research.com/software/reviews/craft-docs)). **WELL:** stunning native UX, media-rich, widgets, cross-platform. **POORLY:** proprietary/closed data; block cap on free; heavier than a quick-capture tool; not Markdown-file-native.

### 6. UpNote — cross-platform, one-time-purchase Markdown

**Positioning:** Clean cross-platform notes with notebooks + Markdown ([UpNote FAQ](https://help.getupnote.com/resources/upnote-premium/premium-faqs)). **Capture:** fast, quick-access, notes filter; no standout global hotkey. **Formatting:** Markdown + rich text, **tables**, code syntax highlighting, focus mode. **Multi-note:** nested notebooks, pinning, filters; single editor. **Images/attachments:** yes (**Premium**). **Metadata:** notebooks, tags, links. **Storage/sync:** proprietary local DB + own sync across Mac/Windows/iOS/Android/web. **Free limits:** **50 notes; no attachments/tables/limited export on free** ([SaaSworthy](https://www.saasworthy.com/product/getupnote)). **Open source:** No. **Pricing:** **$1.99/mo or one-time $39.99 lifetime** (rare lifetime option). **WELL:** cheap lifetime price, all platforms, notebooks + tables. **POORLY:** proprietary format; free tier restrictive; capture speed unremarkable; not open.

### 7. Apple Notes — the default incumbent

**Positioning:** Free built-in notes across Apple devices ([MacRumors guide](https://www.macrumors.com/guide/apple-notes/)). **Capture:** **Quick Note** via hot-corner or `⌘Q`-style shortcut, from any app; extremely convenient on Apple hardware. **Formatting:** rich text, checklists, **tables**, drawings, scanned docs; **not Markdown-native — Markdown import/export only arriving in iOS 26 (2025)**, no Markdown composing ([MacRumors, 2025-06-04](https://www.macrumors.com/2025/06/04/apple-notes-rumored-markdown-support-ios-26/)). **Multi-note:** open notes in separate windows on Mac; folders + smart folders; **nested tags**. **Images/media:** first-class. **Link rendering:** basic. **Metadata:** folders, tags, pinning, shared folders/collaboration. **Storage/sync:** **iCloud**, proprietary. **Platforms:** Apple-only (+ iCloud web). **Widgets/Siri/Shortcuts:** deep. **Open source:** No. **Pricing:** free. **WELL:** zero-cost, instant Quick Note, deep OS integration, reliable sync. **POORLY:** no true Markdown authoring, weak for developers/power formatting, proprietary lock-in, Apple-only, limited theming, no rich link previews.

### 8. Notion — the all-in-one workspace

**Positioning:** Blocks + databases workspace for docs, wikis, projects ([notion.com/pricing](https://www.notion.com/pricing)). **Capture:** **slow — ~4-6s** because you must choose a page/DB destination ([review-sourced](https://www.notion.com/releases/2025-08-19)). **Formatting:** everything-is-a-block; rich, databases, embeds. **Offline:** native offline mode added **Aug 2025**, but limited (first 50 DB rows per view, sub-pages toggled individually) ([Notion 2.53 release](https://www.notion.com/releases/2025-08-19)). **Performance:** degrades on large DBs (>1,000 related items, noticeable >5,000 rows). **Multi-note:** tabs, side-peek, nested pages. **Storage/sync:** cloud-only proprietary. **Platforms:** Mac/Win/web/iOS/Android. **Open source:** No. **Pricing:** Free (individuals) / Plus / Business / Enterprise. **WELL:** flexibility, databases, collaboration. **POORLY:** slow capture, laggy at scale, online-first, not local-first, overkill for quick memos.

### 9. Obsidian — local-first Markdown PKM leader

**Positioning:** Local-first Markdown knowledge base you own ([Wikipedia](https://en.wikipedia.org/wiki/Obsidian_(software))). **Target:** PKM enthusiasts, developers, researchers. **Capture:** desktop app launch is fast but not a global-hotkey scratchpad by default (plugins/Advanced URI needed); mobile quick-capture weaker. **Formatting:** **plain Markdown files**, Live Preview (near-WYSIWYG), tables, code, math (MathJax); **Bases** (database-like views) and **Canvas** (infinite spatial board) are core plugins ([search-sourced](https://aiproductivity.ai/blog/obsidian-pricing/)). **Colors:** via CSS themes/plugins, not inline text color natively. **Style/theme:** **huge** — community themes + CSS + plugin ecosystem (its superpower). **Multi-note:** **excellent — tabs, split panes, pop-out windows, linked panes.** **Images:** paste/drag into vault as files. **Link rendering:** `[[wikilinks]]`, backlinks, graph view; rich URL unfurling via plugins. **Metadata:** YAML frontmatter (tags, properties, dates, aliases), folders, tags. **Storage:** **your own folder of `.md` files** — maximal portability/ownership. **Sync:** free via iCloud/Dropbox/Git/Syncthing, or **Obsidian Sync ~$4-5/mo** (E2EE, AES-256). **Platforms:** Mac/Win/Linux/iOS/Android. **Open source:** **No** (proprietary but free; plugins/themes are open). **Pricing:** **free for personal AND commercial** (commercial-license requirement dropped Feb 2025); optional Sync/Publish add-ons ([eesel](https://www.eesel.ai/blog/obsidian-pricing)). **Install:** direct download / Homebrew cask. **WELL:** true file ownership, extensibility, panes/tabs, graph, massive community. **POORLY:** setup/plugin complexity, not fast quick-capture out of the box, mobile capture weaker, native tables/colors clunky, not truly open source.

### 10. Logseq — local Markdown outliner

**Positioning:** Outliner-first, block-based PKM with bidirectional links ([search-sourced](https://toolchase.com/tool/logseq/)). **Formatting:** every bullet is a block; Markdown/Org files; PDF annotation, flashcards (spaced repetition), Datalog queries. **Multi-note:** journal-first + right sidebar; outliner navigation. **Storage:** **local Markdown/Org files.** **Sync:** iCloud/Dropbox/Git/Syncthing or **Logseq Sync ~$5/mo (E2EE)**. **Platforms:** Mac/Win/Linux/iOS/Android. **Open source:** **Yes (AGPL).** **Pricing:** free; DB-version rewrite ongoing 2025-26. **WELL:** outliner + queries + local files + OSS. **POORLY:** outliner paradigm not for everyone; performance/DB-rewrite churn; capture not global-hotkey-instant.

### 11. Anytype — local-first, encrypted, object-based

**Positioning:** Local-first, E2EE, P2P workspace; "everything is an object with types + relations" ([productivity.directory](https://productivity.directory/anytype), [any-sync GitHub](https://github.com/fullstackinfo/anytype-any-sync)). **Storage:** encrypted local store, **not plain Markdown files**; **P2P sync (AnySync)**, offline-first. **Encryption:** zero-knowledge, 12-word recovery key. **Platforms:** Mac/Win/Linux/iOS/Android. **Open source:** **Yes (client OSS; Swiss Any Association nonprofit).** **Pricing:** free local; hosted backup/sync tier (~$5/mo for storage, verify). **WELL:** ownership + encryption + Notion-like flexibility + OSS. **POORLY:** proprietary encrypted store (not portable `.md`); learning curve; capture not instant; younger ecosystem.

### 12. Standard Notes — privacy-first encrypted notes

**Positioning:** E2EE, zero-knowledge, open-source notes ([standardnotes.com/features](https://standardnotes.com/features)). **Formatting:** plain/Markdown/rich/code/tasks/spreadsheets via editors (advanced editors are paid). **Metadata:** nested folders, tags, pinning, archiving, Smart Views; per-note password. **Storage/sync:** E2EE zero-knowledge cloud sync across iOS/Android/web/desktop. **Platforms:** all major. **Open source:** **Yes.** **Pricing:** freemium; **Productivity ~$90/yr, Professional ~$120/yr (100GB)** ([plans](https://standardnotes.com/plans)). **WELL:** security, longevity, OSS, cross-platform. **POORLY:** editors paywalled; plain-first UX unremarkable; capture not global-hotkey-fast; formatting depth behind subscription.

### 13. Joplin — open-source Evernote alternative

**Positioning:** Open-source, offline-first notebooks + Markdown with E2EE ([knightli overview](https://knightli.com/en/2026/05/30/joplin-open-source-note-taking-app/)). **Formatting:** advanced Markdown editor + optional Rich Text; math, diagrams; media/PDF; plugins + themes. **Metadata:** notebooks, tags. **Storage/sync:** local + sync via Nextcloud/Dropbox/OneDrive/**Joplin Cloud**; E2EE. **Platforms:** Mac/Win/Linux/iOS/Android + terminal. **Open source:** **Yes.** **Pricing:** app free; Joplin Cloud from ~€2.4-6.69/mo. **WELL:** free/OSS, self-host, plugins, cross-platform. **POORLY:** utilitarian/dated UX; Markdown files wrapped in its own structure; capture not instant; polish lags Bear/Craft.

### 14. Simplenote — minimalist, free (now in maintenance)

**Positioning:** Free, cross-platform plain-text notes with instant sync (Automattic) ([toolstack](https://toolstack.io/tools/simplenote)). **Formatting:** plain text + Markdown, tags, version history. **Storage/sync:** Simperium real-time sync. **Platforms:** Mac/Win/Linux/iOS/Android/web. **Open source:** **Yes (GPLv2).** **Pricing:** free. **Status:** **Automattic ended active development (announced ~March 2026)** — maintenance/bug-fixes only, no new features ([WebProNews](https://www.webpronews.com/simplenotes-quiet-death-how-automattics-cost-cutting-left-millions-of-users-scrambling-for-a-new-notes-app/)). **WELL:** free, simple, fast sync, OSS. **POORLY:** feature-frozen; no images/tables/rich formatting; no folders; no future roadmap. (A cautionary tale about free-forever sustainability.)

### 15. Notesnook — E2EE, open-source, full-featured

**Positioning:** Zero-knowledge, open-source private notes ([notesnook.com](https://notesnook.com/)). **Formatting:** advanced editor — **tables**, code w/ highlighting, callouts, outlines, math/chemistry, Markdown shortcuts, note version history. **Images/attachments:** yes. **Encryption:** XChaCha20-Poly1305 + Argon2. **Storage/sync:** E2EE cross-platform. **Platforms:** Win/macOS/Linux/iOS/Android/web. **Open source:** **Yes (AGPLv3, apps + sync server; self-hostable).** **Pricing:** Free (50MB/mo) / Essential $1.99/mo / Pro $6.99/mo / Believer $8.99/mo. **WELL:** rich formatting + E2EE + OSS + self-host + cross-platform. **POORLY:** encrypted store (not portable `.md`); capture not global-hotkey-instant; free storage tiny.

### 16. Reflect — networked, encrypted, AI notes

**Positioning:** Minimalist AI note-taking for networked thought, E2EE, fast sync ([Votars review](https://votars.ai/en/blog/reflect-review-2025/)). **Formatting:** clean Markdown-ish editor, backlinks, daily notes. **Metadata:** backlinks, calendar (Google/Outlook) integration. **AI:** transcription, outlines, summaries. **Storage/sync:** E2EE cloud. **Platforms:** Mac/Win/iOS/web. **Open source:** No. **Pricing:** **single plan ~$10/mo billed annually.** **WELL:** speed, backlinks, encryption, AI, calendar. **POORLY:** pricey single tier; not local files; not open; capture not global-hotkey-first.

### 17. Amie — quick-capture meets calendar (adjacent)

**Positioning:** Beautiful calendar + task capture; **pivoted 2025 toward AI meeting notes/recorder** ([ClickUp review](https://clickup.com/blog/amie-calendar-review/)). **Capture:** fast task/event capture with NLP; shortcuts. **Platforms:** web/macOS/iOS (no Android as of 2025). **Open source:** No. **Pricing:** ~$12-15/mo. **Relevance:** shows the market's appetite for frictionless capture + AI meeting notes, but it's a calendar/meeting tool, not a note editor — an adjacent signal, not a direct competitor.

---

## Comparison table

Legend: Y = yes, N = no, ~ = partial/plugin/paid, ? = unconfirmed. "Local files" = user-owned plain files (usually `.md`).

| Product | Global-hotkey capture | Rich fmt (tables/colors) | Image paste | Multi-note panes/tabs | Link previews | Tags/notebooks | Local files (own `.md`) | Sync model | Platforms | iOS widgets/Siri | Open source | Price (2025-26) |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| **Raycast Notes** | **Y (best)** | N tables / N colors | N (?) | N (1 at a time) | N | N | N (enc DB) | Raycast Cloud (Pro, E2EE) | mac, iOS, Win(beta) | ~ | N | Free 5 notes / Pro ~$8/mo |
| Drafts | Y | N | ~ | ~ | N | Y | N | iCloud | Apple only | Y | N | Free / $1.99/mo |
| Heynote | Y | N tables / N colors | **Y** | ~ (buffers) | N | N | **Y** | none | mac/Win/Linux | N | **Y** | Free |
| Bear | ~ | **Y** | Y | N | N (wikilinks) | **Y** | N (SQLite) | iCloud | Apple only | Y | N | Free / $2.99/mo |
| Craft | ~ (widgets) | Y | Y | ~ | Y | Y | N | Cloud | mac/iOS/Win/Android/web | Y | N | Free(1500 blk)/~$8/mo |
| UpNote | ~ | Y (Pro) | Y (Pro) | N | ~ | Y | N | Own cloud | mac/Win/iOS/Android/web | ~ | N | $1.99/mo or $39.99 lifetime |
| Apple Notes | **Y (Quick Note)** | Y (tables) / N colors | Y | ~ (windows) | ~ | Y | N | iCloud | Apple only | Y | N | Free |
| Notion | N (~4-6s) | Y | Y | Y (tabs/peek) | Y | Y | N | Cloud | all | Y | N | Free / tiers |
| Obsidian | ~ (plugin) | ~ tables / ~ colors | Y | **Y (best)** | ~ (plugin) | Y | **Y** | iCloud/Git/Sync $4-5 | mac/Win/Linux/iOS/Android | ~ | N (free) | Free + add-ons |
| Logseq | ~ | ~ | Y | ~ | ~ | Y | **Y** | Git/iCloud/Sync $5 | all | **Y (AGPL)** | Free |
| Anytype | ~ | Y | Y | ~ | Y | Y | N (enc) | P2P/E2EE | all | ~ | **Y** | Free / ~$5/mo |
| Standard Notes | ~ | ~ (paid) | ~ | ~ | N | Y | N (enc) | E2EE cloud | all | ~ | **Y** | Free / ~$90-120/yr |
| Joplin | ~ | Y | Y | ~ | ~ | Y | ~ | Nextcloud/own/Cloud | all | ~ | **Y** | Free / cloud €2.4+ |
| Simplenote | ~ | N | N | N | N | Y | N | Simperium | all | ~ | **Y** | Free (frozen) |
| Notesnook | ~ | **Y** | Y | ~ | ~ | Y | N (enc) | E2EE cloud | all | ~ | **Y** | Free / $1.99-8.99/mo |
| Reflect | ~ | ~ | Y | ~ | Y | Y (backlinks) | N | E2EE cloud | mac/Win/iOS/web | ~ | N | ~$10/mo |

_Cells marked `~`/`?` are partial or unverified — see per-product notes. Verify pricing before external use._

---

## Where Raycast Notes is strong — and where it's weak (the gaps to exploit)

**Strong (match or beat, don't regress):**
1. **Sub-second global-hotkey capture** with an auto-sizing floating window above other apps. This is the north star and the reason people love it.
2. **Keyboard-first everything** — Action Panel (`⌘K`), Format Bar, shortcuts, and **Quicklinks** to jump straight to a specific note.
3. **Minimal, distraction-free editor** with clean Markdown formatting.
4. **Export flexibility** (txt/md/HTML) and E2EE sync (for Pro).

**Weak (the exploitable gaps):**
1. **No tables, no text colors, no style customization** — pure text-decoration Markdown only.
2. **No inline image/photo paste** (or at best uncertain/limited) — a glaring omission for a 2026 note app.
3. **One note visible at a time — no tabs, panes, or multi-note windows.** No side-by-side comparison or reference-while-writing.
4. **No first-class organization** — no tags, notebooks/folders, icons, colors, or rich metadata; only pinning + search.
5. **No rich/short link previews** (unfurled cards).
6. **Free tier capped at 5 notes; sync + unlimited gated behind the broader Raycast Pro bundle** (~$8/mo) — you pay for a launcher suite, not a note app.
7. **Not local files you own** (encrypted DB) and **not open source** — no data portability guarantee, no self-host, no community plugins.
8. **Locked inside the Raycast app** — it's a feature of a launcher, not a dedicated note experience; no standalone/mobile-first note UX, weak iOS widget/Siri story.

---

## Whitespace / the opportunity blazing-fast-memo can own

No single competitor combines all four of these. Each rival nails one axis and drops the others:

- **Raycast** = speed, but shallow formatting, single-note, closed DB, paywalled sync.
- **Bear/Craft** = beautiful rich formatting, but slow-to-summon, Apple-locked or closed cloud, not files you own, not open.
- **Obsidian/Logseq** = local files + panes + extensibility, but complex, not instant-capture, weak native tables/colors, mobile capture weak.
- **Notesnook/Anytype/Standard Notes** = OSS + encryption, but not global-hotkey-fast and store data in non-portable encrypted blobs.

**The unclaimed position:** _"Raycast Notes' speed + Bear's beauty, on Obsidian's open local Markdown files, fully open source."_

Concretely, the ownable combination is:
1. **Sub-second global-hotkey capture** (match Raycast) as a standalone, launcher-independent app.
2. **Rich content that Raycast lacks**: extended Markdown, **tables, text/highlight colors, style customization/themes**, **inline photo paste**, and **rich/short link previews** — while staying keyboard-driven.
3. **Multi-note view** — **tabs/panes/pop-out windows** (the thing every fast-capture tool omits) so you can reference and write side-by-side.
4. **True local-first plain `.md` files the user owns** (Obsidian-grade portability), with **optional E2EE cloud sync** as a paid/self-hostable add-on rather than a gate on basic use.
5. **Open source (permissive or copyleft) + Homebrew install** — a trust/ownership story none of the fast-capture incumbents (Raycast, Bear, Craft, Drafts) offers.
6. **Rich metadata + light organization done keyboard-first**: tags, groups, icons, colors, dates/descriptions — but surfaced via fast command-palette actions, not heavy sidebars.

That intersection — **fast + rich + multi-note + open local files** — is empty today. Owning it, macOS-first, is the differentiated wedge.

---

## Risks & hard-to-replicate features

1. **Global-hotkey capture parity is table stakes, not a moat.** Raycast, Apple Quick Note, Drafts, Heynote all do it. The differentiation must be _rich content + multi-note + ownership on top of_ that speed.
2. **Rich Markdown WYSIWYG is genuinely hard.** Bear/Craft spent years on a fast, native, live-styling editor with tables, images, and colors that stays snappy. Doing this while writing to **plain portable `.md`** (colors/styles aren't standard Markdown) forces a format decision: HTML-in-Markdown, front-matter styling, or a documented extension syntax — each with portability trade-offs. This is the central engineering risk.
3. **Sync is expensive and unglamorous.** E2EE, conflict resolution, and reliability took Obsidian/Bear/Notesnook years. Consider leaning on **iCloud/CloudKit or a folder-sync-agnostic** model first (like Obsidian) before building bespoke sync.
4. **Ecosystem lock-in advantages are hard to match:** Apple Notes' OS integration and Bear's/Craft's native polish and Shortcuts/widgets are deep. iOS widgets/Siri/Shortcuts (your Phase 2) are non-trivial and are where Apple-native rivals are strongest.
5. **Free-forever sustainability risk.** Simplenote's 2026 development freeze shows the danger of no revenue model. Plan monetization (paid sync, self-host support, pro features) from day one — but avoid Raycast's mistake of gating _basic_ unlimited notes.
6. **Plugin/theme ecosystems** (Obsidian, Logseq, Joplin) create lock-in you can't replicate quickly; an open, documented API is a long game.
7. **AI features** (Reflect, Bear MCP, Amie) are becoming expected; not core to the vision but a fast-moving competitive front.

---

## Concrete UX & feature takeaways for the product spec

1. **Protect the sub-second capture path above all.** One global hotkey → blank note, keyboard ready, floating window that auto-sizes. Never let any feature (sync, org, rich UI) add latency to first keystroke. This is the reason to exist; benchmark against Raycast/Heynote cold-open time.

2. **Ship the rich content Raycast refuses to: tables, text/highlight colors, inline photo paste, and rich link previews — from v1.** These are the single biggest, most visible gaps in the primary inspiration and the fastest way to be "Raycast Notes but better." Keep them keyboard-invokable (command palette / Format Bar), not mouse-dependent.

3. **Make multi-note view a headline feature: tabs + split panes + pop-out windows.** Every fast-capture competitor shows one note at a time. Side-by-side reference/writing, keyboard-driven pane switching, is a defensible differentiator and directly targets Raycast's weakest UX point.

4. **Store notes as user-owned plain `.md` files in a visible folder (Obsidian-grade ownership).** Decide early how to encode non-standard styling (colors/tables/metadata) — recommend a documented Markdown extension + YAML front-matter for metadata, degrading gracefully in other editors. Portability is a core trust promise the incumbents' encrypted DBs can't make.

5. **Do NOT gate basic unlimited notes behind a paywall** (Raycast's 5-note cap and UpNote's 50-note cap are friction/goodwill costs). Monetize **optional cloud sync, self-host support, and pro/team features** instead. Local + unlimited must be free.

6. **Keyboard-first organization with rich metadata surfaced through the command palette:** tags, groups/notebooks, icons, colors, dates, descriptions — added/edited via fast actions, not heavy always-visible sidebars. Add Quicklink-style "jump to note" shortcuts (Raycast's genuinely good idea worth copying).

7. **Be standalone and open source, with Homebrew install.** Position as a dedicated note app (not a launcher feature) with a `brew install` cask and a real macOS app, plus a permissive/AGPL license and portable data. This is the trust/ownership wedge Raycast, Bear, Craft, and Drafts structurally cannot match.

8. **Sequence platforms deliberately, mirroring the vision:** nail macOS depth first; make sync folder-agnostic (iCloud/Dropbox/Git) before building bespoke E2EE sync; then iOS with first-class **widgets/Siri/Shortcuts** (where Apple-native rivals are strong, so budget real effort); then other platforms. Have a monetization plan from launch to avoid Simplenote's fate.

---

## Sources

Raycast: [blog](https://www.raycast.com/blog/raycast-notes) · [manual/notes](https://manual.raycast.com/notes) · [core-features/notes](https://www.raycast.com/core-features/notes) · [Cloud Sync](https://manual.raycast.com/cloud-sync) · [pricing](https://www.raycast.com/pricing) · [iOS](https://www.raycast.com/ios) · [Windows blog](https://www.raycast.com/blog/raycast-for-windows) · [Windows changelog](https://www.raycast.com/changelog/windows) · [Wikipedia](https://en.wikipedia.org/wiki/Raycast_(software))
Drafts: [site](https://getdrafts.com/) · [Pro docs](https://docs.getdrafts.com/draftspro) · [MacStories](https://www.macstories.net/reviews/drafts-5-mac/)
Heynote: [site](https://heynote.com/) · [GitHub](https://github.com/heyman/heynote)
Bear: [site](https://bear.app/) · [notes location FAQ](https://bear.app/faq/where-are-bears-notes-located/) · [Wikipedia](https://en.wikipedia.org/wiki/Bear_(app)) · [ClickUp review](https://clickup.com/blog/bear-vs-evernote/)
Craft: [MacStories](https://www.macstories.net/reviews/craft-review-a-powerful-native-notes-and-collaboration-app/) · [Shortcuts/Widgets](https://support.craft.do/hc/en-us/sections/15275577889948-Shortcuts-and-Widgets) · [research.com](https://research.com/software/reviews/craft-docs)
UpNote: [Premium FAQ](https://help.getupnote.com/resources/upnote-premium/premium-faqs) · [SaaSworthy](https://www.saasworthy.com/product/getupnote)
Apple Notes: [MacRumors guide](https://www.macrumors.com/guide/apple-notes/) · [Markdown iOS 26](https://www.macrumors.com/2025/06/04/apple-notes-rumored-markdown-support-ios-26/)
Notion: [2.53 offline release](https://www.notion.com/releases/2025-08-19) · [pricing](https://www.notion.com/pricing)
Obsidian: [Wikipedia](https://en.wikipedia.org/wiki/Obsidian_(software)) · [eesel pricing](https://www.eesel.ai/blog/obsidian-pricing) · [aiproductivity pricing](https://aiproductivity.ai/blog/obsidian-pricing/)
Logseq: [ToolChase](https://toolchase.com/tool/logseq/)
Anytype: [productivity.directory](https://productivity.directory/anytype) · [any-sync GitHub](https://github.com/fullstackinfo/anytype-any-sync)
Standard Notes: [features](https://standardnotes.com/features) · [plans](https://standardnotes.com/plans)
Joplin: [overview](https://knightli.com/en/2026/05/30/joplin-open-source-note-taking-app/) · [GetApp](https://www.getapp.com/all-software/a/joplin/)
Simplenote: [toolstack](https://toolstack.io/tools/simplenote) · [WebProNews (dev freeze)](https://www.webpronews.com/simplenotes-quiet-death-how-automattics-cost-cutting-left-millions-of-users-scrambling-for-a-new-notes-app/)
Notesnook: [site](https://notesnook.com/) · [privacy page](https://notesnook.com/privacy-focused-evernote-alternative)
Reflect: [Votars review](https://votars.ai/en/blog/reflect-review-2025/)
Amie: [ClickUp review](https://clickup.com/blog/amie-calendar-review/) · [App Store](https://apps.apple.com/us/app/amie-todos-calendar/id1548277133)
