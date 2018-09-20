fs = require 'fs-plus'
temp = require 'temp'

path = require 'path'
{
  deserializeTocOptions
  serializeTocOptions
  generateToc
  linkFor
  titleFor
} = require '../lib/utils'

temp = require('temp').track()

describe "markdown-toc-auto", ->
  describe "serialize/desirializeTocOptions", ->
    it "serialize", ->
      serialized = serializeTocOptions({min: 1, max: 1, link: true, update: true})
      expect(serialized).toBe('min:1 max:1 link:true update:true')

    it "deserialize", ->
      expect(deserializeTocOptions('min:1')).toEqual({min: 1})
      expect(deserializeTocOptions('max:3')).toEqual({max: 3})
      expect(deserializeTocOptions('link:true')).toEqual({link: true})
      expect(deserializeTocOptions('update:false')).toEqual({update: false})

      deserialized = deserializeTocOptions('min:1 max:1 link:true update:true')
      expect(deserialized).toEqual({min: 1, max: 1, link: true, update: true})

    it "deserialize ignore invalid value", ->
      expect(deserializeTocOptions('link:99')).toEqual({})
      expect(deserializeTocOptions('link:abc')).toEqual({})
      expect(deserializeTocOptions('update:99')).toEqual({})
      expect(deserializeTocOptions('min:-1')).toEqual({})
      expect(deserializeTocOptions('max:-1')).toEqual({})
      expect(deserializeTocOptions('abc:def')).toEqual({})
      expect(deserializeTocOptions('abc')).toEqual({})
      expect(deserializeTocOptions('')).toEqual({})

  describe "linkFor function", ->
    describe "basic features", ->
      validateLinkFor = (before, after) ->
        expect(linkFor(before)).toEqual(after)

      it "keep multibyte-chars in header", ->
        validateLinkFor "日本語のヘッダーレベル1", "日本語のヘッダーレベル1"
        validateLinkFor "日本語の-ハイフン-を-含む-ヘッダー", "日本語の-ハイフン-を-含む-ヘッダー"
        validateLinkFor "double--hypen--header", "double--hypen--header"
        validateLinkFor "<kbd>a</kbd>b", "ab"
        validateLinkFor "<kbd>a<kbd>c", "ac",
        validateLinkFor "<kbd>FIRST</kbd> TITLE", "first-title"
        validateLinkFor "<kbd>T W O</kbd> TITLE", "t-w-o-title"
        validateLinkFor "TESTING <kbd>KEYBOARD</kbd>", "testing-keyboard"
        validateLinkFor '<a href="https://google.com">GOOGLE</a> AND APPLE.', "google-and-apple"

  describe "titleFor function", ->
    describe "basic features", ->
      validateTitleFor = (before, after) ->
        expect(titleFor(before)).toEqual(after)

      it "keep multibyte-chars in header", ->
        validateTitleFor '<a href="https://google.com">GOOGLE</a> AND APPLE', "GOOGLE AND APPLE"
        validateTitleFor "Do nothing for normal header", "Do nothing for normal header"
        validateTitleFor "[hello-1](http://www.google.com/)", "hello-1"
        validateTitleFor "[hello-2](https://www.google.com/)", "hello-2"
        validateTitleFor "[hello-2-1](other/file)", "hello-2-1"
        validateTitleFor "![hello-3](imgs/whowas.png)", ""
        validateTitleFor "hello-4 ![img](https://build.status/)", "hello-4"
