_ = require 'underscore-plus'
{Range} = require 'atom'
{inspect} = require 'util'

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

MARKDOWN_HEADER_REGEXP = /^(#+)\s*(.*$)$/g
scanHeaders = (editor) ->
  headers = []
  editor.scan MARKDOWN_HEADER_REGEXP, ({match, range}) ->
    return unless isValidHeader(editor, range.start)
    level = match[1].length
    subject = extractLinkText(match[2])
    headers.push({level, subject})
  headers

# Misc
# -------------------------
extractTocSpec = (text) ->
  spec = {}
  if match = text.match(TOC_START_REGEXP)
    params = match[1].trim().split(/\s+/)
    for param in params
      [key, value] = param.split(':')
      switch key
        when 'min', 'max'
          spec[key] = Number(value)
        else
          if value in ['true', 'false']
            spec[key] = value is 'true'
    spec

serializeTocSpec = (tocSpec) ->
  JSON.stringify(tocSpec)
    .replace(/[{"}]/g, '')
    .replace(/,/g, ' ')

getDefaultTocSpec = ->
  settings.getSpecOptions()

insertToc = (editor, range, create=false, tocSpec) ->
  headers = scanHeaders(editor).filter (header) ->
    tocSpec.min <= header.level <= tocSpec.max

  # console.log tocSpec.update
  {inspect} = require 'util'
  p = (args...) -> console.log inspect(args...)
  p tocSpec
  return if (not create) and (not tocSpec.update)

  tocSpecString = serializeTocSpec(tocSpec)
  toc = """
    <!-- TOC START #{tocSpecString} -->
    #{generateToc(headers)}

    #{TOC_END}
    """

  toc += "\n\n" if create
  editor.setTextInBufferRange(range, toc)

# Public
# -------------------------
exports.createToc = (editor, point) ->
  insertToc(editor, [point, point], true, getDefaultTocSpec())

exports.updateToc = (editor, range) ->
  tocStartText = editor.lineTextForBufferRow(range.start.row)
  options = _.defaults(extractTocSpec(tocStartText), getDefaultTocSpec())
  insertToc(editor, range, false, options)

exports.isMarkDownEditor = (editor) ->
  editor.getGrammar().scopeName is "source.gfm"

exports.findExistingTocRange = (editor) ->
  rangeStart = null
  rangeEnd = null

  scanRange = new Range([0, 0], editor.getEofBufferPosition())
  editor.scanInBufferRange TOC_START_REGEXP, scanRange, ({range, stop}) ->
    rangeStart = range.start
    scanRange.start = range.end
    stop()

  return unless rangeStart?

  editor.scanInBufferRange TOC_END_REGEXP, scanRange, ({range, stop}) ->
    rangeEnd = range.end
    stop()

  new Range(rangeStart, rangeEnd) if rangeEnd?
