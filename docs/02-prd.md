# PRD: blazing-fast-memo

**Status**: Draft
**Author**: Alex (PM)  **Last Updated**: 2026-08-10  **Version**: 0.1
**Stakeholders**: Founder (solo Swift dev / product owner), future Software Architect (owns editor-engine and storage-format decisions)

> Companion doc: `03-roadmap.md`. This PRD defines *what* and *why*; the roadmap defines *when* and *in what order*.

---

## 1. Vision

blazing-fast-memo is an extremely fast, keyboard-driven, local-first, open-source note app for macOS (iOS next). It takes the one trait people love most about Raycast Notes — hit one shortcut and you're writing in under a second — and removes its ceilings: unlimited notes, view several notes at once, real customization, richer formatting and media, mobile, and true data ownership. The moat is not feature count (we will never out-feature Notion or Obsidian as a solo dev); the moat is *time-to-first-keystroke*, native feel, and keyboard-everything ergonomics that heavier apps structurally can't match.

---

## 2. Problem Statement

Fast thinkers lose thoughts to friction. The moment between "I have a thought" and "it's captured" is where notes die: launching an app, waiting for sync, finding the right note, fighting formatting. Raycast Notes solved *capture* beautifully but is capped (5 free notes), single-note-focused, macOS-only, closed-source, and locked to Raycast's ecosystem and database. Heavier local-first tools (Obsidian) own your files but are slower to open, mouse-heavy in places, and configuration-heavy. There is an unoccupied seat: **Raycast-Notes-speed capture + Obsidian-grade data ownership + Bear-grade polish, keyboard-first, free and open.**

**Evidence (to strengthen — see Open Questions):**
- Competitive signal: Raycast Notes' most-cited limitations are no mobile, single-note focus, the 5-note free wall, and non-`.md` export. These are our wedge.
- Speed baseline: Bear cold-opens ~0.7s; Notion ~2.6s. "Fast" is a measurable, winnable claim.
- Behavioral/user-interview data: **not yet gathered.** This PRD is currently founder-vision-driven. Flagged as the #1 discovery gap before committing beyond M1.

---

## 3. Target Users & Personas

**Persona A — "The Flow Capturer" (primary)**
Developer / knowledge worker, lives in Raycast or a launcher, captures thoughts, tasks, and snippets throughout the day. Already uses Raycast Notes and has hit the wall: the 5-note cap, no side-by-side, no phone access. Wants capture to stay sub-second and never leave the keyboard. *This is the beachhead. Build for this person first.*

**Persona B — "The Local-First Owner" (secondary)**
Privacy-minded power user, distrusts cloud lock-in, likes that Obsidian is "just files on disk." Finds Obsidian heavier and more configuration-heavy than they want. Will adopt if data is plain, portable, and the app is faster and quieter than what they have.

**Persona C — "The Minimalist Aesthete" (tertiary)**
Values Bear-like polish and a workspace that feels *theirs* — font, colors, note background. Keyboard-comfortable but not keyboard-obsessed. Adoption driver is feel and customization, not power features. Reachable later (M3), not a v1 target.

---

## 4. Jobs To Be Done

1. When a thought hits me mid-work, **capture it in under a second** without breaking flow or context-switching.
2. When I write, **format as I type** ("## " → H2) so I never stop to manage syntax.
3. When I return, **find and move between notes by keyboard** so I stay fast.
4. When I'm synthesizing, **see two (or more) notes at once** without losing my place.
5. When I set up my tools, **own my data locally** and *optionally* sync — never be locked in.
6. When I want the space to feel mine, **tune the look** (font, size, colors, background).

---

## 5. Goals & Non-Goals

### Goals
- Be the fastest way on macOS to go from shortcut to written word. Target: **time-to-first-keystroke < 300ms** on Apple Silicon from cold-ish state.
- Remove every Raycast Notes ceiling that matters: unlimited notes, multi-note viewing, mobile, data ownership, customization.
- Local-first and open-source from day one; cloud is optional and later.
- Ship something the founder uses daily by M1.

