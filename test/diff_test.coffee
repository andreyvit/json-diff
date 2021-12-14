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

    it "should return { <key>: { __old: <old value>, __new: <new value> } } for two objects with different scalar values for a key", ->
      assert.deepEqual { foo: { __old: 42, __new: 10 } }, diff({ foo: 42 }, { foo: 10 })

    it "should return { <key>: <diff> } with a recursive diff for two objects with different values for a key", ->
      assert.deepEqual { bar: { bbboz__deleted: 11, bbbar: { __old: 10, __new: 12 } } }, diff({ foo: 42, bar: { bbbar: 10, bbboz: 11 }}, { foo: 42, bar: { bbbar: 12 }})

  describe 'with arrays of scalars', ->

    it "should return undefined for two arrays with identical contents", ->
      assert.deepEqual undefined, diff([10, 20, 30], [10, 20, 30])

    it "should return [..., ['-', <removed item>], ...] for two arrays when the second array is missing a value", ->
      assert.deepEqual [[' '], ['-', 20], [' ']], diff([10, 20, 30], [10, 30])

    it "should return [..., ['+', <added item>], ...] for two arrays when the second one has an extra value", ->
      assert.deepEqual [[' '], ['+', 20], [' ']], diff([10, 30], [10, 20, 30])

    it "should return [..., ['+', <added item>]] for two arrays when the second one has an extra value at the end (edge case test)", ->
      assert.deepEqual [[' '], [' '], ['+', 30]], diff([10, 20], [10, 20, 30])

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

    it "should return [['+', <added item>], ..., ['+', <added item>]] for two arrays containing objects of 3 or more properties when the second array has extra values (fixes issue #57)", ->
      assert.deepEqual([ [ "+", { "key1": "b", "key2": "1", "key3": "m" } ], [ " " ], [ "+", { "key1": "c", "key2": "1", "key3": "dm" } ]], 
                        diff([ { "key1": "a", "key2": "12", "key3": "cm" } ], [ { "key1": "b", "key2": "1", "key3": "m" }, { "key1": "a", "key2": "12", "key3": "cm" }, { "key1": "c", "key2": "1", "key3": "dm" } ])
      )

    it "should return [..., ['+', <added item>], ...] for two arrays when the second array has a new but nearly identical object added", ->
      assert.deepEqual [[' '],[ '+', { name: 'Foo', a: 3, b: 1, c: 1 }], [' ']], diff([{ "name": "Foo", "a": 3, "b": 1 },{ foo: 10 }], [{ "name": "Foo", "a": 3, "b": 1 },{ "name": "Foo", "a": 3, "b": 1, "c": 1 },{ foo: 10 }])

    it "should return [..., ['~', <diff>], ...] for two arrays when an item has been modified", ->
      assert.deepEqual( [[' '], ['~', { foo: { __old: 20, __new: 21 } }], [' ']], 
                          diff([{ foo: 10, bar: { bbbar: 10, bbboz: 11 } }, 
                                { foo: 20, bar: { bbbar: 50, bbboz: 25 } }, 
                                { foo: 30, bar: { bbbar: 92, bbboz: 34 } }], 
                               [{ foo: 10, bar: { bbbar: 10, bbboz: 11 } }, 
                                { foo: 21, bar: { bbbar: 50, bbboz: 25 } }, 
                                { foo: 30, bar: { bbbar: 92, bbboz: 34 } }])
      )

