marrow = require '../marrow'

QUnit.module 'Setup',
  setup: ->
    @emptyMrw = new window.Marrow()
    @mrw = new window.Marrow('templates/simple.html')

test 'Simple template, read', ->
  ok !@emptyMrw.tmplStr, 'Without constructor it whould be empty'
  @emptyMrw.loadFile 'templates/simple.html'
  notEqual @emptyMrw.tmplStr.length, 0, 'Loaded template should not be zero length'
  equal @emptyMrw.tmplStr[0], '<', 'Should start with tag sign'

test 'Simple template, parse', ->
  equal @mrw.tmplStr[0], '<', 'Should start with tag sign'
  @mrw.parse()
  notEqual @mrw.tmpl, 'Parsed marrow should have template object'

test 'Simple template, dump contents', ->
  # Just test it doesn't throw errors or anything
  @mrw.dumpDom()
  ok 1


