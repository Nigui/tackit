import { Editor } from '@tiptap/core'
import StarterKit from '@tiptap/starter-kit'

declare global {
  interface Window {
    webkit?: {
      messageHandlers?: Record<string, { postMessage: (payload: unknown) => void }>
    }
    focusEditor?: () => void
    resetEditor?: () => void
    tackitReady?: boolean
  }
}

function post(channel: string, payload: unknown): void {
  try {
    window.webkit?.messageHandlers?.[channel]?.postMessage(payload)
  } catch (_err) {
    void _err
  }
}

const element = document.getElementById('editor')
if (!element) {
  throw new Error('missing #editor element')
}

const editor = new Editor({
  element,
  extensions: [StarterKit],
  content: '',
  autofocus: false,
  onCreate() {
    window.tackitReady = true
    post('metrics', { event: 'editorCreated', t: performance.now() })
  },
})

let firstKeyLogged = false
editor.view.dom.addEventListener(
  'keydown',
  () => {
    const keydown = performance.now()
    requestAnimationFrame(() => {
      const painted = performance.now()
      if (!firstKeyLogged) {
        firstKeyLogged = true
        post('metrics', { event: 'firstKeystroke', latency: painted - keydown })
      } else {
        post('metrics', { event: 'keystroke', latency: painted - keydown })
      }
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

window.focusEditor = () => {
  editor.commands.focus('end')
  post('metrics', { event: 'focused', t: performance.now() })
}

window.resetEditor = () => {
  editor.commands.clearContent()
  editor.commands.blur()
}
