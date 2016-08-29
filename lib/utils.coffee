_ = require 'underscore-plus'
{Range} = require 'atom'
settings = require './settings'

TOC_END = '<!-- TOC END -->'
TOC_START_REGEXP = /<!\-\- TOC START (.*)?\-\->/i
TOC_END_REGEXP = ///#{_.escapeRegExp(TOC_END)}///i

# TOC generation
# -------------------------
linkFor = (text) ->
  text
    .toLowerCase()
    .replace(/\s/g, '-')
    .replace(/\<(.*?)>(.+)<\/\1>/g, "$2") # e.g. exract 'a' from <kbd>a<kbd>
    .replace(/[^\w-]/g, '') # Remove non-(alphanumeric or '-') char.

titleFor = (text) ->
  text
    .replace(/!\[.*?\]\(https?:\/\/.*?\)/g, "") # Remove img link
    .replace(/\[(.*?)\]\(https?:\/\/.*?\)/g, "$1") # extract link txt
    .trim()

generateToc = (headers, tocOptions) ->
  indentBase = "  "
  headers
    .filter (header) ->
      tocOptions.min <= header.level <= tocOptions.max

    .map ({level, subject}) ->
      indent = indentBase.repeat(level-1)
      title = titleFor(subject)
      if tocOptions.link
        "#{indent}- [#{title}](##{linkFor(subject)})"
      else
        "#{indent}- [#{title}]"

    .join("\n")

# Extract markdown headers from editor
# -------------------------
isMarkdownHeader = (editor, bufferPosition) ->
  {scopes} = editor.scopeDescriptorForBufferPosition(bufferPosition)
  scopes[1]?.startsWith('markup.heading')

MARKDOWN_HEADER_REGEXP = /^(#+)\s*(.*$)$/g
scanHeaders = (editor) ->
  headers = []
  editor.scan MARKDOWN_HEADER_REGEXP, ({match, range}) ->
    return unless isMarkdownHeader(editor, range.start)
    level = match[1].length
    subject = match[2]
    headers.push({level, subject})
  headers

# Misc
# -------------------------
deserializeTocOptions = (text) ->
  options = {}
  for param in text.trim().split(/\s+/)
    [key, value] = param.split(':')
    switch key
      when 'min', 'max' # integer
        options[key] = Number(value)
      when 'link', 'update' # boolean
        options[key] = value is 'true' if value in ['true', 'false']
  options

serializeTocOptions = (tocOptions) ->
  JSON.stringify(tocOptions)
    .replace(/[{"}]/g, '')
    .replace(/,/g, ' ')

getDefaultTocOptions = ->
  settings.getTocOptions()

insertToc = ({editor, range, tocOptions}) ->
  headers = scanHeaders(editor)
  toc = """
    <!-- TOC START #{serializeTocOptions(tocOptions)} -->
    #{generateToc(headers, tocOptions)}

    #{TOC_END}
    """

  toc += "\n\n" if range.isEmpty()
  editor.setTextInBufferRange(range, toc)

# Public
# -------------------------
createToc = (editor, point) ->
  insertToc(
    editor: editor
    range: [point, point]
    tocOptions: getDefaultTocOptions()
  )

updateToc = (editor, range) ->
  tocStartText = editor.lineTextForBufferRow(range.start.row)

  tocOptions = {}
  if match = tocStartText.match(TOC_START_REGEXP)
    tocOptions = deserializeTocOptions(match[1])
    return unless tocOptions.update

  insertToc(
    editor: editor
    range: range
    tocOptions: _.defaults(tocOptions, getDefaultTocOptions())
  )

isMarkDownEditor = (editor) ->
  editor.getGrammar().scopeName is "source.gfm"

findRangeForPattern = (editor, pattern, scanRange) ->
  found = null
  editor.scanInBufferRange pattern, scanRange, ({range, stop}) ->
    found = range
    stop()
  found

findTocRange = (editor) ->
  [tocStartRange, tocEndRange] = []

  scanRange = new Range([0, 0], editor.getEofBufferPosition())
  tocStartRange = findRangeForPattern(editor, TOC_START_REGEXP, scanRange)

  return unless tocStartRange?

  scanRange.start = tocStartRange.end
  tocEndRange = findRangeForPattern(editor, TOC_END_REGEXP, scanRange)

  new Range(tocStartRange.start, tocEndRange.end) if tocEndRange?

module.exports = {
  createToc
  updateToc
  isMarkDownEditor
  findTocRange

  deserializeTocOptions
  serializeTocOptions
}
