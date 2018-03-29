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
function setTitleAndLink (headers) {
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

function generateToc (headers, options) {
  const indentBase = '  '
  return headers
    .filter(header => options.min <= header.level && header.level <= options.max)
    .map(({level, title, link}) => {
      const indent = indentBase.repeat(level - options.min)
      if (options.link) {
        return `${indent}- [${title}](#${link})`
      } else {
        return `${indent}- [${title}]`
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
  const options = {}
  for (const param of ['min', 'max', 'link', 'update']) {
    options[param] = atom.config.get(`markdown-toc-auto.${param}`)
  }
  return options
}

function insertToc ({editor, range, options}) {
  let point
  const headers = scanHeaders(editor)
  setTitleAndLink(headers)

  const list = []
  let toc = ''
  toc += `<!-- TOC START ${serializeTocOptions(options)} -->\n`
  toc += generateToc(headers, options) + '\n\n'
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

// Public
// -------------------------
function createToc (editor, point = editor.getCursorBufferPosition()) {
  insertToc({
    editor,
    range: new Range(point, point),
    options: getDefaultTocOptions()
  })
}

function updateToc (editor) {
  const range = findTocRange(editor)
  if (range) {
    const tocStartText = editor.lineTextForBufferRow(range.start.row)

    let options = {}
    const match = tocStartText.match(TOC_START_REGEXP)
    if (match) {
      options = deserializeTocOptions(match[1])
    }
    options = _.defaults(options, getDefaultTocOptions())

    if (options.update) {
      insertToc({editor, range, options})
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
  generateToc,
  scanHeaders
}
