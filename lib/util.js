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

const roundObj = function (data, precision) {
    var type = typeof data;
    if (type == "array") {
        return data.map(x => roundObj(x, precision));
    } else if (type == "object") {
        for( var key in data) {
            data[key] = roundObj( data[key], precision );
        }
        return data;
    } else if (type == "number" && Number.isFinite(data) && !Number.isInteger(data)) {
        return +(data).toFixed(precision);
    } else {
        return data;
    }
}

module.exports = { extendedTypeOf, roundObj }
