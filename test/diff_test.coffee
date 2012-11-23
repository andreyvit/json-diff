assert = require 'assert'

{ diff } = require "../#{process.env.JSLIB or 'lib'}/index"

describe 'diff', ->

  describe 'with simple scalar values', ->

    it "should return undefined for two identical numbers", ->
      assert.deepEqual undefined, diff(42, 42)

    it "should return undefined for two identical strings", ->
      assert.deepEqual undefined, diff("foo", "foo")

    it "should return { __old: <old value>, __new: <new value> } object for two different numbers", ->
      assert.deepEqual { __old: 42, __new: 10 }, diff(42, 10)

  describe 'with objects', ->

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

    it "should return [..., ['-', <removed item>], ...] for two arrays when the second array is missing a value", ->
      assert.deepEqual [[' '], ['-', { foo: 20 }], [' ']], diff([{ foo: 10 }, { foo: 20 }, { foo: 30 }], [{ foo: 10 }, { foo: 30 }])

    it "should return [..., ['+', <added item>], ...] for two arrays when the second array has an extra value", ->
      assert.deepEqual [[' '], ['+', { foo: 20 }], [' ']], diff([{ foo: 10 }, { foo: 30 }], [{ foo: 10 }, { foo: 20 }, { foo: 30 }])

    it "should return [..., ['~', <diff>], ...] for two arrays when an item has been modified (note: involves a crazy heuristic)", ->
      assert.deepEqual [[' '], ['~', { foo: { __old: 20, __new: 21 } }], [' ']], diff([{ foo: 10, bar: { bbbar: 10, bbboz: 11 } }, { foo: 20, bar: { bbbar: 50, bbboz: 25 } }, { foo: 30, bar: { bbbar: 92, bbboz: 34 } }], [{ foo: 10, bar: { bbbar: 10, bbboz: 11 } }, { foo: 21, bar: { bbbar: 50, bbboz: 25 } }, { foo: 30, bar: { bbbar: 92, bbboz: 34 } }])
