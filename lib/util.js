const extendedTypeOf = function (obj) {
  const result = typeof obj
  if (obj == null) {
    return 'null'
  } else if (result === 'object' && obj.constructor === Array) {
    return 'array'
  } else {
    return result
  }
}

module.exports = { extendedTypeOf }
