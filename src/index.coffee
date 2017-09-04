
path = require "path"
fs = require "fs"

# Constants used for determining file type.
{S_IFMT, S_IFREG, S_IFDIR, S_IFLNK} = fs.constants

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
    throw Error "Cannot use `readDir` on a non-existent path: '#{dirPath}'"
  if mode isnt S_IFDIR
    throw Error "Expected a directory: '#{dirPath}'"
  return fs.readdirSync dirPath

exports.readFile = (filePath, encoding) ->
  unless mode = getMode filePath
    throw Error "Cannot use `readFile` on a non-existent path: '#{filePath}'"
  if mode is S_IFDIR
    throw Error "Cannot use `readFile` on a directory: '#{filePath}'"
  encoding = "utf8" if encoding is undefined
  return fs.readFileSync filePath, encoding

exports.readLink = (linkPath) ->
  unless mode = getMode linkPath
    throw Error "Cannot use `readLink` on a non-existent path: '#{linkPath}'"
  if mode is S_IFLNK
    return fs.readlinkSync linkPath
  return linkPath

exports.writeDir = (dirPath) ->
  unless mode = getMode dirPath
    exports.writeDir path.dirname dirPath
    return fs.mkdirSync dirPath
  if mode isnt S_IFDIR
    throw Error "Cannot use `writeDir` on an existing path: '#{dirPath}'"

exports.writeFile = (filePath, string) ->
  if getMode(filePath) isnt S_IFDIR
    return fs.writeFileSync filePath, string
  throw Error "Cannot use `writeFile` on a directory: '#{filePath}'"

exports.writeLink = (linkPath, targetPath) ->
  unless getMode linkPath
    return fs.symlinkSync targetPath, linkPath
  throw Error "Cannot use `writeLink` on an existing path: '#{linkPath}'"

exports.removeDir = (dirPath) ->
  unless mode = getMode dirPath
    throw Error "Cannot use `removeDir` on a non-existent path: '#{dirPath}'"
  if mode isnt S_IFDIR
    throw Error "Expected a directory: '#{dirPath}'"
  if ".." is path.relative(process.cwd(), dirPath).slice 0, 2
    throw Error "Cannot use `removeDir` on paths outside of the current directory: '#{dirPath}'"
  return removeTree dirPath

exports.removeFile = (filePath) ->
  unless mode = getMode filePath
    throw Error "Cannot use `removeFile` on a non-existent path: '#{filePath}'"
  if mode is S_IFDIR
    throw Error "Cannot use `removeFile` on a directory: '#{filePath}'"
  return fs.unlinkSync filePath

exports.rename = (srcPath, destPath) ->
  unless mode = getMode srcPath
    throw Error "Cannot `rename` non-existent path: '#{srcPath}'"
  if mode is S_IFDIR
    if getMode destPath
      throw Error "Cannot `rename` directory to pre-existing path: '#{destPath}'"
  else if getMode(destPath) is S_IFDIR
    throw Error "Cannot overwrite directory path: '#{destPath}'"
  exports.writeDir path.dirname destPath
  return fs.renameSync srcPath, destPath

exports.copy = (srcPath, destPath) ->

  unless mode = getMode srcPath
    throw Error "Cannot `copy` non-existent path: '#{srcPath}'"

  if mode is S_IFDIR
    return copyTree srcPath, destPath

  destMode = getMode destPath

  if destMode is S_IFDIR
    destPath = path.join destPath, path.basename srcPath
    destMode = getMode destPath

  if destMode
    if destMode is S_IFDIR
      throw Error "Cannot overwrite directory path: '#{destPath}'"
    fs.unlinkSync destPath

  if mode is S_IFLNK
  then copyLink srcPath, destPath
  else fs.writeFileSync destPath, fs.readFileSync srcPath

#
# Helpers
#

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
