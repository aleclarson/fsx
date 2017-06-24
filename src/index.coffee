
path = require "path"
fs = require "fs"

exists = (filePath) ->
  try # The line below throws when nothing exists at the given path.
    result = fs.lstatSync filePath
  return result isnt undefined

isDir = (filePath) ->
  try # The line below throws when nothing exists at the given path.
    result = fs.statSync(filePath).isDirectory()
  return result is yes

isFile = (filePath) ->
  try # The line below throws when nothing exists at the given path.
    result = fs.statSync(filePath).isFile()
  return result is yes

isLink = (filePath) ->
  try # The line below throws when nothing exists at the given path.
    result = fs.lstatSync(filePath).isSymbolicLink()
  return result is yes

readDir = (dirPath) ->
  fs.readdirSync dirPath

readFile = (filePath, encoding) ->
  encoding = "utf8" if encoding is undefined
  fs.readFileSync filePath, encoding

readLink = (linkPath) ->
  fs.readlinkSync linkPath

writeDir = (dirPath) ->
  return if isDir dirPath
  writeDir path.dirname dirPath
  fs.mkdirSync dirPath

writeFile = (filePath, string) ->
  fs.writeFileSync filePath, string

writeLink = (linkPath, targetPath) ->
  fs.symlinkSync targetPath, linkPath

module.exports = {
  exists
  isDir
  isFile
  isLink
  readDir
  readFile
  readLink
  writeDir
  writeFile
  writeLink
}
