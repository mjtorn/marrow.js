window.Marrow = class Marrow
  ###
  # Constructor takes an fs path for now. Probably the html string later
  ###
  constructor: (@tmplStr) ->
    @domParser = new window.DOMParser()
    @xmlSerializer = new window.XMLSerializer()
    @tmpl = null

  ###
  # Load a given file from the fs
  ###
  loadFile: (tmplPath, enc='utf-8') ->
    fs = require 'fs'

    @tmplStr = fs.readFileSync tmplPath, enc

  ###
  # Or str
  ###
  loadStr: (@tmplStr) ->

  ###
  # Or dom
  ###
  loadDom: (domElement) ->
      @tmplStr = @xmlSerializer.serializeToString domElement

  ###
  # Create a DOM object of the internal template string
  ###
  parse: ->
    !@tmplStr and throw Error('Need template to parse')

    @tmpl = @domParser.parseFromString @tmplStr, 'application/xml'
    if @tmpl.childNodes.length > 1
      raise Error 'Do not know yet how to deal with multi-element templates'

  ###
  # Debugging
  ###
  dumpDom: (node, cb, depth) ->
    !@tmpl and @parse()

    node ?= elems = @tmpl.getElementsByTagName('*')[0]
    depth ?= 0
    cb ?= console?.log depth, ' :: ', node.tagName

    node = node.firstChild
    while node
      depth++
      @dumpDom node, cb, depth
      node = node.nextSibling

  ###
  # Return a rendered string
  ###
  renderString: (ctx) ->
    @_render ctx
    if @tmpl?
      return @serialize()

  ###
  # Render to target element
  ###
  render: (ctx, target) ->
    if typeof target == 'string'
      target = document.getElementById target
      if not target
        throw Error 'Need a destination element or id string'

      @loadDom target

    @_render ctx

    if @tmpl?
      target.parentNode.replaceChild(@tmpl.childNodes[0], target)

  ###
  # Test wrapper for setting innerHTML
  ###
  setHtml: (newHtml, tmplStr) ->
    !@tmplStr and @loadStr tmplStr
    @parse()

    @tmpl.innerHTML = newHtml
    @tmpl

  ###
  # Convenience to get string output
  ###
  serialize: ->
    !@tmpl and throw Error 'load and parse something first'

    return @xmlSerializer.serializeToString @tmpl

  ###
  # JFDI
  ###

  cmdDict: new ->
    {
      'bind': (self, ctxStack, target, args) ->
        key = args[0]
        target.innerHTML = self._findInStack ctxStack, key
    }

  # FIXME: This does not nest
  handle: ->
    argc = arguments.length
    if argc < 5
      throw Error 'Need command, at least one argument and target element', arguments
    argv = Array.prototype.slice.call arguments

    self = argv[0]
    ctx = argv[1]
    target = argv[2]
    cmd = argv[3]
    args = argv[4..argc - 1]

    @cmdDict[cmd] self, ctx, target, args

  # What actually renders
  _render: (ctx) ->
    !@tmplStr and throw Error 'Load a template before rendering'
    !@tmpl and @parse()

    # We want a stack internally for foreach
    if ctx.constructor != Array
      ctx = [ctx]

    elems = @tmpl.getElementsByTagName('*')
    for elem in elems
      attrs = elem.attributes
      for attr in attrs
        if attr.name.search('data-') == 0
          @handle @, ctx, elem, attr.name.split('-')[1..]..., attr.value

  _findInStack: (ctxStack, key) ->
    for ctx in ctxStack
      value = ctx[key]
      return value if value

