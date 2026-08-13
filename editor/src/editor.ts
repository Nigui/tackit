import { Editor } from '@tiptap/core'
import StarterKit from '@tiptap/starter-kit'
import { Markdown } from 'tiptap-markdown'
import { EditorState } from '@tiptap/pm/state'

interface Envelope {
  v: number
  id: string
  type: string
  payload?: Record<string, unknown>
}

declare global {
  interface Window {
    webkit?: {
      messageHandlers?: Record<string, { postMessage: (payload: unknown) => void }>
    }
    __tackitReceive?: (envelope: Envelope) => void
    tackitReady?: boolean
  }
}

let messageCounter = 0

function postToNative(type: string, payload: Record<string, unknown> = {}): void {
  const envelope: Envelope = { v: 1, id: `js-${(messageCounter += 1)}`, type, payload }
  try {
    window.webkit?.messageHandlers?.tackit?.postMessage(envelope)
  } catch (_error) {
    void _error
  }
}

const element = document.getElementById('editor')
if (!element) {
  throw new Error('missing #editor element')
}

let applyingRemote = false

const editor = new Editor({
  element,
  extensions: [StarterKit, Markdown.configure({ html: false, linkify: false, breaks: false })],
  content: '',
  autofocus: false,
  onCreate() {
    window.tackitReady = true
    postToNative('ready')
  },
  onUpdate() {
    if (applyingRemote) {
      return
    }
    postToNative('docChanged', { markdown: getMarkdown() })
  },
})

function getMarkdown(): string {
  const storage = editor.storage as { markdown?: { getMarkdown: () => string } }
  return storage.markdown?.getMarkdown() ?? editor.getText()
}

function resetHistory(): void {
  const fresh = EditorState.create({
    schema: editor.state.schema,
    doc: editor.state.doc,
    plugins: editor.state.plugins,
  })
  editor.view.updateState(fresh)
}

let firstKeyLogged = false
editor.view.dom.addEventListener(
  'keydown',
  () => {
    const start = performance.now()
    requestAnimationFrame(() => {
      postToNative('metric', {
        name: firstKeyLogged ? 'keystroke' : 'firstKeystroke',
        ms: performance.now() - start,
      })
      firstKeyLogged = true
    })
  },
  true,
)

document.body.addEventListener('mousedown', (event) => {
  const dom = editor.view.dom
  const target = event.target as Node | null
  if (target && dom.contains(target)) {
    return
  }
  event.preventDefault()
  editor.commands.focus('end')
})

window.__tackitReceive = (envelope: Envelope) => {
  if (!envelope || envelope.v !== 1) {
    return
  }
  switch (envelope.type) {
    case 'load':
      applyingRemote = true
      editor.commands.setContent(String(envelope.payload?.markdown ?? ''))
      applyingRemote = false
      resetHistory()
      break
    case 'focus':
      editor.commands.focus('end')
      break
    case 'reset':
      applyingRemote = true
      editor.commands.clearContent()
      applyingRemote = false
      resetHistory()
      firstKeyLogged = false
      editor.commands.blur()
      break
    case 'theme':
      document.documentElement.classList.toggle('dark', Boolean(envelope.payload?.dark))
      break
    default:
      break
  }
}
