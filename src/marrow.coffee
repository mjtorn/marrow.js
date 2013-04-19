## These need to go in their own file at some point
defaultCmds = {
  'attr':
    'call': (self, ctxStack, target, args) ->
      # Doing data-attr-class or data-attr-data-href
      attrName = args[0...-1].join '-'

      not attrName and throw Error 'Missing attribute name'

      key = args[-1...][0]

      value = self._findInStack ctxStack, key

      target.attr(attrName, value)

      return true
    'sortOrder': 2

  'bind':
    'call':(self, ctxStack, target, args, filters) ->
      key = args[0]

      value = self._findInStack ctxStack, key

      filterArgClean = (filterArg) =>
        if filterArg[0] == "'" and filterArg[filterArg.length - 1] == "'"
          filterArg = filterArg[1...-1]
          return filterArg
        return self._findInStack ctxStack, filterArg

      filters? and for filter in filters
        filterArgs = null
        if filter.indexOf(':') > -1
          split = filter.split ':'
          filter = split[0]
          filterArgs = split[1..]

          filterArgs = (filterArgClean fArg for fArg in filterArgs)

        func = Filters.get filter
        not func and throw Error 'Unknown filter ' + filter
        value = func value, filterArgs

      target.html(value)

      return true
    'sortOrder': 2

  'include':
    'call': (self, ctxStack, target, args) ->
      templateName = args[0]

      target.html(MRW.Templates.get templateName)

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
      for entry in list or []
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

  'foreachme':
    'call': (self, ctxStack, target, args) ->
      listKey = args[0]
      key = args[1]

      list = self._findInStack ctxStack, listKey

      appendableElements = []
      for entry in list or []
        ctxStack.push {}
        ctxStack[ctxStack.length - 1][key] = entry

        # prevent recursion into recursion into recursion
        cloneTarget = $(target).clone()
        cloneTarget.removeAttr 'data-foreachme-' + listKey, null

        mrwTarget = new Marrow(cloneTarget)

        rendered = mrwTarget.render ctxStack, cloneTarget

        appendableElements.push rendered

        ctxStack.pop()

      i = 0
      for elem in appendableElements
        if i == 0
          target.replaceWith elem
          target = elem
        else
          target.after(elem)
          target = target.next()

        i++

    'sortOrder': 2

  'if':
    'call': (self, ctxStack, target, args) ->
      val = self._findInStack ctxStack, args[0]
      return val?
    'sortOrder': 2

  'renderif':
    'call': (self, ctxStack, target, args) ->
      key = args[0]
      val = self._findInStack ctxStack, key
      if not val?
        target.remove()
        return false
      true
    'sortOrder': 2
  }

defaultFilters = {
  'upper': (s) -> s.toUpperCase()
  'lower': (s) -> s.toLowerCase()
  'reverse': (s) ->
    l = s.split ''
    l.reverse()
    l.join ''
  'append': (s, args) ->
    for arg in args
      s += arg
    s
}

## This is exported, set everything here
MRW = {}

escapeStr = (s) ->
  s.trim().replace('\n', '\\n', 'g')

unescapeStr = (s) ->
  s.trim().replace('\\n', '\n', 'g')

setupCommands = ->
  for cmdName, struct of defaultCmds
    Commands.add cmdName, struct['call'], struct['sortOrder']

setupFilters = ->
  for filterName, func of defaultFilters
    Filters.add filterName, func

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
    c1 = MRW.Commands.get a1
    not c1? and throw Error('Unknown command "' + a1 + '"')

    a2 = @cmdFromAttr a2
    c2 = MRW.Commands.get a2
    not c2? and throw Error('Unknown command "' + a2 + '"')

    not c1.sortOrder and throw Error 'Unsortable object ' + c1
    not c2.sortOrder and throw Error 'Unsortable object ' + c2

    if c1.sortOrder == c2.sortOrder
      return 0
    else if c1.sortOrder > c2.sortOrder
      return 1

    return -1

  render: (ctx, target, depth=1) ->
    #
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

      attrs = (a for a in attrs when a.name.search('data-') == 0 and MRW.Commands.get @cmdFromAttr a)
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

    filters = null
    if args[args.length-1].indexOf('|') > -1
      split = args[args.length-1].split '|'
      args[args.length-1] = split[0]
      filters = split[1..]

    MRW.Commands.get(cmd).call self, ctx, target, args, filters

  _findInStack: (ctxStack, key) ->
    keyAttrs = null
    if key.indexOf('.') > -1
      split = key.split '.'
      key = split[0]
      keyAttrs = split[1..]

    # value = self._findInStack ctxStack, key
    for i in [ctxStack.length-1..0] by -1
      ctx = ctxStack[i]
      value = ctx[key]
      if value?
        break

    ## The context stack magic may lead to value
    ## being undefined somehow, but not going anywhere
    ## if it is null seems to work nonetheless.
    if keyAttrs and value?
      for keyAttr in keyAttrs
        value = value[keyAttr]

    return value if value?

Templates =
  registry: {}
  add: (name, tmplStr) ->
    @registry[name] = tmplStr
  get: (name) ->
    @registry[name]

Commands =
  registry: {}
  add: (name, func, sortOrder) ->
    @registry[name] = {
      'call': func
      'sortOrder': sortOrder
    }

  get: (name, func) ->
    @registry[name]

Filters =
  registry: {}
  add: (name, func) ->
    @registry[name] = func
  get: (name) ->
    @registry[name]

## Defaults setup
setupCommands()
setupFilters()

## Export section
MRW.Marrow = Marrow
MRW.Commands = Commands
MRW.Templates = Templates
MRW.Filters = Filters

MRW.escapeStr = escapeStr
MRW.unescapeStr = unescapeStr

if module?
  module.exports = MRW
else
  exports.MRW = MRW

