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

  console.log "Loading files..."  if options.verbose
  await
    fs.readFile options.file1, 'utf8', defer(err1, data1)
    fs.readFile options.file2, 'utf8', defer(err2, data2)

  throw err1 if err1
  throw err2 if err2

  console.log "Parsing old file..."  if options.verbose
  json1 = JSON.parse(data1)
  console.log "Parsing new file..."  if options.verbose
  json2 = JSON.parse(data2)

  console.log "Running diff..."  if options.verbose
  result = diff(json1, json2)

  process.stdout.write JSON.stringify(result)
