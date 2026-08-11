# Interaction Model & Keymap — blazing-fast-memo

**Last updated**: 2026-08-10 · **Status**: confirmed with founder (tracks the v3 wireframes)

This is the single source of truth for how the app behaves. It supersedes interaction details described in `02-prd.md`. Architecture for the window/webview layer lives in `04-architecture.md` (see the Stickies addendum).

---

## 1. Model in one paragraph

The app is a set of **Apple Stickies-style floating note windows**. Each note is a small, borderless, always-on-top window that behaves identically to every other note — there is no main window, sidebar, or app chrome. You summon your notes with a global hotkey, write instantly, and they float above whatever you're doing so you never lose them. Multiple notes on screen at once is simply "several stickies visible"; it carries no extra logic beyond layering and window-switching.

---

## 2. Window behavior

- **Chrome**: none. No traffic-light buttons, no title bar. Borderless (implemented as a visually-borderless `NSPanel`, not pure `.borderless` — see architecture addendum).
- **Always-on-top**: floats above other apps (`.floating` window level), non-activating so typing never steals focus or switches Spaces, and ⌘-Tab still works. Toggleable in Settings (default on).
- **Default size**: 380px wide, sticky-note proportioned. Resizable; **size and position persist per note** across launches.
- **Default placement**: top-right. Configurable via a 3×3 placement grid in Settings (4 corners, 4 edges, center).
- **Focus / top-most indicator**: the focused (top) sticky is marked with a **subtle accent-gold border / shadow** — no pill or badge.
- **Layering**: most-recently-opened-or-edited window sits on top.
- **Concurrency**: ~10–12 stickies open comfortably; only 3 live web editors at once (pooled), the rest are native snapshots rehydrated on focus (architecture addendum).

---

## 3. Note anatomy

**Header**
- Icon on the left.
- To its right, two lines: **title** (line 1), **description** (line 2).
- Below: **category (group)** chip + **tag** list.
- The icon is **not** tap-editable — it is changed via the action menu / config overlay.

**Body**: the rich Markdown editor (headings, lists/checklists, tables, colored + highlighted text, inline images, link cards, code blocks).

**Footer**: minimal — no date. (Optional subtle word count.)

**Hidden metadata** (never shown in the note body): created date, updated date, cloud-sync status, source location (local file path or cloud). These appear only inside the config overlay.

---

## 4. Keymap

| Action | Key | Notes |
|---|---|---|
| Show / hide all open notes | **⌘⇧.** | Global. Summons your open stickies (last-focused on top); press again hides all. If none are open, opens the last note. |
| New note | **⌘N** | When a sticky is focused. New note appears at the default placement. |
| Focused-note **action menu** | **⌘K** | Acts on THIS note. Every per-note action lives here, each with its own hotkey. |
| Quick-open / search notes | **⌘O** | Find & open ANY note. `Return` = open in current top window; `⌘Return` = open in a new sticky. |
| Close note (stays on disk) | **⌘W** | Removes the sticky from the open set; the note file is untouched. Reopen via quick-open. |
| Delete note (from disk) | **⌘K → Delete** | Palette/action-menu only, with confirm + undo. No destructive raw hotkey. |
| Switch to sticky N | **⌘1–9** (physical number keys, no Shift) | Direct jump to the Nth open sticky. Matched by physical keycode so AZERTY works without Shift — avoids the ⌘⇧3/4/5 screenshot clash. User-rebindable in a later iteration. |
| Metadata / icon / group / tags / pin | **⌘K → …** | Via the action menu; opens the config overlay where relevant. |

There is **no** "hide a single sticky" action — the only per-note removal is **Close** (⌘W). Global show/hide-all is the way to clear the screen.

---

## 5. ⌘K — focused-note action menu

A Raycast-style command list scoped to the currently focused note. Each row shows its hotkey. Actions include: New note (⌘N), Close note (⌘W), Delete note (confirm), Edit metadata / Configure, Change icon, Set group, Add tag, Pin, Copy, Export. This is distinct from ⌘O (which finds/opens any note).

---

## 6. ⌘O — quick-open / search

A search palette across all notes (fuzzy match on title/description/body). `Return` opens the selected note into the **current top window**; `⌘Return` opens it in a **new sticky**. This is the only "navigator" — there is no persistent note list UI.

---

## 7. Metadata & config overlay

- Opened from the ⌘K action menu.
- Renders as an **overlay inside the sticky**, on top of the content, with the content behind it **blurred** (modal-in-sticky, not a separate window).
- **Editable**: icon picker, title, description, group (typeahead), tags.
- **Read-only info**: created date, updated date, cloud-sync status, source location.
- **Group typeahead**: type a name → dropdown of matching existing groups → click to select an existing group, **or** blur the field to create a new group with the typed name. **Empty groups auto-delete** when their last note leaves them.

---

## 8. Settings

- Global hotkey (default **⌘⇧.**, rebindable) and the full editable shortcut list (⌘N, ⌘K, ⌘O, ⌘W, ⌘1–9).
- Default sticky **size** (380px) and **placement** (3×3 grid, default top-right).
- **Always-on-top** toggle (default on).
- Theme (light / dark / system) and **accent** (gold, `#F0B90B` light / `#FFD21A` dark).
- System font only (no font-family picker for now).

---

## 9. Edge cases & open micro-decisions

- **Global hotkey with nothing open** → opens the last-edited note.
- **New note placement** → default placement slot; if occupied, offset so it doesn't fully overlap (design detail for implementation).
- **Delete** always confirms and offers undo.
- **Multi-window** ships at M3, but the single-note window is built on the same window/pool machinery so multi is additive, not a rewrite.
