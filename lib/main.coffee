_ = require 'underscore-plus'
{CompositeDisposable, Range} = require 'atom'

TOC_START = '<!-- TOC START -->'
TOC_END = '<!-- TOC END -->'
HEADER_REGEXP = /^(#+)\s*(.*$)$/g

isTocExists = (editor) ->
  editor.lineTextForBufferRow(0) is TOC_START

isMarkDownEditor = (editor) ->
  editor.getGrammar().scopeName is "source.gfm"

isValidHeader = (editor, bufferPosition) ->
  scopeDescriptor = editor.scopeDescriptorForBufferPosition(bufferPosition)
  scopeDescriptor.scopes[1]?.startsWith('markup.heading')

getRangeToInsert = (editor) ->
  return null unless isTocExists(editor)

  pattern = ///#{_.escapeRegExp(TOC_END)}///
  rangeEnd = null
  editor.scan pattern, ({range, stop}) ->
    rangeEnd = range.end
    stop()

  if rangeEnd?
    new Range([0, 0], rangeEnd)

linkFor = (text) ->
  text
    .toLowerCase()
    .replace(/\s/g, '-')
    .replace(/\<(.*?)>(.+)<\/\1>/g, "$2") # exract inner text
    .replace(/[^\w-]/g, '') # Is this correct?

generateToc = (headers) ->
  texts = []
  for {level, subject} in headers
    indent = "  ".repeat(level)
    topic = "#{indent}- [#{subject}](##{linkFor(subject)})"
    texts.push(topic)
  texts.join("\n")

scanHeaders = (editor) ->
  headers = []
  editor.scan HEADER_REGEXP, ({match, range}) ->
    return unless isValidHeader(editor, range.start)
    level = match[1].length - 1
    subject = match[2]
    headers.push({level, subject})
  headers

insertToc = (editor, range=null) ->
  tableOfContents = """
    #{TOC_START}
    #{generateToc(scanHeaders(editor))}

    #{TOC_END}
    """

  unless range?
    range = [[0, 0], [0, 0]]
    tableOfContents += "\n\n"

  editor.setTextInBufferRange(range, tableOfContents)

updateToc = (editor) ->
  if range = getRangeToInsert(editor)
    insertToc(editor, range)

# Main
# -------------------------
module.exports =
  paneContainerElement: null

  activate: ->
    @subscriptionByBuffer = new Map

    @subscriptions = new CompositeDisposable
    @subscribe atom.commands.add 'atom-text-editor[data-grammar="source gfm"]',
      'markdown-toc-auto:insert-toc': -> insertToc(@getModel())

    @subscribe atom.workspace.observeTextEditors (editor) =>
      return if @subscriptionByBuffer.has(editor.buffer)
      do (editor) =>
        disposable = editor.onDidSave -> updateToc(editor) if isMarkDownEditor(editor)
        @subscriptionByBuffer.set(editor.buffer, disposable)

  deactivate: ->
    @subscriptions?.dispose()
    @subscriptionByBuffer.forEach (disposable) -> disposable.dispose()
    @subscriptionByBuffer.clear()
    {@subscriptions, @paneContainerElement, @subscriptionByBuffer} = {}

  subscribe: (arg) ->
    @subscriptions.add(arg)
