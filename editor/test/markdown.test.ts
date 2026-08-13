import { describe, it, expect } from 'vitest'
import { Editor } from '@tiptap/core'
import StarterKit from '@tiptap/starter-kit'
import { Markdown } from 'tiptap-markdown'
import Link from '@tiptap/extension-link'
import Image from '@tiptap/extension-image'

function makeEditor(markdown: string): Editor {
  const element = document.createElement('div')
  return new Editor({
    element,
    extensions: [
      StarterKit,
      Link.configure({ openOnClick: false, autolink: false, linkOnPaste: false }),
      Image.configure({ inline: true }),
      Markdown.configure({ html: false, linkify: false, breaks: false }),
    ],
    content: markdown,
  })
}

function roundTrip(markdown: string): string {
  const editor = makeEditor(markdown)
  const storage = editor.storage as { markdown: { getMarkdown: () => string } }
  const out = storage.markdown.getMarkdown()
  editor.destroy()
  return out
}

function toHTML(markdown: string): string {
  const editor = makeEditor(markdown)
  const html = editor.getHTML()
  editor.destroy()
  return html
}

const cases = [
  '# Heading',
  '## Subheading',
  'Some **bold** and *italic* text.',
  '- a\n- b\n- c',
  '1. one\n2. two',
  '> a quote',
  '`inline code`',
  '```\ncode block\n```',
  '- [ ] todo\n- [x] done',
  'A paragraph.\n\nAnother paragraph.',
  '- outer\n  - nested\n  - nested two',
  '### h3\n\ntext\n\n- l1\n- l2\n\n> quote',
  'See [docs](https://example.com) for details.',
  '![alt text](https://example.com/x.png)',
]

describe('markdown round-trip is stable (no drift on re-save)', () => {
  for (const md of cases) {
    it(`stable: ${JSON.stringify(md)}`, () => {
      const once = roundTrip(md)
      const twice = roundTrip(once)
      expect(twice).toBe(once)
    })
  }
})

describe('golden md↔PM fuzz (deterministic)', () => {
  function makePrng(seed: number): () => number {
    let state = seed >>> 0
    return () => {
      state = (1664525 * state + 1013904223) >>> 0
      return state / 0xffffffff
    }
  }

  it('random documents are idempotent on re-save', () => {
    const rnd = makePrng(42)
    for (let n = 0; n < 80; n++) {
      const length = 1 + Math.floor(rnd() * 4)
      const parts: string[] = []
      for (let k = 0; k < length; k++) parts.push(cases[Math.floor(rnd() * cases.length)])
      const doc = parts.join('\n\n')
      const once = roundTrip(doc)
      const twice = roundTrip(once)
      expect(twice, `unstable round-trip for:\n${doc}\n--- once ---\n${once}`).toBe(once)
    }
  })
})

describe('links and images are preserved on load→save', () => {
  it('keeps a link target', () => {
    expect(roundTrip('See [docs](https://example.com) here.')).toContain('](https://example.com)')
  })

  it('keeps an image with its source', () => {
    expect(roundTrip('![alt text](https://example.com/x.png)')).toContain('![alt text](https://example.com/x.png)')
  })
})

describe('sanitization boundary (SEC-F4)', () => {
  it('does not emit a <script> element from note content', () => {
    expect(toHTML('Hello <script>alert(1)</script> world')).not.toContain('<script')
  })

  it('does not render a live <img> element from raw HTML', () => {
    // html:false escapes the raw tag to inert text, so no actual <img> element exists.
    expect(toHTML('<img src=x onerror=alert(1)>')).not.toContain('<img')
  })

  it('does not produce a live javascript: link', () => {
    const html = toHTML('[click](javascript:alert(1))')
    expect(html).not.toContain('href="javascript:')
    expect(html).not.toContain('<a ')
  })

  it('round-trip does not resurrect raw HTML', () => {
    const out = roundTrip('Hello <script>alert(1)</script> world')
    expect(out).not.toContain('<script>')
  })
})
