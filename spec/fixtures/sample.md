<!-- TOC START min:1 max:3 link:true update:true -->
- [kind](#kind)
    - [Operations package](#operations-package)
    - [Other package](#other-package)
- [Operations package](#operations-package-1)
    - [move-to-symbols by t9md](#move-to-symbols-by-t9md)
    - [jasmine-increase-focus by t9md](#jasmine-increase-focus-by-t9md)
    - [subword-movement by crshd](#subword-movement-by-crshd)
    - [replace-with-execution by t9md](#replace-with-execution-by-t9md)
    - [move-selected-text by t9md](#move-selected-text-by-t9md)
    - [quick-highlight by t9md](#quick-highlight-by-t9md)
- [Other package](#other-package-1)
    - [vim-mode-plus-ex-mode by t9md](#vim-mode-plus-ex-mode-by-t9md)
    - [project-find-from-search by t9md](#project-find-from-search-by-t9md)
    - [narrow by t9md](#narrow-by-t9md)

<!-- TOC END -->

Intentionally use word **plugin** to distinguish it from normal general Atom package.

**Use link to package on atom.io**. User can jump to github repo from there.  

# kind

### Operations package

Add one of Operator/TextObject/Motion for vmp, essentially provide commands which command is derived from child class of `Base` class.

### Other package

Package not fall into operations package like adding ex-mode support.

# Operations package

### [move-to-symbols](https://atom.io/packages/vim-mode-plus-move-to-symbols) by t9md

Provide motion to move around symbols provided by bundled symbols-view package.  
Symbols are where you can move with `cmd-r` command.  

### [jasmine-increase-focus](https://atom.io/packages/vim-mode-plus-jasmine-increase-focus) by t9md

Provide operator to increase/decrease focus level text of jasmine spec.

### [subword-movement](https://atom.io/packages/vim-mode-plus-subword-movement) by crshd

Provide motion and text-object for subword.

### [replace-with-execution](https://atom.io/packages/vim-mode-plus-replace-with-execution) by t9md

Replace selected text with the result of stdout of execution.  

### [move-selected-text](https://atom.io/packages/vim-mode-plus-move-selected-text) by t9md

Move selected text like object.  
Feature migration from [vim-textmanip](https://github.com/t9md/vim-textmanip) plugin for pure Vim.  

### [quick-highlight](https://atom.io/packages/quick-highlight) by t9md

This package is not vmp specific, it can create multiple persisted highlight.  
This package includes `vim-mode-plus-user:quick-highlight` commands.  
This is operator to highlight keyword specified as operator target.  

# Other package

### [vim-mode-plus-ex-mode](https://atom.io/packages/vim-mode-plus-ex-mode) by t9md

### [project-find-from-search](https://atom.io/packages/vim-mode-plus-project-find-from-search) by t9md

Seamless flow from vmp's search(`/`, `?`) to find-and-replace's project-find.

### [narrow](https://atom.io/packages/narrow) by t9md

It's general purpose package similar to `unite.vim` or `helm-emacs`.  
It have special integration with vmp.  
From vmp's search input-ui, directly start `narrow:line` or `narrow:search`.  
