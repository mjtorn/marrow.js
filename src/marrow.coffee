fs = require 'fs'

window.Marrow = class Marrow
  ###
  # Constructor takes an fs path for now. Probably the html string later
  ###
  constructor: (@tmplPath) ->
    @domParse = new window.DOMParser()
    @tmpl = null
    !!@tmplPath and @loadFile @tmplPath

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

