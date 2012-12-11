marrow = require '../marrow'

QUnit.module 'Setup',
  setup: ->
    @emptyMrw = new window.Marrow()

test 'Simple template, read', ->
  ok !@emptyMrw.tmplStr, 'Without constructor it whould be empty'
  @emptyMrw.loadFile 'templates/simple.html'
  notEqual @emptyMrw.tmplStr.length, 0, 'Loaded template should not be zero length'
  equal @emptyMrw.tmplStr[0], '<', 'Should start with tag sign'

test 'Simple template, parse', ->
  @emptyMrw.loadFile 'templates/simple.html'
  @emptyMrw.parse
  notEqual @emptyMrw.tmpl, 'Parsed marrow should have template object'

