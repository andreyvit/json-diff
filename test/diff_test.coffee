BigNumber = require 'bignumber.js'
fs     = require 'fs'
Path   = require 'path'
assert = require 'assert'

{ diff, diffString } = require "../#{process.env.JSLIB or 'lib'}/index"

describe 'diff', ->

  describe 'with simple scalar values', ->

    it "should return undefined for two identical numbers", ->
      assert.deepEqual undefined, diff(42, 42)

    it "should return undefined for two identical strings", ->
      assert.deepEqual undefined, diff("foo", "foo")

    it "should return { __old: <old value>, __new: <new value> } object for two different numbers", ->
      assert.deepEqual { __old: 42, __new: 10 }, diff(42, 10)

  describe 'with objects', ->

    it "should return undefined for two empty objects", ->
      assert.deepEqual undefined, diff({ }, { })

    it "should return undefined for two objects with identical contents", ->
      assert.deepEqual undefined, diff({ foo: 42, bar: 10 }, { foo: 42, bar: 10 })

    it "should return undefined for two object hierarchies with identical contents", ->
      assert.deepEqual undefined, diff({ foo: 42, bar: { bbbar: 10, bbboz: 11 } }, { foo: 42, bar: { bbbar: 10, bbboz: 11 } })

    it "should return { <key>__deleted: <old value> } when the second object is missing a key", ->
      assert.deepEqual { foo__deleted: 42 }, diff({ foo: 42, bar: 10 }, { bar: 10 })

    it "should return { <key>__added: <new value> } when the first object is missing a key", ->
      assert.deepEqual { foo__added: 42 }, diff({ bar: 10 }, { foo: 42, bar: 10 })

    it "should return { <key>: { __old: <old value>, __new: <new value> } } for two objects with diffent scalar values for a key", ->
      assert.deepEqual { foo: { __old: 42, __new: 10 } }, diff({ foo: 42 }, { foo: 10 })

    it "should return { <key>: <diff> } with a recursive diff for two objects with diffent values for a key", ->
      assert.deepEqual { bar: { bbboz__deleted: 11, bbbar: { __old: 10, __new: 12 } } }, diff({ foo: 42, bar: { bbbar: 10, bbboz: 11 }}, { foo: 42, bar: { bbbar: 12 }})

  describe 'with arrays of scalars', ->

    it "should return undefined for two arrays with identical contents", ->
      assert.deepEqual undefined, diff([10, 20, 30], [10, 20, 30])

    it "should return [..., ['-', <removed item>], ...] for two arrays when the second array is missing a value", ->
      assert.deepEqual [[' ', 10], ['-', 20], [' ', 30]], diff([10, 20, 30], [10, 30])

    it "should return [..., ['+', <added item>], ...] for two arrays when the second one has an extra value", ->
      assert.deepEqual [[' ', 10], ['+', 20], [' ', 30]], diff([10, 30], [10, 20, 30])

    it "should return [..., ['+', <added item>]] for two arrays when the second one has an extra value at the end (edge case test)", ->
      assert.deepEqual [[' ', 10], [' ', 20], ['+', 30]], diff([10, 20], [10, 20, 30])

  describe 'with arrays of objects', ->

    it "should return undefined for two arrays with identical contents", ->
      assert.deepEqual undefined, diff([{ foo: 10 }, { foo: 20 }, { foo: 30 }], [{ foo: 10 }, { foo: 20 }, { foo: 30 }])

    it "should return undefined for two arrays with identical, empty object contents", ->
      assert.deepEqual undefined, diff([{ }], [{ }])

    it "should return undefined for two arrays with identical, empty array contents", ->
      assert.deepEqual undefined, diff([[]], [[]])

    it "should return undefined for two arrays with identical array contents including 'null'", ->
      assert.deepEqual undefined, diff([1, null, null], [1, null, null])

    it "should return undefined for two arrays with identical, repeated contents", ->
      assert.deepEqual undefined, diff([{ a: 1, b: 2 }, { a: 1, b: 2 }], [{ a: 1, b: 2 }, { a: 1, b: 2 }])

    it "should return [..., ['-', <removed item>], ...] for two arrays when the second array is missing a value", ->
      assert.deepEqual [[' '], ['-', { foo: 20 }], [' ']], diff([{ foo: 10 }, { foo: 20 }, { foo: 30 }], [{ foo: 10 }, { foo: 30 }])

    it "should return [..., ['+', <added item>], ...] for two arrays when the second array has an extra value", ->
      assert.deepEqual [[' '], ['+', { foo: 20 }], [' ']], diff([{ foo: 10 }, { foo: 30 }], [{ foo: 10 }, { foo: 20 }, { foo: 30 }])

    it "should return [..., ['+', <added item>], ...] for two arrays when the second array has a new but nearly identical object added", ->
      assert.deepEqual [[' '],[ '+', { name: 'Foo', a: 3, b: 1, c: 1 }], [' ']], diff([{ "name": "Foo", "a": 3, "b": 1 },{ foo: 10 }], [{ "name": "Foo", "a": 3, "b": 1 },{ "name": "Foo", "a": 3, "b": 1, "c": 1 },{ foo: 10 }])

    it "should return [..., ['~', <diff>], ...] for two arrays when an item has been modified (note: involves a crazy heuristic)", ->
      assert.deepEqual [[' '], ['~', { foo: { __old: 20, __new: 21 } }], [' ']], diff([{ foo: 10, bar: { bbbar: 10, bbboz: 11 } }, { foo: 20, bar: { bbbar: 50, bbboz: 25 } }, { foo: 30, bar: { bbbar: 92, bbboz: 34 } }], [{ foo: 10, bar: { bbbar: 10, bbboz: 11 } }, { foo: 21, bar: { bbbar: 50, bbboz: 25 } }, { foo: 30, bar: { bbbar: 92, bbboz: 34 } }])


