{CompositeDisposable} = require 'atom'
settings = require './settings'

utils = null
getUtils = -> utils ?= require('./utils')

# Main
# -------------------------
module.exports =
  config: settings.config

  activate: ->
    @subscriptionByURL = new Map

    @subscriptions = new CompositeDisposable
    @subscribe atom.commands.add 'atom-text-editor[data-grammar="source gfm"]',
      'markdown-toc-auto:insert-toc': -> getUtils().createToc(@getModel())
      'markdown-toc-auto:insert-toc-at-top': -> getUtils().createToc(@getModel(), [0, 0])

    @subscribe atom.workspace.observeTextEditors (editor) =>
      URI = editor.getURI()
      return unless editor.getGrammar().scopeName is "source.gfm"
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