describe 'diff({full: true})', ->

  describe 'with simple scalar values', ->

    it "should return the number for two identical numbers", ->
      assert.deepEqual 42, diff(42, 42, {full: true})

    it "should return the string for two identical strings", ->
      assert.deepEqual "foo", diff("foo", "foo", {full: true})

    it "should return { __old: <old value>, __new: <new value> } object for two different numbers", ->
      assert.deepEqual { __new: 10, __old: 42 }, diff(42, 10, {full: true})

  describe 'with objects', ->

    it "should return an empty object for two empty objects", ->
      assert.deepEqual {}, diff({ }, { }, {full: true})

    it "should return the object for two objects with identical contents", ->
      assert.deepEqual { foo: 42, bar: 10 }, diff({ foo: 42, bar: 10 }, { foo: 42, bar: 10 }, {full: true})

    it "should return the object for two object hierarchies with identical contents", ->
      assert.deepEqual { foo: 42, bar: { bbbar: 10, bbboz: 11 } }, diff({ foo: 42, bar: { bbbar: 10, bbboz: 11 } }, { foo: 42, bar: { bbbar: 10, bbboz: 11 } }, {full: true})

    it "should return { <key>__deleted: <old value>, <remaining properties>} when the second object is missing a key", ->
      assert.deepEqual { foo__deleted: 42, bar: 10 }, diff({ foo: 42, bar: 10 }, { bar: 10 }, {full: true})

    it "should return { <key>__added: <new value>, <remaining properties> } when the first object is missing a key", ->
      assert.deepEqual { foo__added: 42, bar: 10 }, diff({ bar: 10 }, { foo: 42, bar: 10 }, {full: true})

    it "should return { <key>: { __old: <old value>, __new: <new value> } } for two objects with different scalar values for a key", ->
      assert.deepEqual { foo: { __old: 42, __new: 10 } }, diff({ foo: 42 }, { foo: 10 }, {full: true})
      
    it "should return { <key>: <diff>, <equal properties> } with a recursive diff for two objects with different values for a key", ->
      assert.deepEqual { foo: 42, bar: { bbbar: { __old: 10, __new: 12 } } }, diff({ foo: 42, bar: { bbbar: 10 }}, { foo: 42, bar: { bbbar: 12 }}, {full: true})

    it "should return { <key>: <diff>, <equal properties> } with a recursive diff for two objects with different values for a key", ->
      assert.deepEqual { foo: 42, bar: { bbboz__deleted: 11, bbbar: { __old: 10, __new: 12 } } }, diff({ foo: 42, bar: { bbbar: 10, bbboz: 11 }}, { foo: 42, bar: { bbbar: 12 }}, {full: true})

  describe 'with arrays of scalars', ->

    it "should return an array showing no changes for any element for two arrays with identical contents", ->
      assert.deepEqual [ 10, 20, 30 ], diff([10, 20, 30], [10, 20, 30], {full: true})

    it "should return [[' ', <unchanged item>], ['-', <removed item>], [' ', <unchanged item>]] for two arrays when the second array is missing a value", ->
      assert.deepEqual [ [ " ", 10 ], [ "-", 20 ], [ "+", 42 ], [ " ", 30 ] ], diff([10, 20, 30], [10, 42, 30], {full: true})

    it "should return [' ', <unchanged item>], ['+', <added item>], [' ', <unchanged item>]] for two arrays when the second one has an extra value", ->
      assert.deepEqual [[' ', 10], ['+', 20], [' ', 30]], diff([10, 30], [10, 20, 30], {full: true})

    it "should return [' ', <unchanged item>s], ['+', <added item>]] for two arrays when the second one has an extra value at the end (edge case test)", ->
      assert.deepEqual [[' ', 10], [' ', 20], ['+', 30]], diff([10, 20], [10, 20, 30], {full: true})

  describe 'with arrays of objects', ->

    it "should return an array of unchanged elements for two arrays with identical contents", ->
      assert.deepEqual [{ foo: 10 }, { foo: 20 }, { foo: 30 }], diff([{ foo: 10 }, { foo: 20 }, { foo: 30 }], [{ foo: 10 }, { foo: 20 }, { foo: 30 }], {full: true})

    it "should return an array with an unchanged element for two arrays with identical, empty object contents", ->
      assert.deepEqual [ {} ], diff([{ }], [{ }], {full: true})

    it "should return an array with an unchanged element for two arrays with identical, empty array contents", ->
      assert.deepEqual [ [] ], diff([[]], [[]], {full: true})

    it "should return an array of unchanged elements for two arrays with identical array contents including 'null'", ->
      assert.deepEqual [ 1, null, null ], diff([1, null, null], [1, null, null], {full: true})

    it "should return an array of unchanged elements for two arrays with identical, repeated contents", ->
      assert.deepEqual [ { "a": 1, "b": 2 }, { "a": 1, "b": 2 } ], diff([{ a: 1, b: 2 }, { a: 1, b: 2 }], [{ a: 1, b: 2 }, { a: 1, b: 2 }], {full: true})

    it "should return [[' ', <unchanged item>], ['-', <removed item>], [' ', <unchanged item>]] for two arrays when the second array is missing a value", ->
      assert.deepEqual [ [ " ", { "foo": 10 } ], [ "-", { "foo": 20 } ], [ " ", { "foo": 30 } ] ], diff([{ foo: 10 }, { foo: 20 }, { foo: 30 }], [{ foo: 10 }, { foo: 30 }], {full: true})

    it "should return [[' ', <unchanged item>], ['+', <added item>], [' ', <unchanged item>]] for two arrays when the second array has an extra value", ->
      assert.deepEqual [ [ " ", { "foo": 10 } ], [ "+", { "foo": 20 } ], [ " ", { "foo": 30 } ] ], diff([{ foo: 10 }, { foo: 30 }], [{ foo: 10 }, { foo: 20 }, { foo: 30 }], {full: true})

    it "should return [[' ', <unchanged item>], ['+', <added item>], [' ', <unchanged item>]] for two arrays when the second array has a new but nearly identical object added", ->
      assert.deepEqual [ [ " ", { "name": "Foo", "a": 3, "b": 1 } ], [ "+", { "name": "Foo", "a": 3, "b": 1, "c": 1 } ], [ " ", { "foo": 10 } ] ], diff([{ "name": "Foo", "a": 3, "b": 1 },{ "foo": 10 }], [{ "name": "Foo", "a": 3, "b": 1 },{ "name": "Foo", "a": 3, "b": 1, "c": 1 },{ "foo": 10 }], {full: true})

    it "should return [[' ', <unchanged item>], ['~', <diff>], [' ', <unchanged item>]] for two arrays when an item has been modified", ->
      assert.deepEqual( [ [ " ", { "foo": 10, "bar": { "bbbar": 10, "bbboz": 11 } } ], 
                          [ "~", { "foo": { "__old": 20, "__new": 21 }, "bar": { "bbbar": 50, "bbboz": 25 } } ], 
                          [ " ", { "foo": 30, "bar": { "bbbar": 92, "bbboz": 34 } } ] ], 
                          diff([{ foo: 10, bar: { bbbar: 10, bbboz: 11 } }, 
                                { foo: 20, bar: { bbbar: 50, bbboz: 25 } }, 
                                { foo: 30, bar: { bbbar: 92, bbboz: 34 } }], 
                               [{ foo: 10, bar: { bbbar: 10, bbboz: 11 } }, 
                                { foo: 21, bar: { bbbar: 50, bbboz: 25 } }, 
                                { foo: 30, bar: { bbbar: 92, bbboz: 34 } }], {full: true})
      )

   
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

    it "should return undefined for two objects with different scalar values for a key", ->
      assert.deepEqual undefined, diff({ foo: 42 }, { foo: 10 }, {keysOnly: true})

    it "should return undefined with a recursive diff for two objects with different values for a key", ->
      assert.deepEqual undefined, diff({ foo: 42, bar: { bbbar: 10 }}, { foo: 42, bar: { bbbar: 12 }}, {keysOnly: true})

    it "should return { <key>: <diff> } with a recursive diff when second object is missing a key and two objects with different values for a key", ->
      assert.deepEqual { bar: { bbboz__deleted: 11 } }, diff({ foo: 42, bar: { bbbar: 10, bbboz: 11 }}, { foo: 42, bar: { bbbar: 12 }}, {keysOnly: true})

  describe 'with arrays of scalars', ->

    it "should return undefined for two arrays with identical contents", ->
      assert.deepEqual undefined, diff([10, 20, 30], [10, 20, 30], {keysOnly: true})

    it "should return undefined for two arrays with when an item has been modified", ->
      assert.deepEqual undefined, diff([10, 20, 30], [10, 42, 30], {keysOnly: true})

    it "should return [..., ['-', <removed item>], ...] for two arrays when the second array is missing a value", ->
      assert.deepEqual [[' '], ['-', 20], [' ']], diff([10, 20, 30], [10, 30], {keysOnly: true})

    it "should return [..., ['+', <added item>], ...] for two arrays when the second one has an extra value", ->
      assert.deepEqual [[' '], ['+', 20], [' ']], diff([10, 30], [10, 20, 30], {keysOnly: true})

    it "should return [..., ['+', <added item>]] for two arrays when the second one has an extra value at the end (edge case test)", ->
      assert.deepEqual [[' '], [' '], ['+', 30]], diff([10, 20], [10, 20, 30], {keysOnly: true})

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
      assert.deepEqual [[' '], ['-', { bar: 20 }], [' ']], diff([{ foo: 10 }, { bar: 20 }, { bletch: 30 }], [{ foo: 10 }, { bletch: 30 }], {keysOnly: true})

    it "should return [..., ['+', <added item>], ...] for two arrays when the second array has an extra value", ->
      assert.deepEqual [[' '], ['+', { bar: 20 }], [' ']], diff([{ foo: 10 }, { bletch: 30 }], [{ foo: 10 }, { bar: 20 }, { bletch: 30 }], {keysOnly: true})

    it "should return [..., ['~', <diff>], ...] for two arrays when an item has been modified", ->
      assert.deepEqual undefined, diff([{ foo: 10, bar: { bbbar: 10, bbboz: 11 } }, { foo: 20, bar: { bbbar: 50, bbboz: 25 } }, { foo: 30, bar: { bbbar: 92, bbboz: 34 } }], [{ foo: 10, bar: { bbbar: 10, bbboz: 11 } }, { foo: 21, bar: { bbbar: 50, bbboz: 25 } }, { foo: 30, bar: { bbbar: 92, bbboz: 34 } }], {keysOnly: true})


describe 'diffString', ->

  readExampleFile = (file) -> fs.readFileSync(Path.join(__dirname, '../example', file), 'utf8')
  a = JSON.parse(readExampleFile('a.json'))
  b = JSON.parse(readExampleFile('b.json'))

  it "should produce the expected result for the example JSON files", ->
    assert.equal diffString(a, b, {color: false, full: true}), readExampleFile('full-result.jsdiff')

  it "should produce the expected colored result for the example JSON files", ->
    assert.equal diffString(a, b, {color: true, full: true}), readExampleFile('full-result-colored.jsdiff')

  it "return an empty string when no diff found", ->
    assert.equal diffString(a, a), ''
