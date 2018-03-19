_ = require 'underscore-plus'
{Range} = require 'atom'

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

# Set title and link
setTitleAndLink = (headers) ->
  countByLink = {}

  for header in headers
    title = titleFor(header.subject)
    link = linkFor(title)

    if not (link of countByLink)
      countByLink[link] = 0
      linkSuffix = ''
    else
      countByLink[link] += 1
      linkSuffix = "-" + countByLink[link]

    header.title = title
    header.link = link + linkSuffix

generateToc = (headers, options) ->
  indentBase = "  "
  headers
    .filter (header) ->
      options.min <= header.level <= options.max

    .map ({level, title, link}) ->
      indent = indentBase.repeat(level-options.min)
      if options.link
        "#{indent}- [#{title}](##{link})"
      else
        "#{indent}- [#{title}]"

    .join("\n")

# Extract markdown headers from editor
# -------------------------
isMarkdownHeader = (editor, bufferPosition) ->
  {scopes} = editor.scopeDescriptorForBufferPosition(bufferPosition)
  scopes[1]?.startsWith('markup.heading') or scopes[1]?.startsWith('heading.markup.md')

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
        options[key] = value if (value = Number(value)) >= 1
      when 'link', 'update' # boolean
        options[key] = value is 'true' if value in ['true', 'false']
  options

serializeTocOptions = (tocOptions) ->
  JSON.stringify(tocOptions)
    .replace(/[{"}]/g, '')
    .replace(/,/g, ' ')

getDefaultTocOptions = ->
  options = {}
  for param in ['min', 'max', 'link', 'update']
    options[param] = atom.config.get("markdown-toc-auto.#{param}")
  options

insertToc = ({editor, range, options}) ->
  headers = scanHeaders(editor)
  setTitleAndLink(headers)

  toc = """
    <!-- TOC START #{serializeTocOptions(options)} -->
    #{generateToc(headers, options)}

    #{TOC_END}
    """

  toc += "\n\n" if range.isEmpty()
  bufferPositionByCursor = new Map()

  # Save original cursor position for the cusor which point will change.
  for cursor in editor.getCursors() when point = cursor.getBufferPosition()
    if range.containsPoint(point)
      bufferPositionByCursor.set(cursor, point)

  editor.setTextInBufferRange(range, toc, undo: 'skip')

  # Restore oiginal cursor position
  for cursor in editor.getCursors() when point = bufferPositionByCursor.get(cursor)
    cursor.setBufferPosition(point)

  bufferPositionByCursor.clear()

# Public
# -------------------------
createToc = (editor, point) ->
  point ?= editor.getCursorBufferPosition()
  range = new Range(point, point)
  insertToc({editor, range, options: getDefaultTocOptions()})

updateToc = (editor, range) ->
  tocStartText = editor.lineTextForBufferRow(range.start.row)

  options = {}
  if match = tocStartText.match(TOC_START_REGEXP)
    options = deserializeTocOptions(match[1])

  options = _.defaults(options, getDefaultTocOptions())

  if options.update
    insertToc({editor, range, options})

findTocRange = (editor) ->
  tocRange = []
  scanRange = new Range([0, 0], editor.getEofBufferPosition())
  editor.scanInBufferRange TOC_START_REGEXP, scanRange, ({range}) ->
    tocRange.push(range)

  return if tocRange.length is 0

  scanRange.start = tocRange[0].end
  editor.scanInBufferRange TOC_END_REGEXP, scanRange, ({range}) -> tocRange.push(range)
  new Range(tocRange[0].start, tocRange[1].end) if tocRange.length is 2

module.exports = {
  createToc
  updateToc
  findTocRange

  deserializeTocOptions
  serializeTocOptions
  generateToc
  scanHeaders
}
