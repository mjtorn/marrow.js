glob = require '../../env/node_modules/glob'
qqunit = require '../../env/node_modules/qqunit'

path = require 'path'

if !window.DOMParser
  jsdom = require '../../env/node_modules/jsdom'
  window.DOMParser = class FakeDOMParser
    constructor: ->

    parseFromString: (s, mimeType) ->
      jsdom.jsdom(s)

if !window.XMLSerializer
  xmlshim = require '../../env/node_modules/xmlshim'
  window.XMLSerializer = xmlshim.XMLSerializer

tests = glob.sync '*test*coffee'
suite = (path.resolve(test) for test in tests)

qqunit.Runner.run suite

