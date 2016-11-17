{CompositeDisposable} = require 'atom'
{createToc, updateToc, isMarkDownEditor, findTocRange} = require './utils'
settings = require './settings'

# Main
# -------------------------
module.exports =
  config: settings.config

  activate: ->
    @subscriptionByURL = new Map

    @subscriptions = new CompositeDisposable
    @subscribe atom.commands.add 'atom-text-editor[data-grammar="source gfm"]',
      'markdown-toc-auto:insert-toc': -> createToc(@getModel(), @getModel().getCursorBufferPosition())
      'markdown-toc-auto:insert-toc-at-top': -> createToc(@getModel(), [0, 0])

    @subscribe atom.workspace.observeTextEditors (editor) =>
      URI = editor.getURI()
      return if @subscriptionByURL.has(URI)

      disposable = editor.buffer.onWillSave ->
        if isMarkDownEditor(editor) and (range = findTocRange(editor))
          updateToc(editor, range)

      @subscriptionByURL.set(URI, disposable)

  deactivate: ->
    @subscriptions?.dispose()
    @subscriptionByURL.forEach (disposable) -> disposable.dispose()
    @subscriptionByURL.clear()
    {@subscriptions, @subscriptionByURL} = {}

  subscribe: (arg) ->
    @subscriptions.add(arg)
