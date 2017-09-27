{CompositeDisposable} = require 'atom'

utils = null
getUtils = -> utils ?= require('./utils')

# Main
# -------------------------
module.exports =
  activate: ->
    @subscriptionByURL = new Map

    @subscriptions = new CompositeDisposable

    commands =
      'markdown-toc-auto:insert-toc': -> getUtils().createToc(@getModel())
      'markdown-toc-auto:insert-toc-at-top': -> getUtils().createToc(@getModel(), [0, 0])

    @subscribe atom.commands.add('atom-text-editor[data-grammar="source gfm"]', commands)
    @subscribe atom.commands.add('atom-text-editor[data-grammar="text md"]', commands)

    @subscribe atom.workspace.observeTextEditors (editor) =>
      URI = editor.getURI()
      return unless editor.getGrammar().scopeName in ["source.gfm", "text.md"]
      return if @subscriptionByURL.has(URI)

      tocRange = null
      disposable = editor.buffer.onWillSave ->
        if tocRange ?= getUtils().findTocRange(editor)
          getUtils().updateToc(editor, tocRange)
          tocRange = null

      @subscriptionByURL.set(URI, disposable)

  deactivate: ->
    @subscriptions?.dispose()
    @subscriptionByURL.forEach (disposable) -> disposable.dispose()
    @subscriptionByURL.clear()
    {@subscriptions, @subscriptionByURL} = {}

  subscribe: (arg) ->
    @subscriptions.add(arg)
