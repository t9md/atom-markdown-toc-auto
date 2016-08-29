describe "markdown-toc-auto", ->
  {deserializeTocOptions, serializeTocOptions} = require '../lib/utils'
  describe "serialize/desirializeTocOptions", ->
    it "serialize", ->
      tocOptions = {
        min: 1, max: 1, link: true, update: true
      }
      serialized = 'min:1 max:1 style:ul link:true update:true'
      expect(serializeTocOptions(tocOptions)).toBe(serialized)

    it "deserialize", ->
      text = 'min:1 max:1 link:true update:true'
      expect(deserializeTocOptions(text)).toEqual {
        min: 1, max: 1, link: true, update: true
      }
