assert = require 'assert'

{ diff } = require '../lib/index'

describe 'diff', ->

  it "should return undefined for two identical numbers", ->
    assert.deepEqual undefined, diff(42, 42)

  it "should return undefined for two identical strings", ->
    assert.deepEqual undefined, diff("foo", "foo")

  it "should return { __old: <old value>, __new: <new value> } object for two different numbers", ->
    assert.deepEqual { __old: 42, __new: 10 }, diff(42, 10)

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
