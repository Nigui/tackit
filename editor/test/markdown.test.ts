import { describe, it, expect } from 'vitest'
import { Editor } from '@tiptap/core'
import StarterKit from '@tiptap/starter-kit'
import { Markdown } from 'tiptap-markdown'

function roundTrip(markdown: string): string {
  const element = document.createElement('div')
  const editor = new Editor({
    element,
    extensions: [StarterKit, Markdown.configure({ html: false, linkify: false, breaks: false })],
    content: markdown,
  })
  const storage = editor.storage as { markdown: { getMarkdown: () => string } }
  const out = storage.markdown.getMarkdown()
  editor.destroy()
  return out
}

describe('markdown round-trip is stable (no drift on re-save)', () => {
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
  ]

  for (const md of cases) {
    it(`stable: ${JSON.stringify(md)}`, () => {
      const once = roundTrip(md)
      const twice = roundTrip(once)
      expect(twice).toBe(once)
    })
  }
})

describe('sanitization boundary', () => {
  it('does not render raw HTML from note content', () => {
    const out = roundTrip('Hello <script>alert(1)</script> world')
    expect(out).not.toContain('<script>')
  })
})
