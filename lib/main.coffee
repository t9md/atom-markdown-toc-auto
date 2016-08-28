_ = require 'underscore-plus'
{CompositeDisposable, Range} = require 'atom'

TOC_START_TEMPLATE = "<!-- TOC START:CONFIG_PART -->"
CONFIG_PART = " min:MIN_LEVEL max:MAX_LEVEL"

TOC_START = TOC_START_TEMPLATE.replace('CONFIG_PART', CONFIG_PART)
TOC_END = '<!-- TOC END -->'
HEADER_REGEXP = /^(#+)\s*(.*$)$/g

findExistingTOCRange = (editor) ->
  rangeStart = null
  rangeEnd = null

  pattern = _.escapeRegExp(TOC_START_TEMPLATE).replace('CONFIG_PART', '.*')
  pattern = ///^#{pattern}$///
  scanRange = new Range([0, 0], editor.getEofBufferPosition())
  editor.scanInBufferRange pattern, scanRange, ({range, stop}) ->
    rangeStart = range.start
    scanRange.start = range.end
    stop()

  return unless rangeStart?

  pattern = ///#{_.escapeRegExp(TOC_END)}///
  editor.scanInBufferRange pattern, scanRange, ({range, stop}) ->
    rangeEnd = range.end
    stop()

  new Range(rangeStart, rangeEnd) if rangeEnd?

# TOC generation
# -------------------------
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

# Extract markdown headers from editor
# -------------------------
extractLinkText = (text) ->
  text.replace(/\[(.*?)\]\(https?:\/\/.*\)/, "$1") # extract link txt

isValidHeader = (editor, bufferPosition) ->
  scopeDescriptor = editor.scopeDescriptorForBufferPosition(bufferPosition)
  scopeDescriptor.scopes[1]?.startsWith('markup.heading')

scanHeaders = (editor) ->
  headers = []
  editor.scan HEADER_REGEXP, ({match, range}) ->
    return unless isValidHeader(editor, range.start)
    level = match[1].length
    subject = extractLinkText(match[2])
    headers.push({level, subject})
  headers

# Misc
# -------------------------
TOC_START_REGEXP = _.escapeRegExp(TOC_START)
  .replace('MIN_LEVEL', '(\\d)')
  .replace('MAX_LEVEL', '(\\d)')

extractTOCSpec = (text) ->
  spec = {}
  if match = text.match(TOC_START_REGEXP)
    spec.minLevel = Math.max(match[1], 1)
    spec.maxLevel = Math.max(match[2], 1)
  spec

getDefaultTOCSpec = ->
  minLevel: atom.config.get('markdown-toc-auto.initialMinLevel')
  maxLevel: atom.config.get('markdown-toc-auto.initialMaxLevel')

# Main
# -------------------------
module.exports =
  paneContainerElement: null

  activate: ->
    @subscriptionByBuffer = new Map

    @subscriptions = new CompositeDisposable
    createToc = @createToc.bind(this)
    @subscribe atom.commands.add 'atom-text-editor[data-grammar="source gfm"]',
      'markdown-toc-auto:insert-toc': -> createToc(@getModel(), @getModel().getCursorBufferPosition())
      'markdown-toc-auto:insert-toc-at-top': -> createToc(@getModel(), [0, 0])

    isMarkDownEditor = (editor) ->
      editor.getGrammar().scopeName is "source.gfm"

    @subscribe atom.workspace.observeTextEditors (editor) =>
      return if @subscriptionByBuffer.has(editor.buffer)
      # [FIXME] maybe buffer is different but path is same possibility?
      do (editor) =>
        disposable = editor.onDidSave =>
          if isMarkDownEditor(editor) and (range = findExistingTOCRange(editor))
            @updateToc(editor, range)
        @subscriptionByBuffer.set(editor.buffer, disposable)

  deactivate: ->
    @subscriptions?.dispose()
    @subscriptionByBuffer.forEach (disposable) -> disposable.dispose()
    @subscriptionByBuffer.clear()
    {@subscriptions, @paneContainerElement, @subscriptionByBuffer} = {}

  subscribe: (arg) ->
    @subscriptions.add(arg)

  createToc: (editor, point) ->
    options = _.defaults(getDefaultTOCSpec(), update: false)
    @insertToc(editor, [point, point], options)

  updateToc: (editor, range) ->
    tocStartText = editor.lineTextForBufferRow(range.start.row)
    options = _.defaults(extractTOCSpec(tocStartText), update: true)
    @insertToc(editor, range, options)

  insertToc: (editor, range, {minLevel, maxLevel, update}) ->
    headers = scanHeaders(editor).filter (header) ->
      minLevel <= header.level <=  maxLevel

    tocStart = TOC_START
      .replace('MIN_LEVEL', minLevel)
      .replace('MAX_LEVEL', maxLevel)

    toc = """
      #{tocStart}
      #{generateToc(headers)}

      #{TOC_END}
      """

    toc += "\n\n" unless update
    editor.setTextInBufferRange(range, toc)
