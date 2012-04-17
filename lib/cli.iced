fs = require 'fs'

{ diff } = require './index'


module.exports = (argv) ->
  options = require('dreamopt') [
    "Usage: json-diff [-v] first.json second.json"

    "Arguments:"
    "  first.json              Old file #var(file1) #required"
    "  second.json             New file #var(file2) #required"

    "General options:"
    "  -v, --verbose           Output progress info"
  ], argv

  process.stderr.write "Loading files...\n"  if options.verbose
  await
    fs.readFile options.file1, 'utf8', defer(err1, data1)
    fs.readFile options.file2, 'utf8', defer(err2, data2)

  throw err1 if err1
  throw err2 if err2

  process.stderr.write "Parsing old file...\n"  if options.verbose
  json1 = JSON.parse(data1)
  process.stderr.write "Parsing new file...\n"  if options.verbose
  json2 = JSON.parse(data2)

  process.stderr.write "Running diff...\n"  if options.verbose
  result = diff(json1, json2)

  process.stderr.write "Producing output...\n"  if options.verbose
  process.stdout.write JSON.stringify(result, null, 2)
