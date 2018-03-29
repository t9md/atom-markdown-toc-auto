const _ = require('underscore-plus')
const {Range} = require('atom')
const dedent = require('dedent')

const TOC_END = '<!-- TOC END -->'
const TOC_START_REGEXP = /<!\-\- TOC START (.*)?\-\->/i
const TOC_END_REGEXP = new RegExp(`${_.escapeRegExp(TOC_END)}`, 'i')

// TOC generation
// -------------------------
function linkFor (text) {
  return text
    .toLowerCase()
    .replace(/\s/g, '-')
    .replace(/\<(.*?)>(.+)<\/\1>/g, '$2') // e.g. exract 'a' from <kbd>a<kbd>
    .replace(/[^\w-]/g, '') // Remove non-(alphanumeric or '-') char.
}

function titleFor (text) {
  return text
    .replace(/!\[.*?\]\(https?:\/\/.*?\)/g, '') // Remove img link
    .replace(/\[(.*?)\]\(https?:\/\/.*?\)/g, '$1') // extract link txt
    .trim()
}

// Set title and link
function injectTitleAndLink (headers) {
  const countByLink = {}

  for (const header of headers) {
    let linkSuffix
    const title = titleFor(header.subject)
    const link = linkFor(title)

    if (!(link in countByLink)) {
      countByLink[link] = 0
      linkSuffix = ''
    } else {
      countByLink[link] += 1
      linkSuffix = '-' + countByLink[link]
    }
    header.title = title
    header.link = link + linkSuffix
  }
}

function buildTocText (headers, options) {
  injectTitleAndLink(headers)

  const indentBase = '  '
  return headers
    .filter(header => options.min <= header.level && header.level <= options.max)
    .map(header => {
      const indent = indentBase.repeat(header.level - options.min)
      if (options.link) {
        return `${indent}- [${header.title}](#${header.link})`
      } else {
        return `${indent}- [${header.title}]`
      }
    })
    .join('\n')
}

// Extract markdown headers from editor
// -------------------------
function isMarkdownHeader (editor, bufferPosition) {
  const {scopes} = editor.scopeDescriptorForBufferPosition(bufferPosition)
  const scope = scopes[1]
  return (scope != null && scope.startsWith('markup.heading')) || scope.startsWith('heading.markup.md')
}

const MARKDOWN_HEADER_REGEXP = /^(#+)\s*(.*$)$/g
function scanHeaders (editor) {
  const headers = []
  editor.scan(MARKDOWN_HEADER_REGEXP, ({match, range}) => {
    if (!isMarkdownHeader(editor, range.start)) {
      return
    }
    const level = match[1].length
    const subject = match[2]
    headers.push({level, subject})
  })
  return headers
}

// Misc
// -------------------------
function deserializeTocOptions (text) {
  const options = {}
  for (const param of text.trim().split(/\s+/)) {
    let [key, value] = param.split(':')
    switch (key) {
      case 'min':
      case 'max': // integer
        const number = Number(value)
        if (number >= 1) options[key] = number
        break
      case 'link':
      case 'update': // boolean
        if (['true', 'false'].includes(value)) {
          options[key] = value === 'true'
        }
        break
    }
  }
  return options
}

function serializeTocOptions (tocOptions) {
  return JSON.stringify(tocOptions)
    .replace(/[{"}]/g, '')
    .replace(/,/g, ' ')
}

function getDefaultTocOptions () {
  return {
    min: atom.config.get('markdown-toc-auto.min'),
    max: atom.config.get('markdown-toc-auto.max'),
    link: atom.config.get('markdown-toc-auto.link'),
    update: atom.config.get('markdown-toc-auto.update')
  }
}

// Public
// -------------------------
function insertToc (editor, range, options = {}) {
  range = Range.fromObject(range)
  options = Object.assign(getDefaultTocOptions(), options)

  const list = []
  let toc = ''
  toc += `<!-- TOC START ${serializeTocOptions(options)} -->\n`
  toc += buildTocText(scanHeaders(editor), options) + '\n\n'
  toc += TOC_END + (range.isEmpty() ? '\n\n' : '')

  const bufferPositionByCursor = new Map()
  // Save original cursor position for the cusor which point will change.
  for (const cursor of editor.getCursors()) {
    const point = cursor.getBufferPosition()
    if (range.containsPoint(point)) {
      bufferPositionByCursor.set(cursor, point)
    }
  }

  editor.setTextInBufferRange(range, toc, {undo: 'skip'})

  // Restore oiginal cursor position
  for (const cursor of editor.getCursors()) {
    const point = bufferPositionByCursor.get(cursor)
    if (point) {
      cursor.setBufferPosition(point)
    }
  }
}

function insertTocAtPoint (editor, point) {
  insertToc(editor, [point, point])
}

function updateToc (editor) {
  const range = findTocRange(editor)
  if (range) {
    const tocStartRowText = editor.lineTextForBufferRow(range.start.row)
    const match = tocStartRowText.match(TOC_START_REGEXP)
    if (match) {
      const options = deserializeTocOptions(match[1])
      if (options.update) {
        insertToc(editor, range, options)
      }
    }
  }
}

function findTocRange (editor) {
  const tocRange = []
  const scanRange = new Range([0, 0], editor.getEofBufferPosition())
  editor.scanInBufferRange(TOC_START_REGEXP, scanRange, ({range}) => tocRange.push(range))

  if (tocRange.length === 0) {
    return
  }

  scanRange.start = tocRange[0].end
  editor.scanInBufferRange(TOC_END_REGEXP, scanRange, ({range}) => tocRange.push(range))
  if (tocRange.length === 2) {
    return new Range(tocRange[0].start, tocRange[1].end)
  }
}

module.exports = {
  createToc,
  updateToc,

  deserializeTocOptions,
  serializeTocOptions,
  buildTocText,
  scanHeaders
}
