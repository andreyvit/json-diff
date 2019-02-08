BigNumber = require 'bignumber.js'

extendedTypeOf = (obj, bigNumberSupport = false) ->
  result = typeof obj
  if !obj?
    'null'
  else if result is 'object' and obj.constructor is Array
    'array'
  else if bigNumberSupport and BigNumber.isBigNumber(obj)
    'number'
  else
    result

module.exports = { extendedTypeOf }
