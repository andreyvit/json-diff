color = require 'cli-color'
JSONbig = require 'true-json-bigint'

{ extendedTypeOf } = require './util'

Theme =
  ' ': (s) -> s
  '+': color.green
  '-': color.red


subcolorizeToCallback = (key, diff, output, color, indent, options) ->
  prefix    = if key then "#{key}: " else ''
  subindent = indent + '  '
  switch extendedTypeOf(diff, options.bigNumberSupport)
    when 'object'
      if ('__old' of diff) and ('__new' of diff) and (Object.keys(diff).length is 2)
        subcolorizeToCallback(key, diff.__old, output, '-', indent, options)
        subcolorizeToCallback(key, diff.__new, output, '+', indent, options)
      else
        output color, "#{indent}#{prefix}{"
        for own subkey, subvalue of diff
          if m = subkey.match /^(.*)__deleted$/
            subcolorizeToCallback(m[1], subvalue, output, '-', subindent, options)
          else if m = subkey.match /^(.*)__added$/
            subcolorizeToCallback(m[1], subvalue, output, '+', subindent, options)
          else
            subcolorizeToCallback(subkey, subvalue, output, color, subindent, options)
        output color, "#{indent}}"

    when 'array'
      output color, "#{indent}#{prefix}["

      looksLikeDiff = yes
      for item in diff
        if (extendedTypeOf(item) isnt 'array') or !((item.length is 2) or ((item.length is 1) and (item[0] is ' '))) or !(typeof(item[0]) is 'string') or item[0].length != 1 or !(item[0] in [' ', '-', '+', '~'])
          looksLikeDiff = no

      if looksLikeDiff
        for [op, subvalue] in diff
          if op is ' ' && !subvalue?
            output(' ', subindent + '...')
          else
            unless op in [' ', '~', '+', '-']
              throw new Error("Unexpected op '#{op}' in #{JSONbig.stringify(diff, null, 2)}")
            op = ' ' if op is '~'
            subcolorizeToCallback('', subvalue, output, op, subindent, options)
      else
        for subvalue in diff
          subcolorizeToCallback('', subvalue, output, color, subindent, options)

      output color, "#{indent}]"

    else
      if diff == 0 or diff
        output(color, indent + prefix + JSONbig.stringify(diff))



colorizeToCallback = (diff, options, output) ->
  subcolorizeToCallback('', diff, output, ' ', '', options)


colorizeToArray = (diff, options = {}) ->
  output = []
  colorizeToCallback(diff, options, (color, line) -> output.push "#{color}#{line}")
  return output


colorize = (diff, options={}) ->
  output = []
  colorizeToCallback diff, options, (color, line) ->
    if options.color ? yes
      output.push (options.theme?[color] ? Theme[color])("#{color}#{line}") + "\n"
    else
      output.push "#{color}#{line}\n"
  return output.join('')


module.exports = { colorize, colorizeToArray, colorizeToCallback }
