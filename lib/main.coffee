{CompositeDisposable} = require 'atom'
{
  createToc
  updateToc
  isMarkDownEditor
  findExistingTocRange
} = require './utils'

# Main
# -------------------------
module.exports =
  paneContainerElement: null

  activate: ->
    @subscriptionByBuffer = new Map

    @subscriptions = new CompositeDisposable
    @subscribe atom.commands.add 'atom-text-editor[data-grammar="source gfm"]',
      'markdown-toc-auto:insert-toc': -> createToc(@getModel(), @getModel().getCursorBufferPosition())
      'markdown-toc-auto:insert-toc-at-top': -> createToc(@getModel(), [0, 0])

    @subscribe atom.workspace.observeTextEditors (editor) =>
      return if @subscriptionByBuffer.has(editor.buffer)
      # [FIXME] maybe buffer is different but path is same possibility?
      do (editor) =>
        disposable = editor.onDidSave ->
          updateToc(editor, range) if isMarkDownEditor(editor) and (range = findExistingTocRange(editor))
        @subscriptionByBuffer.set(editor.buffer, disposable)

  deactivate: ->
    @subscriptions?.dispose()
    @subscriptionByBuffer.forEach (disposable) -> disposable.dispose()
    @subscriptionByBuffer.clear()
    {@subscriptions, @subscriptionByBuffer} = {}

  subscribe: (arg) ->
    @subscriptions.add(arg)
