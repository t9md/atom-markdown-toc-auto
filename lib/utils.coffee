_ = require 'underscore-plus'
{Range} = require 'atom'
settings = require './settings'

TOC_END = '<!-- TOC END -->'
TOC_START_REGEXP = /<!\-\- TOC START (.*)?\-\->/
TOC_END_REGEXP = ///#{_.escapeRegExp(TOC_END)}///

# TOC generation
# -------------------------
linkFor = (text) ->
  text
    .toLowerCase()
    .replace(/\s/g, '-')
    .replace(/\<(.*?)>(.+)<\/\1>/g, "$2") # e.g. exract 'a' from <kbd>a<kbd>
    .replace(/[^\w-]/g, '') # Remove non-(alphanumeric or '-') char.

generateToc = (headers) ->
  indent = "  "
  headers
    .map ({level, subject}) -> "#{indent.repeat(level-1)}- [#{subject}](##{linkFor(subject)})"
    .join("\n")

# Extract markdown headers from editor
# -------------------------
extractLinkText = (text) ->
  text.replace(/\[(.*?)\]\(https?:\/\/.*\)/, "$1") # extract link txt

isMarkdownHeader = (editor, bufferPosition) ->
  {scopes} = editor.scopeDescriptorForBufferPosition(bufferPosition)
  scopes[1]?.startsWith('markup.heading')

MARKDOWN_HEADER_REGEXP = /^(#+)\s*(.*$)$/g
scanHeaders = (editor) ->
  headers = []
  editor.scan MARKDOWN_HEADER_REGEXP, ({match, range}) ->
    return unless isMarkdownHeader(editor, range.start)
    level = match[1].length
    subject = extractLinkText(match[2])
    headers.push({level, subject})
  headers

# Misc
# -------------------------
deserializeTocOptions = (text) ->
  options = {}
  for param in text.trim().split(/\s+/)
    [key, value] = param.split(':')
    switch key
      when 'min', 'max'
        options[key] = Number(value)
      else
        options[key] = value is 'true' if value in ['true', 'false']
  options

serializeTocOptions = (tocOptions) ->
  JSON.stringify(tocOptions)
    .replace(/[{"}]/g, '')
    .replace(/,/g, ' ')

getDefaultTocOptions = ->
  settings.getTocOptions()

insertToc = ({editor, range, create, tocOptions}) ->
  headers = scanHeaders(editor).filter (header) ->
    tocOptions.min <= header.level <= tocOptions.max

  return if (not create) and (not tocOptions.update)

  tocOptionsString = serializeTocOptions(tocOptions)
  toc = """
    <!-- TOC START #{tocOptionsString} -->
    #{generateToc(headers)}

    #{TOC_END}
    """

  toc += "\n\n" if create
  editor.setTextInBufferRange(range, toc)

# Public
# -------------------------
exports.createToc = (editor, point) ->
  insertToc(
    editor: editor
    range: [point, point]
    create: true
    tocOptions: getDefaultTocOptions()
  )

exports.updateToc = (editor, range) ->
  tocStartText = editor.lineTextForBufferRow(range.start.row)

  tocOptions = {}
  if match = tocStartText.match(TOC_START_REGEXP)
    tocOptions = deserializeTocOptions(match[1])

  insertToc(
    editor: editor
    range: range
    create: false
    tocOptions: _.defaults(tocOptions, getDefaultTocOptions())
  )

exports.isMarkDownEditor = (editor) ->
  editor.getGrammar().scopeName is "source.gfm"

exports.findTocRange = (editor) ->
  [startPoint, endPoint] = []

  scanRange = new Range([0, 0], editor.getEofBufferPosition())
  tocStartRange = null
  editor.scanInBufferRange TOC_START_REGEXP, scanRange, ({range, stop}) ->
    tocStartRange = range
    stop()

  return unless tocStartRange?
  scanRange.start = tocStartRange.end

  editor.scanInBufferRange TOC_END_REGEXP, scanRange, ({range, stop}) ->
    tocEndRange = range
    stop()

  new Range(tocStartRange.start, tocEndRange.end) if tocEndRange?
