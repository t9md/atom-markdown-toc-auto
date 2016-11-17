settings = require '../lib/settings'
fs = require 'fs-plus'
temp = require 'temp'

path = require 'path'
{
  deserializeTocOptions
  serializeTocOptions
  generateToc
} = require '../lib/utils'

temp = require('temp').track()

describe "markdown-toc-auto", ->
  describe "settings", ->
    it "hold tocOption specific keys", ->
      expect(settings.tocOptionKeys).toEqual(['min', 'max', 'link', 'update'])

    it "return collection of settings for tocOptions", ->
      options = settings.getTocOptions()
      expect(Object.keys(options)).toEqual(settings.tocOptionKeys)
      for key, value of options
        configValue = atom.config.get("markdown-toc-auto.#{key}")
        expect(options[key]).toBe(configValue)

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

  # WIP
  xdescribe "??", ->
    [workDir, editor] = []

    beforeEach ->
      waitsForPromise ->
        atom.packages.activatePackage('language-gfm')

      waitsForPromise ->
        temp.mkdirSync('working')
        workDir = temp.path()
        filePathDst = path.join(workDir, "sample.md")
        fs.copySync(atom.project.resolvePath('./'), workDir)
        atom.workspace.open(filePathDst).then (e) ->
          editor = e

    # describe "generateToc", ->
    #   it "create path", ->
    #     console.log editor.getGrammar().scopeName
    #     console.log editor.getPath()
