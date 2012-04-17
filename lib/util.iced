
extendedTypeOf = (obj) ->
  result = typeof obj
  if result is 'object' and obj.constructor is Array
    'array'
  else
    result

module.exports = { extendedTypeOf }
