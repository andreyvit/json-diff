{ SequenceMatcher } = require 'difflib'
{ extendedTypeOf } = require './util'
{ colorize } = require './colorize'

isScalar = (obj) -> (typeof obj isnt 'object')


objectDiff = (obj1, obj2) ->
  result = {}
  score = 0

  keys1 = Object.keys(obj1)
  keys2 = Object.keys(obj2)

  for own key, value1 of obj1 when !(key of obj2)
    result["#{key}__deleted"] = value1
    score -= 30

  for own key, value2 of obj2 when !(key of obj1)
    result["#{key}__added"] = value2
    score -= 30

  for own key, value1 of obj1 when key of obj2
    score += 20
    value2 = obj2[key]
    [subscore, change] = diffWithScore(value1, value2)
    if change
      result[key] = change
      # console.log "key #{key} subscore=#{subscore}"
    score += Math.min(20, Math.max(-10, subscore / 5))  # BATMAN!

  if Object.keys(result).length is 0
    [score, result] = [100 * Math.max(Object.keys(obj1).length, 0.5), undefined]
  else
    score = Math.max(0, score)

  # console.log "objectDiff(#{JSON.stringify(obj1, null, 2)} <=> #{JSON.stringify(obj2, null, 2)}) == #{JSON.stringify([score, result])}"

  return [score, result]


findMatchingObject = (item, index, fuzzyOriginals, used) ->
  # console.log "findMatchingObject: " + JSON.stringify({item, fuzzyOriginals}, null, 2)
  bestMatch = null

  matchIndex = 0
  for own key, candidate of fuzzyOriginals when key isnt '__next' and !used[key]?
    indexDistance = Math.abs(matchIndex - index)
    if extendedTypeOf(item) == extendedTypeOf(candidate)
      score = diffScore(item, candidate)
      if !bestMatch || score > bestMatch.score || (score == bestMatch.score && indexDistance < bestMatch.indexDistance)
        bestMatch = { score, key, indexDistance }
    matchIndex++

  # console.log "findMatchingObject result = " + JSON.stringify(bestMatch, null, 2)
  bestMatch


scalarize = (array, originals, fuzzyOriginals) ->
  for item, index in array
    if isScalar item
      item
    else if fuzzyOriginals && (bestMatch = findMatchingObject(item, index, fuzzyOriginals, originals)) && bestMatch.score > 40
      originals[bestMatch.key] = item
      bestMatch.key
    else
      proxy = "__$!SCALAR" + originals.__next++
      originals[proxy] = item
      proxy

isScalarized = (item, originals) ->
  (typeof item is 'string') && (item of originals)

descalarize = (item, originals) ->
  if isScalarized(item, originals)
    originals[item]
  else
    item


arrayDiff = (obj1, obj2, stats) ->
  originals1 = { __next: 1 }
  seq1 = scalarize(obj1, originals1)
  originals2 = { __next: originals1.__next }
  seq2 = scalarize(obj2, originals2, originals1)

  opcodes = new SequenceMatcher(null, seq1, seq2).getOpcodes()

  # console.log "arrayDiff:\nobj1 = #{JSON.stringify(obj1, null, 2)}\nobj2 = #{JSON.stringify(obj2, null, 2)}\nseq1 = #{JSON.stringify(seq1, null, 2)}\nseq2 = #{JSON.stringify(seq2, null, 2)}\nopcodes = #{JSON.stringify(opcodes, null, 2)}"

  result = []
  score = 0

  allEqual = yes
  for [op, i1, i2, j1, j2] in opcodes
    if op isnt 'equal'
      allEqual = no

    switch op
      when 'equal'
        for i in [i1 ... i2]
          item = seq1[i]
          if isScalarized(item, originals1)
            unless isScalarized(item, originals2)
              throw new AssertionError("internal bug: isScalarized(item, originals1) != isScalarized(item, originals2) for item #{JSON.stringify(item)}")
            item1 = descalarize(item, originals1)
            item2 = descalarize(item, originals2)
            change = diff(item1, item2)
            if change
              result.push ['~', change]
              allEqual = no
            else
              result.push [' ']
          else
            result.push [' ', item]
          score += 10
      when 'delete'
        for i in [i1 ... i2]
          result.push ['-', descalarize(seq1[i], originals1)]
          score -= 5
      when 'insert'
        for j in [j1 ... j2]
          result.push ['+', descalarize(seq2[j], originals2)]
          score -= 5
      when 'replace'
        for i in [i1 ... i2]
          result.push ['-', descalarize(seq1[i], originals1)]
          score -= 5
        for j in [j1 ... j2]
          result.push ['+', descalarize(seq2[j], originals2)]
          score -= 5

  if allEqual or (opcodes.length is 0)
    result = undefined
    score  = 100
  else
    score  = Math.max(0, score)

  return [score, result]


diffWithScore = (obj1, obj2) ->
  type1 = extendedTypeOf obj1
  type2 = extendedTypeOf obj2

  if type1 == type2
    switch type1
      when 'object'
        return objectDiff(obj1, obj2)
      when 'array'
        return arrayDiff(obj1, obj2)

  if obj1 != obj2
    [0, { __old: obj1, __new: obj2 }]
  else
    [100, undefined]

diff = (obj1, obj2) ->
  [score, change] = diffWithScore(obj1, obj2)
  return change

diffScore = (obj1, obj2) ->
  [score, change] = diffWithScore(obj1, obj2)
  return score

diffString = (obj1, obj2, options) ->
  return colorize(diff(obj1, obj2), options)



module.exports = { diff, diffString }