### Non-Goals (this product, for the foreseeable roadmap)
- **Not** a knowledge-graph / backlinks / wiki tool (that's Obsidian's game; revisit only on strong signal).
- **Not** a databases/blocks/collaboration tool (that's Notion). No real-time multiplayer.
- **Not** a Windows/Linux/Android app in the near term (Apple-native first is a locked decision).
- **Not** distributed via the Mac App Store (Homebrew / direct download — locked decision).
- **Not** an AI-writing product in v1 (deliberately out; can layer later, don't let it dilute the speed story).

---

## 6. Prioritized Feature List

Priorities are **relative to a great local-only v1 (milestone M1)**:
- **Must** = v1 is not v1 without it.
- **Should** = strongly wanted in/around v1; cut only under pressure.
- **Could** = nice, opportunistic, not blocking.
- **Won't-yet** = explicitly deferred to a later milestone (not "no" — "not now"). Roadmap milestone noted.

> ⚠️ **Cross-cutting architecture dependency.** Several features below (colors, note backgrounds, tables, pasted photos, rich blocks) are **not representable in plain `.md`**. The more of these we commit to, the more we are forced off plain Markdown toward `markdown+frontmatter+assets` or a rich block model — which trades away some of the "just plain files, no lock-in" promise. This is the product's central tension and it maps directly onto the **storage-format decision the architect owns**. Features carrying this dependency are marked **[STORAGE]**. Features whose feel depends on the **editor-engine decision** (TextKit 2 vs web editor) are marked **[EDITOR]**.

### 6.1 Capture
| Feature | Description | Priority |
|---|---|---|
| Global hotkey → instant note | One system-wide shortcut opens a ready-to-type surface | **Must** |
| New-note-on-open default | Opens straight into writing, not a list | **Must** |
| Sub-300ms time-to-first-keystroke | Perf budget as a product requirement, not a nice-to-have | **Must** |
| Quick-switch to recent note on open | Optionally reopen last note instead of new | **Should** |
| Menu-bar presence / quick access | Lightweight always-available entry point | **Should** |
| Global "append to today" capture | Hotkey that appends to a daily note | **Could** |

### 6.2 Editing & Formatting
| Feature | Description | Priority |
|---|---|---|
| Markdown-as-you-type | "## "→H2, `*x*`→italic, live, Typora-style **[EDITOR]** | **Must** |
| Core inline marks | Bold, italic, strikethrough, inline code | **Must** |
| Lists, checklists, nesting/reorder | Bulleted/numbered/task lists, keyboard indent | **Must** |
| Headings H1–H3, quotes, code blocks | Standard block formatting **[EDITOR]** | **Must** |
| Keyboard-first formatting | Every format reachable without the mouse | **Must** |
| Tables | Create/edit markdown tables fluidly **[EDITOR][STORAGE]** | **Should** |
| Extended markdown (footnotes, highlights, etc.) | Beyond CommonMark **[STORAGE]** | **Could** |
| Text colors / highlights | Inline color — **not plain-md-representable [STORAGE]** | **Could** |
| Slash / command palette for blocks | `/` menu for inserts | **Could** |
| Rich block model (callouts, toggles) | Notion-style blocks — **major storage commitment [STORAGE]** | **Won't-yet** (M3+, gated on architecture) |

### 6.3 Organization & Metadata
| Feature | Description | Priority |
|---|---|---|
| Unlimited notes | No cap. Direct answer to Raycast's 5-note wall | **Must** |
| Keyboard note switcher / quick-open | Fuzzy find + arrow-key nav | **Must** |
| Full-text search | Fast search across all notes | **Must** |
| Auto metadata (created / updated) | Timestamps maintained automatically **[STORAGE: frontmatter]** | **Should** |
| Groups / folders | Organize notes into collections | **Should** |
| Note description & icon | Human-set metadata per note **[STORAGE: frontmatter]** | **Could** |
| Tags | Lightweight cross-cutting labels | **Could** |
| Pinning / favorites | Keep key notes on top | **Could** |

### 6.4 Viewing & Multi-Note
| Feature | Description | Priority |
|---|---|---|
| Single focused editor (Raycast-style) | The default fast surface | **Must** |
| Note list / navigator | Browse and jump by keyboard | **Must** |
| View multiple notes at once | Side-by-side / split — **key differentiator, interaction-model risk (see §8)** | **Should** |
| Detachable / floating note windows | Pop a note into its own window | **Could** |
| Focus / zen mode | Hide all chrome | **Could** |

### 6.5 Customization
| Feature | Description | Priority |
|---|---|---|
| Light/dark + system theme | Baseline theming | **Should** |
| Font family & size | Reader/writer comfort | **Should** |
| Customizable keyboard shortcuts | Rebind global + in-app actions | **Should** |
| Accent / UI color | Personalization | **Could** |
| Per-note background | **Not plain-md-representable [STORAGE]** | **Could** |
| Theme presets / import | Shareable themes | **Won't-yet** (M3) |

### 6.6 Media & Links
| Feature | Description | Priority |
|---|---|---|
| Paste photos into a note | Image capture — **needs asset storage [STORAGE]** | **Should** |
| Rich/short link rendering | URLs render as compact rich chips instead of raw links **[EDITOR]** | **Should** |
| Drag-and-drop images/files | Beyond paste | **Could** |
| File attachments (non-image) | Attach arbitrary files **[STORAGE]** | **Could** |
| Link preview / unfurl | Fetch title/favicon (needs network) | **Won't-yet** (M3) |

### 6.7 Sync
| Feature | Description | Priority |
|---|---|---|
| Local-only, no backend | Everything on disk, no account | **Must** (M1) |
| Optional folder in user-chosen location | Point storage at iCloud Drive/Dropbox as a poor-man's sync | **Could** |
| CloudKit sync (macOS ↔ iOS) | Apple-only, no server to run | **Won't-yet** (M2) |
| Managed freemium sync (E2E, cross-platform) | Accounts, billing, encryption, support | **Won't-yet** (M4) |

### 6.8 Distribution
| Feature | Description | Priority |
|---|---|---|
| Direct download (signed + notarized) | Notarized `.app` / `.dmg` | **Must** |
| Homebrew Cask install | `brew install --cask blazing-fast-memo` | **Must** |
| Open-source repo + license | Public repo from day one | **Must** |
| Auto-update (e.g. Sparkle) | In-app updates outside App Store | **Should** |
| iOS App Store build | iPhone/iPad app, widgets, App Intents/Siri | **Won't-yet** (M2) |

---

## 7. Success Metrics / Definition of a Good v1 (M1)

A good v1 is one **the founder uses every day and would miss if it disappeared.** Concretely:

| Dimension | Definition of good v1 | How measured |
|---|---|---|
| Speed | Time-to-first-keystroke < 300ms; open→typed word feels instant | Manual instrumentation / signposts |
| Core loop | Capture → format-as-you-type → find later works with zero mouse | Founder dogfooding, task walkthrough |
| Reliability | Zero data-loss incidents; notes survive crash/quit | Crash + save testing |
| Reach | Unlimited notes, full-text search, keyboard switcher all working | Feature checklist |
| Ownership | Notes readable/editable outside the app (real files) | Open storage dir, inspect |
| Install | `brew install --cask` works on a clean Mac; app is notarized | Clean-machine test |

Post-launch signals to watch (lightweight; solo-dev-appropriate): GitHub stars/issues as demand proxy, Homebrew install count, and qualitative feedback from the first ~20 external users. **We are deliberately not building heavy in-app analytics for v1** (local-first + privacy-positioning + solo effort).

---

## 8. Key Risks & Assumptions

| Risk / Assumption | Type | Impact | Mitigation |
|---|---|---|---|
| **Scope vs. solo capacity.** Vision spans 4 platforms, rich editing, media, and a managed E2E freemium backend — years of work for one dev. | Risk | High | Ruthless milestone gating (see roadmap). Treat M4 as "maybe/hire," not a commitment. Compete on speed+feel, not feature count. |
| **Rich features vs. plain-`.md` promise.** Colors, backgrounds, blocks, images can't live in plain Markdown; committing to them erodes the "just files, no lock-in" pitch. | Risk | High | Force the storage decision early (architect). Keep body as portable Markdown + sidecar assets/frontmatter; treat colors/backgrounds as app-layer metadata, degrade gracefully outside the app. |
| **Multi-note view breaks the Raycast interaction model.** Side-by-side implies a windowed app, not a single quick panel — two different UX paradigms. | Risk | Med | Ship single-panel capture first (M1); introduce multi-note as an *additional* mode (M3), not a replacement. Validate demand before building. |
| **Editor engine bet.** Markdown-as-you-type + tables + rich links is the hardest craft; MarkEdit chose a web editor over TextKit 2 for exactly this. Wrong bet = rewrite. | Risk | High | Architect decides TextKit 2 vs web editor at M0 via a spike against the as-you-type requirement. This is a POC gate, not a later cleanup. |
| **Distribution cost/friction.** Notarization + Homebrew Cask still require a paid Apple Developer account and a signing/notarization pipeline. | Assumption→Risk | Med | Budget $99/yr Apple Developer; set up signing before M1, not at ship time. |
| **No user evidence yet.** Direction is founder-vision-led; personas/JTBD are hypotheses. | Risk | Med | Run 5–10 problem interviews with Raycast Notes users before committing past M1. Cheap insurance. |
| **Assumption: "fast native" is a durable moat.** MarkEdit shows web editors can also be fast. | Assumption | Med | Differentiate on *capture speed + keyboard ergonomics + integrated capture*, not raw editor perf alone. |

---

## 9. Open Questions for the Founder

1. **What is the one-sentence wedge for v1?** My recommendation: "Raycast Notes without the ceilings — unlimited, ownable, multi-note." Do you agree, or is customization/aesthetics the wedge? This changes whether Persona A or C leads.
2. **How plain must the files be?** Is "notes are portable Markdown, but colors/backgrounds/icons live in frontmatter or a sidecar and don't render outside the app" acceptable? Your answer largely pre-decides the architect's storage choice.
3. **Is multi-note viewing a v1-adjacent differentiator or an M3 feature?** It's your loudest "better than Raycast" claim but it forks the whole interaction model. I've placed it at M3 — push back if it must be earlier.
4. **How real is M4 (managed freemium E2E backend)?** For a solo dev this is a company, not a feature (accounts, billing, encryption, support, compliance). Is the honest plan "someday / if it grows / possibly hire," and CloudKit (M2) is the practical end state for a long while?
5. **AI features — in or out?** I've scoped them out to protect the speed story. Confirm.
6. **What's the license?** MIT/Apache (permissive, max adoption) vs GPL (protects openness). Affects contributions and any future commercial layer.
