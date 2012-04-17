{ SequenceMatcher } = require 'difflib'


extendedTypeOf = (obj) ->
  result = typeof obj
  if result is 'object' and obj.constructor is 'Array'
    'array'
  else
    result


emptyDiffStats = ->
  matchedKeys:   0
  unmatchedKeys: 0


objectDiff = (obj1, obj2, stats) ->
  result = {}

  keys1 = Object.keys(obj1)
  keys2 = Object.keys(obj2)

  for own key, value1 of obj1 when !(key of obj2)
    result["#{key}__deleted"] = value1
    stats.unmatchedKeys++ if stats

  for own key, value2 of obj2 when !(key of obj1)
    result["#{key}__added"] = value2
    stats.unmatchedKeys++ if stats

  for own key, value1 of obj1 when key of obj2
    value2 = obj2[key]
    if change = diff(value1, value2)
      result[key] = change
      stats.matchedKeys++ if stats
    else
      stats.matchedKeys++ if stats

  if Object.keys(result).length is 0
    return undefined

  return result


arrayDiff = (obj1, obj2, stats) ->
  opcodes = new SequenceMatcher(null, "a", "ab").getOpcodes()
  console.log opcodes
  return


diff = (obj1, obj2, stats) ->
  type1 = extendedTypeOf obj1
  type2 = extendedTypeOf obj2

  if type1 == type2
    switch type1
      when 'object'
        return objectDiff(obj1, obj2, stats)
      when 'array'
        return arrayDiff(obj1, obj2, stats)

  if obj1 != obj2
    { __old: obj1, __new: obj2 }
  else
    undefined


module.exports = { diff }
