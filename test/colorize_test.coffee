assert = require 'assert'

{ colorize, colorizeToArray } = require "../#{process.env.JSLIB or 'lib'}/colorize"

describe 'colorizeToArray', ->

  it "should return ' <value>' for a scalar value", ->
    assert.deepEqual [' 42'], colorizeToArray(42)

  it "should return ' <value>' for 'null' value", ->
    assert.deepEqual [' null'], colorizeToArray(null)

  it "should return ' <value>' for 'false' value", ->
    assert.deepEqual [' false'], colorizeToArray(false)

  it "should return '-<old value>', '+<new value>' for a scalar diff", ->
    assert.deepEqual ['-42', '+10'], colorizeToArray({ __old: 42, __new: 10 })

  it "should return '-<old value>', '+<new value>' for 'null' and 'false' diff", ->
    assert.deepEqual ['-false', '+null'], colorizeToArray({ __old: false, __new: null })

  it "should return '-<removed key>: <removed value>' for an object diff with a removed key", ->
    assert.deepEqual [' {', '-  foo: 42', ' }'], colorizeToArray({ foo__deleted: 42 })

  it "should return '+<added key>: <added value>' for an object diff with an added key", ->
    assert.deepEqual [' {', '+  foo: 42', ' }'], colorizeToArray({ foo__added: 42 })

  it "should return '+<added key>: <added value>' for an object diff with an added key with 'null' value", ->
    assert.deepEqual [' {', '+  foo: null', ' }'], colorizeToArray({ foo__added: null })

  it "should return '+<added key>: <added value>' for an object diff with an added key with 'false' value", ->
    assert.deepEqual [' {', '+  foo: false', ' }'], colorizeToArray({ foo__added: false })

  it "should return '+<added key>: <added stringified value>' for an object diff with an added key and a non-scalar value", ->
    assert.deepEqual [' {', '+  foo: {', '+    bar: 42', '+  }', ' }'], colorizeToArray({ foo__added: { bar: 42 } })

  it "should return ' <modified key>: <colorized diff>' for an object diff with a modified key", ->
    assert.deepEqual [' {', '-  foo: 42', '+  foo: 10', ' }'], colorizeToArray({ foo: { __old: 42, __new: 10 } })

  it "should return '+<inserted item>' for an array diff", ->
    assert.deepEqual [' [', '   10', '+  20', '   30', ' ]'], colorizeToArray([[' ', 10], ['+', 20], [' ', 30]])

  it "should return '-<deleted item>' for an array diff", ->
    assert.deepEqual [' [', '   10', '-  20', '   30', ' ]'], colorizeToArray([[' ', 10], ['-', 20], [' ', 30]])

  it "should handle an array diff with subobject diff", ->
    input = [ [" "], ["~", {"foo__added": 42}], [" "] ]
    expected = [" [", "   ...", "   {", "+    foo: 42", "   }", "   ...", " ]"]
    console.log "output:\n%s", colorizeToArray(input).join("\n")
    assert.deepEqual colorizeToArray(input), expected



describe 'colorize', ->

  it "should return a string with ANSI escapes", ->
    assert.equal colorize({ foo: { __old: 42, __new: 10 } }), " {\n\u001b[31m-  foo: 42\u001b[39m\n\u001b[32m+  foo: 10\u001b[39m\n }\n"

  it "should return a string without ANSI escapes on { color: false }", ->
    assert.equal colorize({ foo: { __old: 42, __new: 10 } }, color: no), " {\n-  foo: 42\n+  foo: 10\n }\n"