describe 'diff({keysOnly: true})', ->

  describe 'with simple scalar values', ->

    it "should return undefined for two identical numbers", ->
      assert.deepEqual undefined, diff(42, 42, {keysOnly: true})

    it "should return undefined for two identical strings", ->
      assert.deepEqual undefined, diff("foo", "foo", {keysOnly: true})

    it "should return undefined object for two different numbers", ->
      assert.deepEqual undefined, diff(42, 10, {keysOnly: true})

  describe 'with objects', ->

    it "should return undefined for two empty objects", ->
      assert.deepEqual undefined, diff({ }, { }, {keysOnly: true})

    it "should return undefined for two objects with identical contents", ->
      assert.deepEqual undefined, diff({ foo: 42, bar: 10 }, { foo: 42, bar: 10 }, {keysOnly: true})

    it "should return undefined for two object hierarchies with identical contents", ->
      assert.deepEqual undefined, diff({ foo: 42, bar: { bbbar: 10, bbboz: 11 } }, { foo: 42, bar: { bbbar: 10, bbboz: 11 } }, {keysOnly: true})

    it "should return { <key>__deleted: <old value> } when the second object is missing a key", ->
      assert.deepEqual { foo__deleted: 42 }, diff({ foo: 42, bar: 10 }, { bar: 10 }, {keysOnly: true})

    it "should return { <key>__added: <new value> } when the first object is missing a key", ->
      assert.deepEqual { foo__added: 42 }, diff({ bar: 10 }, { foo: 42, bar: 10 }, {keysOnly: true})

    it "should return undefined for two objects with diffent scalar values for a key", ->
      assert.deepEqual undefined, diff({ foo: 42 }, { foo: 10 }, {keysOnly: true})

    it "should return undefined with a recursive diff for two objects with diffent values for a key", ->
      assert.deepEqual undefined, diff({ foo: 42, bar: { bbbar: 10 }}, { foo: 42, bar: { bbbar: 12 }}, {keysOnly: true})

    it "should return { <key>: <diff> } with a recursive diff when second object is missing a key and two objects with diffent values for a key", ->
      assert.deepEqual { bar: { bbboz__deleted: 11 } }, diff({ foo: 42, bar: { bbbar: 10, bbboz: 11 }}, { foo: 42, bar: { bbbar: 12 }}, {keysOnly: true})

  describe 'with arrays of scalars', ->

    it "should return undefined for two arrays with identical contents", ->
      assert.deepEqual undefined, diff([10, 20, 30], [10, 20, 30], {keysOnly: true})

    it "should return undefined for two arrays with when an item has been modified", ->
      assert.deepEqual undefined, diff([10, 20, 30], [10, 42, 30], {keysOnly: true})

    it "should return [..., ['-', <removed item>], ...] for two arrays when the second array is missing a value", ->
      assert.deepEqual [[' ', 10], ['-', 20], [' ', 30]], diff([10, 20, 30], [10, 30], {keysOnly: true})

    it "should return [..., ['+', <added item>], ...] for two arrays when the second one has an extra value", ->
      assert.deepEqual [[' ', 10], ['+', 20], [' ', 30]], diff([10, 30], [10, 20, 30], {keysOnly: true})

    it "should return [..., ['+', <added item>]] for two arrays when the second one has an extra value at the end (edge case test)", ->
      assert.deepEqual [[' ', 10], [' ', 20], ['+', 30]], diff([10, 20], [10, 20, 30], {keysOnly: true})

  describe 'with arrays of objects', ->

    it "should return undefined for two arrays with identical contents", ->
      assert.deepEqual undefined, diff([{ foo: 10 }, { foo: 20 }, { foo: 30 }], [{ foo: 10 }, { foo: 20 }, { foo: 30 }], {keysOnly: true})

    it "should return undefined for two arrays with identical, empty object contents", ->
      assert.deepEqual undefined, diff([{ }], [{ }], {keysOnly: true})

    it "should return undefined for two arrays with identical, empty array contents", ->
      assert.deepEqual undefined, diff([[]], [[]], {keysOnly: true})

    it "should return undefined for two arrays with identical, repeated contents", ->
      assert.deepEqual undefined, diff([{ a: 1, b: 2 }, { a: 1, b: 2 }], [{ a: 1, b: 2 }, { a: 1, b: 2 }], {keysOnly: true})

    it "should return [..., ['-', <removed item>], ...] for two arrays when the second array is missing a value", ->
      assert.deepEqual [[' '], ['-', { foo: 20 }], [' ']], diff([{ foo: 10 }, { foo: 20 }, { foo: 30 }], [{ foo: 10 }, { foo: 30 }], {keysOnly: true})

    it "should return [..., ['+', <added item>], ...] for two arrays when the second array has an extra value", ->
      assert.deepEqual [[' '], ['+', { foo: 20 }], [' ']], diff([{ foo: 10 }, { foo: 30 }], [{ foo: 10 }, { foo: 20 }, { foo: 30 }], {keysOnly: true})

    it "should return [..., ['~', <diff>], ...] for two arrays when an item has been modified (note: involves a crazy heuristic)", ->
      assert.deepEqual undefined, diff([{ foo: 10, bar: { bbbar: 10, bbboz: 11 } }, { foo: 20, bar: { bbbar: 50, bbboz: 25 } }, { foo: 30, bar: { bbbar: 92, bbboz: 34 } }], [{ foo: 10, bar: { bbbar: 10, bbboz: 11 } }, { foo: 21, bar: { bbbar: 50, bbboz: 25 } }, { foo: 30, bar: { bbbar: 92, bbboz: 34 } }], {keysOnly: true})


