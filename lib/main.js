const {CompositeDisposable} = require('atom')

let utils
function getUtils () {
  if (!utils) utils = require('./utils')
  return utils
}

function isMarkdownEditor (editor) {
  return ['source.gfm', 'text.md'].includes(editor.getGrammar().scopeName)
}

// Main
// -------------------------
module.exports = {
  activate () {
    this.subscriptionByURL = new Map()

    const commands = {
      'markdown-toc-auto:insert-toc' () {
        const editor = this.getModel()
        getUtils().insertTocAtPoint(editor, editor.getCursorBufferPosition())
      },
      'markdown-toc-auto:insert-toc-at-top' () {
        getUtils().insertTocAtPoint(this.getModel(), [0, 0])
      }
    }

    this.subscriptions = new CompositeDisposable(
      atom.commands.add('atom-text-editor[data-grammar="source gfm"]', commands),
      atom.commands.add('atom-text-editor[data-grammar="text md"]', commands),
      atom.workspace.observeTextEditors(editor => {
        if (!isMarkdownEditor(editor)) return
        const URI = editor.getURI()

        if (!this.subscriptionByURL.has(URI)) {
          this.subscriptionByURL.set(URI, editor.buffer.onWillSave(() => getUtils().updateToc(editor)))
        }
      })
    )
  },

  deactivate () {
    this.subscriptions.dispose()
    this.subscriptionByURL.forEach(disposable => disposable.dispose())
    this.subscriptionByURL.clear()
  }
}
