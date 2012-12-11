fs = require 'fs'

window.Marrow = class Marrow
  constructor: (@tmplPath) ->
    @domParse = new window.DOMParser()
    @tmpl = null
    !!@tmplPath and @loadFile @tmplPath

  loadFile: (tmplPath, enc='utf-8') ->
    @tmplStr = fs.readFileSync tmplPath, enc

  parse: ->
    !@tmplStr and throw Error('Need template to parse')

    @tmpl = @domParse.parseFromString @tmplStr, 'application/xml'

