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

  cmdDict: {
    'bind': (ctx, target, args) ->
      key = args[0]
      target.innerHTML = ctx[key]
  }

  # FIXME: This does not nest
  handle: ->
    argc = arguments.length
    if argc < 4
      throw Error 'Need command, at least one argument and target element', arguments
    argv = Array.prototype.slice.call arguments

    ctx = argv[0]
    target = argv[1]
    cmd = argv[2]
    args = argv[3..argc - 1]

    @cmdDict[cmd] ctx, target, args

  # What actually renders
  _render: (ctx) ->
    !@tmplStr and throw Error 'Load a template before rendering'
    !@tmpl and @parse()

    elems = @tmpl.getElementsByTagName('*')
    for elem in elems
      attrs = elem.attributes
      for attr in attrs
        if attr.name.search('data-') == 0
          @handle ctx, elem, attr.name.split('-')[1..]..., attr.value


