/*
 * DS202: Simplify dynamic range loops
 */
const { SequenceMatcher } = require('difflib')
const { extendedTypeOf } = require('./util')
const { colorize } = require('./colorize')

const isScalar = obj => (typeof obj !== 'object') || (obj === null)

const objectDiff = function (obj1, obj2, options = {}) {
  let result = {}
  let score = 0

  for (const [key, value] of Object.entries(obj1)) {
    if (!(key in obj2)) {
      result[`${key}__deleted`] = value
      score -= 30
    }
  }

  for (const [key, value] of Object.entries(obj2)) {
    if (!(key in obj1)) {
      result[`${key}__added`] = value
      score -= 30
    }
  }

  for (const [key, value1] of Object.entries(obj1)) {
    if (key in obj2) {
      score += 20
      const value2 = obj2[key]
      const [subscore, change] = diffWithScore(value1, value2, options)
      if (change) {
        result[key] = change
      } else {
        result[key] = value1
      }
      // console.log "key #{key} subscore=#{subscore} #{value}"
      score += Math.min(20, Math.max(-10, subscore / 5)) // BATMAN!
    }
  }

  if (Object.keys(result).length === 0) {
    [score, result] = [100 * Math.max(Object.keys(obj1).length, 0.5), undefined]
  } else {
    score = Math.max(0, score)
  }

  // console.log "objectDiff(#{JSON.stringify(obj1, null, 2)} <=> #{JSON.stringify(obj2, null, 2)}) == #{JSON.stringify([score, result])}"

  return [score, result]
}

const findMatchingObject = function (item, index, fuzzyOriginals) {
  // console.log "findMatchingObject: " + JSON.stringify({item, fuzzyOriginals}, null, 2)
  let bestMatch = null

  let matchIndex = 0
  for (const [key, candidate] of Object.entries(fuzzyOriginals)) {
    if (key !== '__next') {
      const indexDistance = Math.abs(matchIndex - index)
      if (extendedTypeOf(item) === extendedTypeOf(candidate)) {
        const score = diffScore(item, candidate)
        if (!bestMatch ||
          score > bestMatch.score ||
          (score === bestMatch.score && indexDistance < bestMatch.indexDistance)) {
          bestMatch = { score, key, indexDistance }
        }
      }
      matchIndex++
    }
  }

  // console.log "findMatchingObject result = " + JSON.stringify(bestMatch, null, 2)
  return bestMatch
}

const scalarize = function (array, originals, fuzzyOriginals) {
  const fuzzyMatches = []
  if (fuzzyOriginals) {
    // Find best fuzzy match for each object in the array
    const keyScores = {}
    for (let index = 0; index < array.length; index++) {
      const item = array[index]
      if (isScalar(item)) {
        continue
      }
      const bestMatch = findMatchingObject(item, index, fuzzyOriginals)
      if (!keyScores[bestMatch.key] || bestMatch.score > keyScores[bestMatch.key].score) {
        keyScores[bestMatch.key] = { score: bestMatch.score, index }
      }
    }
    for (const [key, match] of Object.entries(keyScores)) {
      fuzzyMatches[match.index] = key
    }
  }

  const result = []
  for (let index = 0; index < array.length; index++) {
    const item = array[index]
    if (isScalar(item)) {
      result.push(item)
    } else {
      const key = fuzzyMatches[index] || ('__$!SCALAR' + originals.__next++)
      originals[key] = item
      result.push(key)
    }
  }
  return result
}

const isScalarized = (item, originals) => (typeof item === 'string') && (item in originals)

const descalarize = function (item, originals) {
  if (isScalarized(item, originals)) {
    return originals[item]
  } else {
    return item
  }
}

