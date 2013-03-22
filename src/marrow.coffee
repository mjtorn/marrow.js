class Marrow
  ###
  # Constructor optionally takes anything jQuery can deal with as an element
  # If you don't pass anything, you must call one of the load methods
  ###
  constructor: (@tmplStr) ->
    @tmpl = null

    @tmplStr and @parse()

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
    @tmplStr = domElement.html()
    @tmpl = domElement

  ###
  # Create a DOM object of the internal template string
  ###
  parse: ->
    !@tmplStr and throw Error('Need template to parse')

    # Always interpret the given input as jQuery
    @tmpl = $(@tmplStr)
    # if @tmpl.children().length == 0
    #   console.log 'Template has no children. Please give the parent', @tmpl
    #   throw Error 'Template has no children. Please give the parent'
    ###
    else if @tmpl.children().length != 1
      console.log 'Do not know how to deal with multi-element templates', @tmpl
      throw Error 'Do not know how to deal with multi-element templates'
    ###
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
  # Test wrapper for setting innerHTML
  ###
  setHtml: (newHtml, tmplStr) ->
    !@tmplStr and @loadStr tmplStr
    @parse()

    @tmpl.html newHtml
    @tmpl

  ###
  # Convenience to get string output
  ###
  serialize: ->
    !@tmpl and throw Error 'load and parse something first'

    return @tmpl.wrap('<div></div>').parent().html()

  ###
  # JFDI
  ###

  cmdDict: new ->
    {
      'attr': (self, ctxStack, target, args) ->
        attrName = args[0]
        value = self._findInStack ctxStack, attrName
        target.attr(attrName, value)
        target

      'bind': (self, ctxStack, target, args) ->
        key = args[0]
        target.html self._findInStack ctxStack, key
        target

      'foreach': (self, ctxStack, target, args) ->
        listKey = args[0]
        key = args[1]

        list = self._findInStack ctxStack, listKey

        # Push our local entry into the context
        ctxStack.push {}
        appendableElements = []
        for entry in list
          # Update our stack element
          ctxStack[ctxStack.length - 1][key] = entry

          # Wrap target into Marrow() to make rendering possible
          mrwTarget = new Marrow(target)

          # XXX: This is why we use jQuery, this didn't work without it
          rendered = mrwTarget.render ctxStack, $(mrwTarget.tmpl.children(0).clone())

          appendableElements.push rendered

        # Prevent stack from having old entries
        ctxStack.pop()

        for elem in appendableElements
          target.prepend elem

        target
    }

  walk: (ctx, target, depth=1) ->
    console.log depth, target

    attrs = target.get(0).attributes
    for attr in attrs
      if attr.name.search('data-') == 0
        console.log 'Found attr', attr

    for elem in target.children()
      $elem = $(elem)
      @walk ctx, $elem, depth+1

  render: (ctx, target, depth=1) ->
    # We want a stack internally for foreach
    if ctx.constructor != Array
      ctx = [ctx]

    $elem = $(target)
    attrs = target.get(0).attributes
    for attr in attrs
      if attr.name.search('data-') == 0
        @handle @, ctx, $elem, attr.name.split('-')[1..]..., attr.value

    for elem in target.children()
      $elem = $(elem)
      @render ctx, $elem, depth+1

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

  _findInStack: (ctxStack, key) ->
    for i in [ctxStack.length-1..0] by -1
      ctx = ctxStack[i]
      value = ctx[key]
      return value if value

if module?
  module.exports = Marrow
else
  exports.Marrow = Marrow

