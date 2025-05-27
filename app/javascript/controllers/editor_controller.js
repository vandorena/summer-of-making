import { Controller } from "@hotwired/stimulus"
import EditorJS from "@editorjs/editorjs"
import CodeTool from "@editorjs/code"
import Paragraph from "@editorjs/paragraph"

export default class extends Controller {
  static targets = ["editor", "input"]
  static values = { data: Object }

  connect() {
    this.emoteCache = new Map()
    
    this.initializeEditor()
  }

  disconnect() {
    if (this.editor) {
      this.editor.destroy()
    }
  }

  initializeEditor() {
    this.editor = new EditorJS({
      holder: this.editorTarget,
      tools: {
        paragraph: {
          class: Paragraph,
          inlineToolbar: true
        },
        code: CodeTool
      },
      data: this.dataValue,
      placeholder: "Write your comment here... (be nice)",
      // Unforuntely, once you processEmotes it becomes an infinite loop, this.processEmotes() triggers parent.replaceChild(fragment, textNode) and they keep triggering themselves. I haven't been able to find a solution but https://github.com/codex-team/editor.js/discussions/1907
      onChange: () => {
        this.saveData()
        this.processEmotes()
      }
    })
  }

  async processEmotes() {
      const walker = document.createTreeWalker( // Hello my manager (he attack, he protecc but most importantly he walks)
        this.editorTarget,
        NodeFilter.SHOW_TEXT,
        null,
        false
      )

      const textNodes = []
      let node
      while (node = walker.nextNode()) {
        textNodes.push(node)
      }

      for (const textNode of textNodes) {
        const text = textNode.textContent
        const emotePattern = /:([a-zA-Z0-9_+-]+):/g
        let match

        while ((match = emotePattern.exec(text)) !== null) {
          const emoteName = match[1]
          
          if (this.emoteCache.has(emoteName)) {
            const emote = this.emoteCache.get(emoteName)
            this.replaceEmoteInTextNode(textNode, emoteName, emote)
          } else {
            this.fetchAndReplaceEmote(textNode, emoteName)
          }
        }
      }
  }

  async fetchAndReplaceEmote(textNode, emoteName) {
    try {
      const response = await fetch(`/api/v1/emotes/${encodeURIComponent(emoteName)}`)
      if (response.ok) {
        const emote = await response.json()
        this.emoteCache.set(emoteName, emote)
        this.replaceEmoteInTextNode(textNode, emoteName, emote)
      } 
    } catch (error) {
      console.error(`Failed to fetch emote ${emoteName}:`, error)
    }
  }

  replaceEmoteInTextNode(textNode, emoteName, emote) {
    if (!textNode.parentNode) return

    const text = textNode.textContent
    const emotePattern = new RegExp(`:${emoteName.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')}:`, 'g')
    
    if (!emotePattern.test(text)) return

    const selection = window.getSelection()
    let cursorOffset = null
    let shouldRestoreCursor = false
    
    if (selection.rangeCount > 0) {
      const range = selection.getRangeAt(0)
      if (range.startContainer === textNode || range.endContainer === textNode) {
        cursorOffset = range.startOffset
        shouldRestoreCursor = true
      }
    }

    const parts = text.split(emotePattern)
    if (parts.length === 1) return

    const parent = textNode.parentNode
    const fragment = document.createDocumentFragment()
    let newCursorNode = null
    let newCursorOffset = 0
    
    for (let i = 0; i < parts.length; i++) {
      if (i > 0) {
        const img = document.createElement('img')
        img.src = emote.url
        img.alt = `:${emoteName}:`
        img.className = 'inline-emote'
        img.style.cssText = 'width: 20px; height: 20px; vertical-align: middle; display: inline-block;'
        img.dataset.emoteName = emoteName
        fragment.appendChild(img)
        
        if (shouldRestoreCursor && cursorOffset !== null) {
          const emoteStartPos = parts.slice(0, i).join('').length + (`:${emoteName}:`.length * (i - 1))
          const emoteEndPos = emoteStartPos + `:${emoteName}:`.length
          
          if (cursorOffset >= emoteStartPos && cursorOffset <= emoteEndPos) {
            // Have to creatwe a text node otherwise editor js will reset the cursor regardless
            const spacerNode = document.createTextNode('')
            fragment.appendChild(spacerNode)
            newCursorNode = spacerNode
            newCursorOffset = 0
          }
        }
      }
      
      if (parts[i]) {
        const textPart = document.createTextNode(parts[i])
        fragment.appendChild(textPart)
        
        if (shouldRestoreCursor && !newCursorNode && cursorOffset !== null) {
          const partStartPos = parts.slice(0, i).join('').length + (`:${emoteName}:`.length * i)
          const partEndPos = partStartPos + parts[i].length
          
          if (cursorOffset >= partStartPos && cursorOffset <= partEndPos) {
            newCursorNode = textPart
            newCursorOffset = cursorOffset - partStartPos
          }
        }
      }
    }

    parent.replaceChild(fragment, textNode)
    
    if (shouldRestoreCursor && newCursorNode) {
      this.restoreCursorPosition(newCursorNode, newCursorOffset)
    }
  }

  restoreCursorPosition(node, offset) {
    const attempts = [0, 10, 50, 100]
    
    attempts.forEach(delay => {
      setTimeout(() => {
        try {
          const selection = window.getSelection()
          if (selection.rangeCount === 0 || !document.contains(node)) return
          
          const range = document.createRange()
          
          if (node.nodeType === Node.TEXT_NODE) {
            const safeOffset = Math.min(offset, node.textContent.length)
            range.setStart(node, safeOffset)
            range.setEnd(node, safeOffset)
          } else {
            range.setStartAfter(node)
            range.setEndAfter(node)
          }
          
          selection.removeAllRanges()
          selection.addRange(range)
        } catch (error) {
        }
      }, delay)
    })
  }

  async saveData() {
    try {
      this.convertEmotesToText()
      
      const outputData = await this.editor.save()
      this.inputTarget.value = JSON.stringify(outputData)
    } catch (error) {
      console.error('Saving failed:', error)
    }
  }

  convertEmotesToText() {
    const emoteImages = this.editorTarget.querySelectorAll('img.inline-emote[data-emote-name]')
    emoteImages.forEach(img => {
      const emoteName = img.dataset.emoteName
      const textNode = document.createTextNode(`:${emoteName}:`)
      img.parentNode.replaceChild(textNode, img)
    })
  }

  async validateContent() {
    try {
      const outputData = await this.editor.save()
      return outputData.blocks && outputData.blocks.length > 0
    } catch (error) {
      console.error('Validation failed:', error)
      return false
    }
  }
} 