const arrayDiff = function (obj1, obj2, options = {}) {
  const originals1 = { __next: 1 }
  const seq1 = scalarize(obj1, originals1)
  const originals2 = { __next: originals1.__next }
  const seq2 = scalarize(obj2, originals2, originals1)

  const opcodes = new SequenceMatcher(null, seq1, seq2).getOpcodes()

  // console.log "arrayDiff:\nobj1 = #{JSON.stringify(obj1, null, 2)}\nobj2 = #{JSON.stringify(obj2, null, 2)}\nseq1 = #{JSON.stringify(seq1, null, 2)}\nseq2 = #{JSON.stringify(seq2, null, 2)}\nopcodes = #{JSON.stringify(opcodes, null, 2)}"

  const result = []
  let score = 0

  let allEqual = true
  for (const [op, i1, i2, j1, j2] of opcodes) {
    let change, i, j
    let asc, end
    let asc1, end1
    let asc2, end2
    if (!((op === 'equal') || (options.keysOnly && (op === 'replace')))) {
      allEqual = false
    }

    switch (op) {
      case 'equal':
        for (i = i1, end = i2, asc = i1 <= end; asc ? i < end : i > end; asc ? i++ : i--) {
          const item = seq1[i]
          if (isScalarized(item, originals1)) {
            if (!isScalarized(item, originals2)) {
              throw new Error(`internal bug: isScalarized(item, originals1) != isScalarized(item, originals2) for item ${JSON.stringify(item)}`)
            }
            const item1 = descalarize(item, originals1)
            const item2 = descalarize(item, originals2)
            change = diff(item1, item2, options)
            if (change) {
              result.push(['~', change])
              allEqual = false
            } else {
              result.push([' ', item1])
            }
          } else {
            result.push([' ', item])
          }
          score += 10
        }
        break
      case 'delete':
        for (i = i1, end1 = i2, asc1 = i1 <= end1; asc1 ? i < end1 : i > end1; asc1 ? i++ : i--) {
          result.push(['-', descalarize(seq1[i], originals1)])
          score -= 5
        }
        break
      case 'insert':
        for (j = j1, end2 = j2, asc2 = j1 <= end2; asc2 ? j < end2 : j > end2; asc2 ? j++ : j--) {
          result.push(['+', descalarize(seq2[j], originals2)])
          score -= 5
        }
        break
      case 'replace':
        if (!options.keysOnly) {
          let asc3, end3
          let asc4, end4
          for (i = i1, end3 = i2, asc3 = i1 <= end3; asc3 ? i < end3 : i > end3; asc3 ? i++ : i--) {
            result.push(['-', descalarize(seq1[i], originals1)])
            score -= 5
          }
          for (j = j1, end4 = j2, asc4 = j1 <= end4; asc4 ? j < end4 : j > end4; asc4 ? j++ : j--) {
            result.push(['+', descalarize(seq2[j], originals2)])
            score -= 5
          }
        } else {
          let asc5, end5
          for (i = i1, end5 = i2, asc5 = i1 <= end5; asc5 ? i < end5 : i > end5; asc5 ? i++ : i--) {
            change = diff(descalarize(seq1[i], originals1), descalarize(seq2[(i - i1) + j1], originals2), options)
            if (change) {
              result.push(['~', change])
              allEqual = false
            } else {
              result.push([' '])
            }
          }
        }
        break
    }
  }

  if (allEqual || (opcodes.length === 0)) {
    // result = undefined
    score = 100
  } else {
    score = Math.max(0, score)
  }

  return [score, result]
}

const diffWithScore = function (obj1, obj2, options = {}) {
  const type1 = extendedTypeOf(obj1)
  const type2 = extendedTypeOf(obj2)

  if (type1 === type2) {
    switch (type1) {
      case 'object':
        return objectDiff(obj1, obj2, options)

      case 'array':
        return arrayDiff(obj1, obj2, options)
    }
  }

  if (!options.keysOnly) {
    if (obj1 !== obj2) {
      return [0, { __old: obj1, __new: obj2 }]
    } else {
      return [100, obj1]
    }
  } else {
    return [100, undefined]
  }
}

const diff = function (obj1, obj2, options = {}) {
  // eslint-disable-next-line no-unused-vars
  const [score, change] = diffWithScore(obj1, obj2, options)
  return change
}

const diffScore = function (obj1, obj2, options = {}) {
  // eslint-disable-next-line no-unused-vars
  const [score, change] = diffWithScore(obj1, obj2, options)
  return score
}

const diffString = (obj1, obj2, colorizeOptions, diffOptions = {}) => colorize(diff(obj1, obj2, diffOptions), colorizeOptions)

module.exports = { diff, diffString }
