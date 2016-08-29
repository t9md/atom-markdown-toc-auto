# markdown-toc-auto [![Build Status](https://travis-ci.org/t9md/atom-markdown-toc-auto.svg?branch=master)](https://travis-ci.org/t9md/atom-markdown-toc-auto)

Automatically update table of contents for GitHub wiki.

![gif](https://raw.githubusercontent.com/t9md/t9md/12d553f0ec6d5ae921dea200ae2250f718a09523/img/atom-markdown-toc-auto.gif)

# Featuresaa

- Insert TOC
- Automatically update TOC on editor save.
- Customizable `max` and `min` level of header to use. auto `update`, inlucde `link` or not.
- Extract only markdown header by using Atom's scope descriptor used in syntax highlight(So ignore `#` in embedded code in markdown).
- Generate link for GitHub wiki
  - Remove invalid char for link
  - Extract inner text(`xxx`) from `<kbd>xxx</kbd>` tag and use in link.

# How to use

1. Open markdown editor
2. From command-palette, invoke "Markdown Toc Auto: Insert Toc". TOC is inserted at cursor position.
3. Each time you save editor, TOC is automatically updated.
4. [Optional] You can change following TOC options to control toc generation.
  - `min`, `max`: From `min` to `max` level headers are subject to generate.
  - `update`: If `true`, automatically updated on save.
  - `link`: If `false`, link are not generated.

# Commands

- `markdown-toc-auto:insert-toc`: Insert TOC on cursor position.
- `markdown-toc-auto:insert-toc-at-top`: Insert TOC on top of buffer.

# Limitation

- Currently only `source gfm` editor is supported.
- And only checked with GitHub Wiki.
- Header style must start with `#`.

# Why I created yet another packge?

- As exercise.
- Wanted to correctly ignore embedded code's comment `#`.
- Wanted to generate valid link in github wiki(for [vim-mode-plus](https://atom.io/packages/vim-mode-plus)'s wiki).

# Similar project

- [markdown-toc](https://atom.io/packages/markdown-toc)
- [atom-mdtoc](https://atom.io/packages/atom-mdtoc)
