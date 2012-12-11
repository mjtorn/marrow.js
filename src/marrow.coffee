fs = require 'fs'

window.Marrow = class Marrow
  constructor: (@tmplStr) ->
    @domParse = new window.DOMParser()
    @tmpl = null

  loadFile: (tmplPath, enc='utf-8') ->
    @tmplStr = fs.readFileSync tmplPath, enc

  parse: ->
    !@tmplStr and throw Error('Need template to parse')

    @tmpl = @domParse.parseFromString @tmplStr, 'application/xml'

