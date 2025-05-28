import { Controller } from "@hotwired/stimulus"
import { Editor } from "@tiptap/core"
import StarterKit from "@tiptap/starter-kit"
import Typography from "@tiptap/extension-typography"
// import Placeholder from "@tiptap/extenon-placeholder"


export default class extends Controller {
  static targets = ["editor", "input", "toolbar"]
  static values = { data: Object }

  connect() {
    this.emoteCache = new Map()
    this.initializeEditor()
    this.setupToolbar()
  }

  disconnect() {
    if (this.editor) {
      this.editor.destroy()
    }
  }

  initializeEditor() {
    this.editor = new Editor({
      element: this.editorTarget,
      extensions: [
        StarterKit.configure({
          heading: false
        }),
        Typography
      ],
      content: this.dataValue?.content || '',
      editorProps: {
        attributes: {
          class: 'tiptap-editor focus:outline-none prose prose-sm max-w-none min-h-[120px] h-full w-full cursor-text [&_p]:my-2 [&_p:first-child]:mt-0 [&_p:last-child]:mb-0 [&_strong]:text-black [&_em]:italic [&_code]:bg-gray-900 [&_code]:text-forest [&_code]:px-1 [&_code]:py-0.5 [&_code]:rounded [&_code]:font-mono [&_code]:text-sm [&_pre]:bg-gray-100 [&_pre]:p-3 [&_pre]:rounded-md [&_pre]:overflow-x-auto [&_pre]:my-4 [&_pre_code]:bg-transparent [&_pre_code]:p-0 [&_pre_code]:font-mono [&_ul]:list-disc [&_ul]:pl-6 [&_ul]:my-2 [&_ol]:list-decimal [&_ol]:pl-6 [&_ol]:my-2 [&_li]:my-1 [&_blockquote]:border-l-4 [&_blockquote]:border-gray-300 [&_blockquote]:pl-4 [&_blockquote]:my-4 [&_blockquote]:text-gray-600 [&_.inline-emote]:w-5 [&_.inline-emote]:h-5 [&_.inline-emote]:align-middle [&_.inline-emote]:inline-block',
        },
      },
      onUpdate: ({ editor }) => {
        this.saveData()
        this.updateToolbar()
      },
      onSelectionUpdate: ({ editor }) => {
        this.updateToolbar()
      },
    })
  }

  setupToolbar() {
    if (!this.hasToolbarTarget) return

    const toolbar = this.toolbarTarget

    toolbar.addEventListener('click', (e) => {
      const button = e.target.closest('button')
      if (!button) return

      e.preventDefault()
      const action = button.dataset.action

      switch (action) {
        case 'undo':
          this.editor.chain().focus().undo().run()
          break
        case 'redo':
          this.editor.chain().focus().redo().run()
          break
        case 'bold':
          this.editor.chain().focus().toggleBold().run()
          break
        case 'italic':
          this.editor.chain().focus().toggleItalic().run()
          break
        case 'strike':
          this.editor.chain().focus().toggleStrike().run()
          break
        case 'code':
          this.editor.chain().focus().toggleCode().run()
          break
        case 'bulletList':
          this.editor.chain().focus().toggleBulletList().run()
          break
        case 'orderedList':
          this.editor.chain().focus().toggleOrderedList().run()
          break
        case 'blockquote':
          this.editor.chain().focus().toggleBlockquote().run()
          break
        case 'codeBlock':
          this.editor.chain().focus().toggleCodeBlock().run()
          break
      }
    })

    this.updateToolbar()
  }

  updateToolbar() {
    if (!this.hasToolbarTarget) return

    const toolbar = this.toolbarTarget
    
    const buttons = toolbar.querySelectorAll('button[data-action]')
    buttons.forEach(button => {
      const action = button.dataset.action
      let isActive = false

      switch (action) {
        case 'bold':
          isActive = this.editor.isActive('bold')
          break
        case 'italic':
          isActive = this.editor.isActive('italic')
          break
        case 'strike':
          isActive = this.editor.isActive('strike')
          break
        case 'code':
          isActive = this.editor.isActive('code')
          break
        case 'bulletList':
          isActive = this.editor.isActive('bulletList')
          break
        case 'orderedList':
          isActive = this.editor.isActive('orderedList')
          break
        case 'blockquote':
          isActive = this.editor.isActive('blockquote')
          break
        case 'codeBlock':
          isActive = this.editor.isActive('codeBlock')
          break
      }

      button.classList.toggle('active', isActive)
      
      if (isActive) {
        button.classList.add('text-forest')
        button.classList.remove('text-saddle-taupe')
      } else {
        button.classList.remove('text-forest')
        button.classList.add('text-saddle-taupe')
      }
    })
  }

  saveData() {
    try {      
      const content = this.editor.getHTML()
      const json = this.editor.getJSON()
      
      // Store both HTML and JSON for flexibility
      const outputData = {
        type: 'tiptap',
        content: content,
        json: json
      }
      
      this.inputTarget.value = JSON.stringify(outputData)
    } catch (error) {
      console.error('Saving failed:', error)
    }
  }

  async validateContent() {
    try {
      const content = this.editor.getText().trim()
      return content.length > 0
    } catch (error) {
      console.error('Validation failed:', error)
      return false
    }
  }
} 