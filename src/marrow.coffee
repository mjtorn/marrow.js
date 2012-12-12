fs = require 'fs'

window.Marrow = class Marrow
  ###
  # Constructor takes an fs path for now. Probably the html string later
  ###
  constructor: (@tmplStr) ->
    @domParse = new window.DOMParser()
    @tmpl = null

  ###
  ## Load a given file from the fs
  ###
  loadFile: (tmplPath, enc='utf-8') ->
    @tmplStr = fs.readFileSync tmplPath, enc

  ###
  # Create a DOM object of the internal template string
  ###
  parse: ->
    !@tmplStr and throw Error('Need template to parse')

    @tmpl = @domParse.parseFromString @tmplStr, 'application/xml'

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

