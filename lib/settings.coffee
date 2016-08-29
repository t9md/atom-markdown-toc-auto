class Settings
  tocOptionKeys: ['min', 'max', 'link', 'update']

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

  getTocOptions: ->
    options = {}
    for key in @tocOptionKeys
      options[key] = @get(key)
    options

module.exports = new Settings 'markdown-toc-auto',
  min:
    type: 'integer'
    minimum: 1
    default: 1
    description: "Minimum header level on create toc"
  max:
    type: 'integer'
    minimum: 1
    default: 3
    description: "Maximum header level on create toc"
  update:
    type: 'boolean'
    default: true
    description: "Update option on create"
  link:
    type: 'boolean'
    default: true
    description: "Link option on create"
