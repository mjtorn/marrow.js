## This is exported, set everything here
MRW = {}

escapeStr = (s) ->
  s.trim().replace('\n', '\\n', 'g')

unescapeStr = (s) ->
  s.trim().replace('\\n', '\n', 'g')

class Marrow
  ###
  # Constructor optionally takes anything jQuery can deal with as an element
  # If you don't pass anything, you must call one of the load methods
  ###
  constructor: (@tmplStr) ->
    @tmpl = null

    # Always assume \\n is an escaped newline, not valid user input or such
    if @tmplStr and @tmplStr.constructor == String
      us = unescapeStr @tmplStr
      # jQuery considers some newline-whitespace-sets to be empty textnodes o_O
      us = us.replace />\s*</gm, '><'
      @tmplStr = us.replace '\n', '', 'g'

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

  ###
  # Return a rendered string
  ###
  renderString: (ctx) ->
    @render ctx, @tmpl
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
      'attr':
        'call': (self, ctxStack, target, args) ->
          # Doing data-attr-class or data-attr-data-href
          attrName = args[0...-1].join '-'

          key = args[-1...][0]

          value = self._findInStack ctxStack, key

          target.attr(attrName, value)

          return true
        'sortOrder': 2

      'bind':
        'call':(self, ctxStack, target, args) ->
          key = args[0]
          target.html(self._findInStack ctxStack, key)

          return true
        'sortOrder': 2

      'include':
        'call': (self, ctxStack, target, args) ->
          templateName = args[0]

          ## FIXME: do not necessarily enforce global name "templates"
          target.html(templates.get templateName)

          return true
        'sortOrder': 1

      'foreach':
        'call': (self, ctxStack, target, args) ->
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
            childTarget = mrwTarget.tmpl.children(0).clone()
            rendered = mrwTarget.render ctxStack, $(childTarget)

            appendableElements.push rendered

          # Prevent stack from having old entries
          ctxStack.pop()

          # Replace the first empty one, then append
          i = 0
          for elem in appendableElements
            if i == 0
              target.html(elem)
            else
              target.append elem

            i++

          return true
        'sortOrder': 2

      'if':
        'call': (self, ctxStack, target, args) ->
          val = self._findInStack ctxStack, args[0]
          return val?
        'sortOrder': 2

      'renderif':
        'call': (self, ctxStack, target, args) ->
          val = self._findInStack ctxStack, args[0]
          if not val?
            target.remove()
        'sortOrder': 2

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

  cmdFromAttr: (attr) ->
    ### Get the command from given attribute
    ###

    attr.name.split('-')[1]

  sortCmds: (a1, a2) =>
    ### Sort two attributes as commands
    ###

    a1 = @cmdFromAttr a1
    c1 = @cmdDict[a1]
    not c1? and throw Error('Unknown command "' + a1 + '"')

    a2 = @cmdFromAttr a2
    c2 = @cmdDict[a2]
    not c2? and throw Error('Unknown command "' + a2 + '"')

    not c1.sortOrder and throw Error 'Unsortable object ' + c1
    not c2.sortOrder and throw Error 'Unsortable object ' + c2

    if c1.sortOrder == c2.sortOrder
      return 0
    else if c1.sortOrder > c2.sortOrder
      return 1

    return -1

  render: (ctx, target, depth=1) ->
    # We want a stack internally for foreach
    if ctx.constructor != Array
      ctx = [ctx]

    $target = $(target)

    for subTarget in $target
      $subTarget = $(subTarget)

      ## Extract all attrs and put them in a sane
      ## order before executing
      attrs = $subTarget.get(0).attributes
      attrs = Array.prototype.slice.call attrs
      attrs = (a for a in attrs when a.name.search('data-') == 0)
      attrs = attrs.sort @sortCmds

      for attr in attrs
        cont = @handle @, ctx, $subTarget, attr.name.split('-')[1..]..., attr.value
        if not cont
          break

      for elem in $subTarget.children()
        $elem = $(elem)
        @render ctx, $elem, depth+1

    target

  handle: ->
    argc = arguments.length
    if argc < 5
      throw Error 'Need command, at least one argument and target element', arguments
    argv = Array.prototype.slice.call arguments

    self = argv[0]
    ctx = argv[1]
    target = argv[2]
    cmd = argv[3]
    args = argv[4..-1]

    @cmdDict[cmd].call self, ctx, target, args

  _findInStack: (ctxStack, key) ->
    for i in [ctxStack.length-1..0] by -1
      ctx = ctxStack[i]
      value = ctx[key]
      return value if value

class Templates
  registry: {}
  add: (name, tmplStr) ->
    @registry[name] = tmplStr
  get: (name) ->
    @registry[name]

## Export section
MRW.Marrow = Marrow
MRW.Templates = Templates

MRW.escapeStr = escapeStr
MRW.unescapeStr = unescapeStr

if module?
  module.exports = MRW
else
  exports.MRW = MRW

