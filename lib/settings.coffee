SPEC_KEYS = ['min', 'max', 'style', 'link', 'update']
class Settings
  constructor: (@scope, @config) ->
    # Inject order props to display orderd in setting-view
    for name, i in Object.keys(@config)
      @config[name].order = i

  has: (param) ->
    param of atom.config.get(@scope)

  delete: (param) ->
    @set(param, undefined)

  get: (param) ->
    atom.config.get "#{@scope}.#{param}"

  set: (param, value) ->
    atom.config.set "#{@scope}.#{param}", value

  getSpecOptions: ->
    params = {}
    for key in SPEC_KEYS
      params[key] = @get(key)
    params

  specKeys: ->
    SPEC_KEYS

module.exports = new Settings 'markdown-toc-auto',
  min:
    type: 'integer'
    minimum: 1
    default: 1
    description: "Minimum header level used on initial insert"
  max:
    type: 'integer'
    minimum: 1
    default: 1
    description: "Maximum header level used on initial insert"
  update:
    type: 'boolean'
    default: true
  link:
    type: 'boolean'
    default: true
  style:
    type: 'string'
    default: 'ul'
    enum: ['ul', 'ol']