describe 'diffString', ->

  readExampleFile = (file) -> fs.readFileSync(Path.join(__dirname, '../example', file), 'utf8')
  a = JSON.parse(readExampleFile('a.json'))
  b = JSON.parse(readExampleFile('b.json'))

  it "should produce the expected result for the example JSON files", ->
    assert.equal diffString(a, b, color: no), readExampleFile('result.jsdiff')

  it "should produce the expected colored result for the example JSON files", ->
    assert.equal diffString(a, b), readExampleFile('result-colored.jsdiff')

  it "return an empty string when no diff found", ->
    assert.equal diffString(a, a), ''


describe 'Big Number Support', ->

  it "should handle a diff with different Big Number values", ->
    assert.deepEqual { __old: BigNumber('3e+5000'), __new: BigNumber('98765432100123456789') }, diff(BigNumber('3e+5000'), BigNumber('98765432100123456789'), bigNumberSupport: true)

  it "should handle a diff with equal Big Number values", ->
    assert.deepEqual undefined, diff(BigNumber('3e+5000'), BigNumber('3e+5000'), bigNumberSupport: true)

  it "should handle a diff for an array with Big Number values", ->
    assert.deepEqual [['~', {__old: BigNumber('3e+5000'), __new: BigNumber('98765432100123456789')}], ['~', {__old: BigNumber('3e+6000'), __new: BigNumber('12345678901234567890')}]], diff([BigNumber('3e+5000'), BigNumber('3e+6000')], [BigNumber('98765432100123456789'), BigNumber('12345678901234567890')], bigNumberSupport: true)

  it "should handle a diff when old value is an ordinary number and new value contains a Big Number value", ->
    assert.deepEqual { __old: 1, __new: BigNumber('98765432100123456789') }, diff(1, BigNumber('98765432100123456789'), bigNumberSupport: true)

  it "should handle a diff when old value contains a Big Number value and new value is an ordinary number", ->
    assert.deepEqual { __old: BigNumber('3e+5000'), __new: 2}, diff(BigNumber('3e+5000'), 2, bigNumberSupport: true)

