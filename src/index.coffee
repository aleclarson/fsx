
path = require "path"
fs = require "fs"

# Constants used for determining file type.
{S_IFMT, S_IFREG, S_IFDIR, S_IFLNK} = fs.constants

exports.ReadStream = fs.ReadStream
exports.WriteStream = fs.WriteStream

exports.open = fs.openSync
exports.append = fs.appendFileSync
exports.close = fs.closeSync

exports.stat = fs.statSync
exports.lstat = fs.lstatSync

exports.touch = (file) ->

  if getMode(file) isnt undefined
    time = Date.now() / 1000
    fs.utimesSync file, time, time
    return

  fs.writeFileSync file, ''
  return

exports.read = (file, opts) ->
  if typeof file is "number"
    if opts then opts.fd = file
    else opts = fd: file
    file = null
  new fs.ReadStream file, opts

exports.write = (file, opts) ->
  if typeof file is "number"
    if opts then opts.fd = file
    else opts = fd: file
    file = null
  new fs.WriteStream file, opts

exports.exists = (filePath) ->
  getMode(filePath) isnt undefined

exports.isDir = (filePath) ->
  getMode(filePath) is S_IFDIR

exports.isFile = (filePath) ->
  getMode(filePath) is S_IFREG

exports.isLink = (filePath) ->
  getMode(filePath) is S_IFLNK

exports.readDir = (dirPath) ->
  unless mode = getMode dirPath
    uhoh "Cannot use `readDir` on a non-existent path: '#{dirPath}'", "DIR_NOT_FOUND"
  if mode isnt S_IFDIR
    uhoh "Expected a directory: '#{dirPath}'", "DIR_NOT_FOUND"
  return fs.readdirSync dirPath

exports.readFile = (filePath, encoding) ->
  unless mode = getMode filePath
    uhoh "Cannot use `readFile` on a non-existent path: '#{filePath}'", "FILE_NOT_FOUND"
  if mode is S_IFDIR
    uhoh "Cannot use `readFile` on a directory: '#{filePath}'", "FILE_NOT_FOUND"
  encoding = "utf8" if encoding is undefined
  return fs.readFileSync filePath, encoding

exports.readLink = (linkPath) ->
  unless mode = getMode linkPath
    uhoh "Cannot use `readLink` on a non-existent path: '#{linkPath}'", "LINK_NOT_FOUND"
  if mode is S_IFLNK
    return fs.readlinkSync linkPath
  return linkPath

exports.readLinks = (linkPath, maxDepth = 100) ->
  depth = 0
  filePath = linkPath
  while (mode = getMode filePath) and (mode is S_IFLNK)
    prevPath = filePath
    filePath = fs.readlinkSync filePath
    if filePath[0] is "."
      filePath = path.resolve path.dirname(prevPath), filePath
    if ++depth > maxDepth
      uhoh "Failed to resolve link: '#{linkPath}'", "MAX_DEPTH"
  return filePath

exports.writeDir = writeDir = (dirPath) ->
  unless mode = getMode dirPath
    writeDir path.dirname dirPath
    return fs.mkdirSync dirPath
  if mode isnt S_IFDIR
    uhoh "Cannot use `writeDir` on an existing path: '#{dirPath}'", "PATH_EXISTS"

exports.writeFile = (filePath, string) ->
  if getMode(filePath) isnt S_IFDIR
    return fs.writeFileSync filePath, string
  uhoh "Cannot use `writeFile` on a directory: '#{filePath}'", "PATH_EXISTS"

exports.writeLink = (linkPath, targetPath) ->
  unless getMode linkPath
    return fs.symlinkSync targetPath, linkPath
  uhoh "Cannot use `writeLink` on an existing path: '#{linkPath}'", "PATH_EXISTS"

exports.removeDir = (dirPath, recursive = true) ->
  unless mode = getMode dirPath
    uhoh "Cannot use `removeDir` on a non-existent path: '#{dirPath}'", "DIR_NOT_FOUND"
  if mode isnt S_IFDIR
    uhoh "Expected a directory: '#{dirPath}'", "DIR_NOT_FOUND"
  if ".." is path.relative(process.cwd(), dirPath).slice 0, 2
    uhoh "Cannot use `removeDir` on paths outside of the current directory: '#{dirPath}'", "ABOVE_CWD"
  if recursive
    return removeTree dirPath
  return fs.rmdirSync dirPath

