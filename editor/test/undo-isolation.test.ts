import { describe, it, expect } from 'vitest'
import { Editor } from '@tiptap/core'
import StarterKit from '@tiptap/starter-kit'
import { Markdown } from 'tiptap-markdown'
import { EditorState } from '@tiptap/pm/state'

function makeEditor(): Editor {
  const element = document.createElement('div')
  return new Editor({
    element,
    extensions: [StarterKit, Markdown.configure({ html: false, linkify: false, breaks: false })],
    content: '',
  })
}

function md(editor: Editor): string {
  const storage = editor.storage as { markdown: { getMarkdown: () => string } }
  return storage.markdown.getMarkdown()
}

function resetHistory(editor: Editor): void {
  const fresh = EditorState.create({
    schema: editor.state.schema,
    doc: editor.state.doc,
    plugins: editor.state.plugins,
  })
  editor.view.updateState(fresh)
}

describe('undo isolation across note switches', () => {
  it('cannot undo across a load boundary after a history reset', () => {
    const editor = makeEditor()

    editor.commands.setContent('note A body')
    resetHistory(editor)
    editor.commands.setContent('note B body')
    resetHistory(editor)

    editor.commands.undo()

    expect(md(editor)).toContain('note B body')
    expect(md(editor)).not.toContain('note A body')
    editor.destroy()
  })

  it('control: without a history reset, undo destroys the current note content', () => {
    const editor = makeEditor()

    editor.commands.setContent('note A body')
    editor.commands.setContent('note B body')
    editor.commands.undo()

    expect(md(editor)).not.toContain('note B body')
    editor.destroy()
  })
})
