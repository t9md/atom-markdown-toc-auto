# markdown-toc-auto

Automatically update table of contents for GitHub wiki.

![gif](https://raw.githubusercontent.com/t9md/t9md/12d553f0ec6d5ae921dea200ae2250f718a09523/img/atom-markdown-toc-auto.gif)

# How to use

1. Open markdown editor
2. From command-palette, invoke "Markdown Toc Auto: Insert Toc". TOC is inserted at top of buffer.
3. Each time you save editor, TOC is automatically updated.

# Features

- Insert TOC
- Automatically update TOC on editor save.
- Ignore embedded code in markdown.
- Generate link for GitHub wiki
  - Remove invalid char for link
  - Extract inner text(`xxx`) from `<kbd>xxx</kbd>` tag and use in link.

# Commands

- `markdown-toc-auto:insert-toc`: Insert TOC on top of buffer.

# Limitation

Currently only `source gfm` editor is supported.  
And only checked with GitHub Wiki.  
Header style must start with `#`.  

# Why I created yet another packge?

- As exercise.
- Wanted to correctly ignore embedded code's comment `#`.
- Wanted to generate valid link in github wiki(for [vim-mode-plus](https://atom.io/packages/vim-mode-plus)'s wiki).

# Related project

- [markdown-toc](https://atom.io/packages/markdown-toc)