exports.removeFile = (filePath) ->
  unless mode = getMode filePath
    uhoh "Cannot use `removeFile` on a non-existent path: '#{filePath}'", "FILE_NOT_FOUND"
  if mode is S_IFDIR
    uhoh "Cannot use `removeFile` on a directory: '#{filePath}'", "FILE_NOT_FOUND"
  return fs.unlinkSync filePath

exports.rename = (srcPath, destPath) ->
  unless mode = getMode srcPath
    uhoh "Cannot `rename` non-existent path: '#{srcPath}'", "SRC_NOT_FOUND"
  if mode is S_IFDIR
    if getMode destPath
      uhoh "Cannot `rename` directory to pre-existing path: '#{destPath}'", "DEST_EXISTS"
  else if getMode(destPath) is S_IFDIR
    uhoh "Cannot overwrite directory path: '#{destPath}'", "DEST_EXISTS"
  writeDir path.dirname destPath
  return fs.renameSync srcPath, destPath

exports.copy = (srcPath, destPath) ->

  unless mode = getMode srcPath
    uhoh "Cannot `copy` non-existent path: '#{srcPath}'", "SRC_NOT_FOUND"

  if mode is S_IFDIR
    return copyTree srcPath, destPath

  destMode = getMode destPath

  if destMode is S_IFDIR
    destPath = path.join destPath, path.basename srcPath
    destMode = getMode destPath

  if destMode
    if destMode is S_IFDIR
      uhoh "Cannot overwrite directory path: '#{destPath}'", "DEST_EXISTS"
    fs.unlinkSync destPath

  # Create missing parent directories.
  writeDir path.dirname destPath

  if mode is S_IFLNK
  then copyLink srcPath, destPath
  else fs.writeFileSync destPath, fs.readFileSync srcPath

exports.watch = fs.watch
exports.watchFile = fs.watchFile

#
# Helpers
#

uhoh = (message, code) ->
  e = Error message
  e.code = code if code
  Error.captureStackTrace e, uhoh
  throw e

getMode = (filePath) ->
  try mode = fs.lstatSync(filePath).mode & S_IFMT
  return mode

copyLink = (srcPath, destPath) ->
  filePath = fs.readlinkSync srcPath
  unless path.isAbsolute filePath
    filePath = path.resolve path.dirname(srcPath), filePath
    filePath = path.relative path.dirname(destPath), filePath
  return fs.symlinkSync filePath, destPath

# Overwrite the `destPath` with contents of the `srcPath`.
copyFile = (srcPath, destPath) ->
  mode = getMode srcPath

  if mode is S_IFDIR
    return copyTree srcPath, destPath

  if destMode = getMode destPath
    if destMode is S_IFDIR
    then removeTree destPath
    else fs.unlinkSync destPath

  # Create missing parent directories.
  writeDir path.dirname destPath

  if mode is S_IFLNK
  then copyLink srcPath, destPath
  else fs.writeFileSync destPath, fs.readFileSync srcPath

# Recursive tree copies.
copyTree = (srcPath, destPath) ->
  destMode = getMode destPath

  # Remove the file under our new path, if needed.
  if destMode and destMode isnt S_IFDIR
    fs.unlinkSync destPath

  # Create the directory, if needed.
  if destMode isnt S_IFDIR
    writeDir path.dirname destPath
    fs.mkdirSync destPath

  fs.readdirSync(srcPath).forEach (file) ->
    copyFile path.join(srcPath, file), path.join(destPath, file)

# Recursive tree deletion.
removeTree = (dirPath) ->
  fs.readdirSync(dirPath).forEach (file) ->
    filePath = path.join dirPath, file
    if getMode(filePath) is S_IFDIR
    then removeTree filePath
    else fs.unlinkSync filePath
  fs.rmdirSync dirPath
