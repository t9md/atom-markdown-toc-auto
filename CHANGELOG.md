# 0.11.0:
- Fix: Fix inappropriate link target generation. Now correctly extract textContent from TAG by @justinhartman. #20
- Improve: Improve toc title extraction from header, now strip 'a' tag from toc title. #21
- Improve: Add test specs. #21

# 0.10.0:
- Fix: No longer eliminate harmless multibyte chars in header, so now header containing multibyte chars is properly linked. #19

# 0.9.1:
- Fix: Fix deprecated `undo` option for `editor.setTextInBufferRange()` function. #17

# 0.9.0:
- Improve: Specified `min` level header now have ZERO indent #13 by @nemoDreamer
- Maintenance: Convert to JavaScript from CoffeeScript.

# 0.8.0:
- Improve: Add support for `language-markdown` grammar by @thancock20.
  - Caution: This pkg still intended to generate toc only for `gfm`.
  - Why I added this is just to mitigate frustration for user using `language-markdown` for all `.md` file.

# 0.7.0:
- Improve: Package activation performance improved.

# 0.6.2
- Improve: Accurate link suffix when header include special character.

# 0.6.1
- Fix: Degradation link options were ignored. Respect it again.

# 0.6.0
- Improve: Add link suffix when same subject header appeared multiple time. #6

# 0.5.0
- Improve: No longer have to save twice to save updated toc at `onDidSave` timing.
  - Since now use `onWillSave` event instead of previous `onDidSave`.
- Fix: Guard to be called auto toc update hook multiple time on save file #2
- Improve: Keep cursor position before and after the toc insertion.
- Improve: Skip toc insertion from undo handling.

# 0.4.1
- Fix: Header was not genrated correctly
- Fix: debug print on `generateToc`

# 0.4.0 unpublished
- Improve: Re-organize file organization(extract private function to utils.coffee).
- New, Breaking: New(`link`, `update`). Renamed(`initialMinLevel` to `min`,  `initialMaxLevel` to `max`).
- Internal: Cleanup codes.
- Improve: Extract link text from img link(`![]`).

# 0.3.0:
- New, Breaking: `insert-toc` renamed to `insert-toc-at-top` and existing `insert-toc` insert TOC at cursor.
- Improve: Now TOC area don't have to be start at top line(row=0).

# 0.2.0:
- Improve: Extract text when link(`[text](link)`) is used in header.
- New: Support `max:` and `min:` pragma to specify header level for toc.

# 0.1.0:
- Initial release.
