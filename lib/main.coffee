_ = require 'underscore-plus'
{CompositeDisposable, Range} = require 'atom'

TOC_START = '<!-- TOC START min:MIN_LEVEL max:MAX_LEVEL -->'
TOC_END = '<!-- TOC END -->'
HEADER_REGEXP = /^(#+)\s*(.*$)$/g

isTocExists = (editor) ->
  # Need to tolerant to support old header(no 'max' option)
  editor.lineTextForBufferRow(0).match(/^<!\-\- TOC START( .*)? \-\->$/)

isMarkDownEditor = (editor) ->
  editor.getGrammar().scopeName is "source.gfm"

isValidHeader = (editor, bufferPosition) ->
  scopeDescriptor = editor.scopeDescriptorForBufferPosition(bufferPosition)
  scopeDescriptor.scopes[1]?.startsWith('markup.heading')

getRangeToInsert = (editor) ->
  return unless isTocExists(editor)

  pattern = ///#{_.escapeRegExp(TOC_END)}///
  rangeEnd = null
  editor.scan pattern, ({range, stop}) ->
    rangeEnd = range.end
    stop()

  new Range([0, 0], rangeEnd) if rangeEnd?

extractLinkText = (text) ->
  text.replace(/\[(.*?)\]\(https?:\/\/.*\)/, "$1") # extract link txt

linkFor = (text) ->
  text
    .toLowerCase()
    .replace(/\s/g, '-')
    .replace(/\<(.*?)>(.+)<\/\1>/g, "$2") # exract inner text
    .replace(/[^\w-]/g, '') # Remove non-(alphanumeric or '-') char.

generateToc = (headers) ->
  indent = "  "
  headers.map ({level, subject}) ->
    "#{indent.repeat(level-1)}- [#{subject}](##{linkFor(subject)})"
  .join("\n")

scanHeaders = (editor) ->
  headers = []
  editor.scan HEADER_REGEXP, ({match, range}) ->
    return unless isValidHeader(editor, range.start)
    level = match[1].length
    subject = extractLinkText(match[2])
    headers.push({level, subject})
  headers

getTOCHeader = (minLevel, maxLevel) ->
  TOC_START
    .replace('MIN_LEVEL', minLevel)
    .replace('MAX_LEVEL', maxLevel)

TOC_START_REGEXP = _.escapeRegExp(TOC_START)
  .replace('MIN_LEVEL', '(\\d)')
  .replace('MAX_LEVEL', '(\\d)')

insertToc = (editor, range=null) ->
  if range?
    isUpdate = true
    if match = editor.lineTextForBufferRow(0).match(TOC_START_REGEXP)
      minLevel = Math.max(match[1], 1)
      maxLevel = Math.max(match[2], 1)
  else
    isUpdate = false
    range = [[0, 0], [0, 0]]

  minLevel ?= atom.config.get('markdown-toc-auto.initialMinLevel')
  maxLevel ?= atom.config.get('markdown-toc-auto.initialMaxLevel')

  headers = scanHeaders(editor).filter (header) -> minLevel <= header.level <=  maxLevel

  toc = """
    #{getTOCHeader(minLevel, maxLevel)}
    #{generateToc(headers)}

    #{TOC_END}
    """

  toc += "\n\n" unless isUpdate
  editor.setTextInBufferRange(range, toc)

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
