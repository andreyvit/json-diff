const color = require('cli-color')

const { extendedTypeOf } = require('./util')

const Theme = {
  ' ' (s) { return s },
  '+': color.green,
  '-': color.red
}

const subcolorizeToCallback = function (key, diff, output, color, indent) {
  let subvalue
  const prefix = key ? `${key}: ` : ''
  const subindent = indent + '  '

  switch (extendedTypeOf(diff)) {
    case 'object':
      if (('__old' in diff) && ('__new' in diff) && (Object.keys(diff).length === 2)) {
        subcolorizeToCallback(key, diff.__old, output, '-', indent)
        return subcolorizeToCallback(key, diff.__new, output, '+', indent)
      } else {
        output(color, `${indent}${prefix}{`)
        for (const subkey of Object.keys(diff)) {
          let m
          subvalue = diff[subkey]
          if ((m = subkey.match(/^(.*)__deleted$/))) {
            subcolorizeToCallback(m[1], subvalue, output, '-', subindent)
          } else if ((m = subkey.match(/^(.*)__added$/))) {
            subcolorizeToCallback(m[1], subvalue, output, '+', subindent)
          } else {
            subcolorizeToCallback(subkey, subvalue, output, color, subindent)
          }
        }
        return output(color, `${indent}}`)
      }

    case 'array': {
      output(color, `${indent}${prefix}[`)

      let looksLikeDiff = true
      for (const item of diff) {
        if ((extendedTypeOf(item) !== 'array') || !((item.length === 2) || ((item.length === 1) && (item[0] === ' '))) || !(typeof (item[0]) === 'string') || (item[0].length !== 1) || !([' ', '-', '+', '~'].includes(item[0]))) {
          looksLikeDiff = false
        }
      }

      if (looksLikeDiff) {
        let op
        for ([op, subvalue] of diff) {
          if (op === ' ' && subvalue == null) {
            output(' ', subindent + '...')
          } else {
            if (![' ', '~', '+', '-'].includes(op)) {
              throw new Error(`Unexpected op '${op}' in ${JSON.stringify(diff, null, 2)}`)
            }
            if (op === '~') { op = ' ' }
            subcolorizeToCallback('', subvalue, output, op, subindent)
          }
        }
      } else {
        for (subvalue of diff) {
          subcolorizeToCallback('', subvalue, output, color, subindent)
        }
      }

      return output(color, `${indent}]`)
    }

    default:
      if (diff === 0 || diff === null || diff === false || diff === '' || diff) {
        return output(color, indent + prefix + JSON.stringify(diff))
      }
  }
}

const colorizeToCallback = (diff, output) => subcolorizeToCallback('', diff, output, ' ', '')

const colorizeToArray = function (diff) {
  const output = []
  colorizeToCallback(diff, (color, line) => output.push(`${color}${line}`))
  return output
}

const colorize = function (diff, options = {}) {
  const output = []
  colorizeToCallback(diff, function (color, line) {
    if (options.color != null ? options.color : true) {
      return output.push(((options.theme != null ? options.theme[color] : undefined) != null ? (options.theme != null ? options.theme[color] : undefined) : Theme[color])(`${color}${line}`) + '\n')
    } else {
      return output.push(`${color}${line}\n`)
    }
  })
  return output.join('')
}

module.exports = { colorize, colorizeToArray, colorizeToCallback }
