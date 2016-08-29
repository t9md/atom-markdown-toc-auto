_ = require 'underscore-plus'
{Range} = require 'atom'

TOC_START_TEMPLATE = "<!-- TOC START:CONFIG_PART -->"
CONFIG_PART = " min:MIN_LEVEL max:MAX_LEVEL"
TOC_START = TOC_START_TEMPLATE.replace('CONFIG_PART', CONFIG_PART)
TOC_END = '<!-- TOC END -->'
HEADER_REGEXP = /^(#+)\s*(.*$)$/g

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

extractTocSpec = (text) ->
  spec = {}
  if match = text.match(TOC_START_REGEXP)
    spec.minLevel = Math.max(match[1], 1)
    spec.maxLevel = Math.max(match[2], 1)
  spec

getDefaultTocSpec = ->
  minLevel: atom.config.get('markdown-toc-auto.initialMinLevel')
  maxLevel: atom.config.get('markdown-toc-auto.initialMaxLevel')

insertToc = (editor, range, {minLevel, maxLevel, update}) ->
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

# Public
# -------------------------
exports.createToc = (editor, point) ->
  options = _.defaults(getDefaultTocSpec(), update: false)
  insertToc(editor, [point, point], options)

exports.updateToc = (editor, range) ->
  tocStartText = editor.lineTextForBufferRow(range.start.row)
  options = _.defaults(extractTocSpec(tocStartText), update: true)
  insertToc(editor, range, options)

exports.isMarkDownEditor = (editor) ->
  editor.getGrammar().scopeName is "source.gfm"

exports.findExistingTocRange = (editor) ->
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
