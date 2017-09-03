
nodeFs = require "fs"
path = require "path"
fs = require "fsx"

nextFile = do ->
  (nextId = 1) and -> "file" + nextId++

nextLink = do ->
  (nextId = 1) and -> "link" + nextId++

nextDir = do ->
  (nextId = 1) and -> "dir" + nextId++

randomString = ->
  Math.random().toString(36).slice(2)

beforeAll ->
  nodeFs.mkdirSync "fixtures"
  process.chdir "fixtures"

describe "fs.writeDir", ->

  it "creates a directory at the given path", ->
    dirPath = nextDir()
    fs.writeDir dirPath
    files = nodeFs.readdirSync dirPath
    expect(files).toEqual []

  it "creates missing parent directories", ->
    dirPath = path.join nextDir(), randomString(), randomString()
    fs.writeDir dirPath
    files = nodeFs.readdirSync dirPath
    expect(files).toEqual []

  it "returns early when the directory already exists", ->
    nodeFs.mkdirSync dirPath = nextDir()
    expect -> fs.writeDir dirPath
    .not.toThrow()

  it "throws for non-directory paths", ->

    filePath = nextFile()
    nodeFs.writeFileSync filePath, randomString()
    expect -> fs.writeDir filePath
    .toThrowError "Cannot use `writeDir` on an existing path: '#{filePath}'"

    linkPath = nextLink()
    nodeFs.symlinkSync filePath, linkPath
    expect -> fs.writeDir linkPath
    .toThrowError "Cannot use `writeDir` on an existing path: '#{linkPath}'"

describe "fs.writeFile", ->

  it "creates a file with the given contents", ->
    filePath = nextFile()
    fs.writeFile filePath, expected = randomString()
    contents = nodeFs.readFileSync filePath, "utf8"
    expect(contents).toBe expected

  it "overwrites the contents of an existing file", ->
    filePath = nextFile()
    nodeFs.writeFileSync filePath, randomString()

    fs.writeFile filePath, expected = randomString()
    contents = nodeFs.readFileSync filePath, "utf8"
    expect(contents).toBe expected

  it "resolves link paths before writing", ->
    filePath = nextFile()
    linkPath = nextLink()
    nodeFs.symlinkSync filePath, linkPath

    fs.writeFile linkPath, expected = randomString()
    contents = nodeFs.readFileSync filePath, "utf8"
    expect(contents).toBe expected

  it "throws for directory paths", ->
    nodeFs.mkdirSync dirPath = nextDir()
    expect -> fs.writeFile dirPath, randomString()
    .toThrowError "Cannot use `writeFile` on a directory: '#{dirPath}'"

describe "fs.writeLink", ->

  it "creates a link to another path", ->
    filePath = nextFile()
    nodeFs.writeFileSync filePath, randomString()
    linkPath = nextLink()
    fs.writeLink linkPath, filePath
    expect(nodeFs.readlinkSync linkPath).toBe filePath

  it "throws for existing paths", ->

    linkPath = nextLink()
    nodeFs.symlinkSync randomString(), linkPath
    expect -> fs.writeLink linkPath, randomString()
    .toThrowError "Cannot use `writeLink` on an existing path: '#{linkPath}'"

    filePath = nextFile()
    nodeFs.writeFileSync filePath, randomString()
    expect -> fs.writeLink filePath, randomString()
    .toThrowError "Cannot use `writeLink` on an existing path: '#{filePath}'"

    nodeFs.mkdirSync dirPath = nextDir()
    expect -> fs.writeLink dirPath, randomString()
    .toThrowError "Cannot use `writeLink` on an existing path: '#{dirPath}'"

describe "fs.readDir", ->

  it "returns an array of filenames", ->
    nodeFs.mkdirSync dirPath = nextDir()
    expected = [randomString(), randomString()].sort()
    nodeFs.writeFileSync path.join(dirPath, expected[0]), randomString()
    nodeFs.mkdirSync path.join(dirPath, expected[1])
    expect(fs.readDir dirPath).toEqual expected

  it "throws for non-existent paths", ->
    filePath = randomString()
    expect -> fs.readDir filePath
    .toThrowError "Cannot use `readDir` on a non-existent path: '#{filePath}'"

  it "throws for non-directory paths", ->

    filePath = nextFile()
    nodeFs.writeFileSync filePath, randomString()
    expect -> fs.readDir filePath
    .toThrowError "Expected a directory: '#{filePath}'"

    linkPath = nextLink()
    nodeFs.symlinkSync randomString(), linkPath
    expect -> fs.readDir linkPath
    .toThrowError "Expected a directory: '#{linkPath}'"

describe "fs.readFile", ->

  it "reads the contents of a file", ->
    filePath = nextFile()
    nodeFs.writeFileSync filePath, expected = randomString()
    expect(fs.readFile filePath).toBe expected

  it "resolves link paths before reading", ->
    filePath = nextFile()
    nodeFs.writeFileSync filePath, expected = randomString()
    linkPath = nextLink()
    nodeFs.symlinkSync filePath, linkPath
    expect(fs.readFile linkPath).toBe expected

  it "supports an encoding argument", ->
    filePath = nextFile()
    nodeFs.writeFileSync filePath, expected = randomString()
    contents = fs.readFile filePath, null
    expect(Buffer.isBuffer contents).toBe true
    expect(contents.toString()).toBe expected

  it "throws for non-existent paths", ->
    filePath = randomString()
    expect -> fs.readFile filePath
    .toThrowError "Cannot use `readFile` on a non-existent path: '#{filePath}'"

  it "throws for directory paths", ->
    nodeFs.mkdirSync dirPath = nextDir()
    expect -> fs.readFile dirPath
    .toThrowError "Cannot use `readFile` on a directory: '#{dirPath}'"

describe "fs.readLink", ->

  it "resolves a link path into its target path", ->
    nodeFs.symlinkSync expected = randomString(), linkPath = nextLink()
    expect(fs.readLink linkPath).toBe expected

  it "passes non-link paths through", ->

    filePath = nextFile()
    nodeFs.writeFileSync filePath, randomString()
    expect(fs.readLink filePath).toBe filePath

    nodeFs.mkdirSync dirPath = nextDir()
    expect(fs.readLink dirPath).toBe dirPath

  it "does *not* resolve link paths recursively", ->
    nodeFs.symlinkSync link2 = nextLink(), link1 = nextLink()
    nodeFs.symlinkSync randomString(), link2
    expect(fs.readLink link1).toBe link2

describe "fs.removeDir", ->

  it "removes a directory and all children", ->
    nodeFs.mkdirSync root = nextDir()
    nodeFs.mkdirSync subdir = nextDir()
    nodeFs.writeFileSync path.join(root, randomString()), randomString()
    nodeFs.writeFileSync path.join(subdir, randomString()), randomString()
    expect ->
      fs.removeDir root
      nodeFs.mkdirSync root
    .not.toThrow()

  it "throws for non-existent paths", ->
    filePath = randomString()
    expect -> fs.removeDir filePath
    .toThrowError "Cannot use `removeDir` on a non-existent path: '#{filePath}'"

  it "throws for non-directory paths", ->

    filePath = nextFile()
    nodeFs.writeFileSync filePath, randomString()
    expect -> fs.removeDir filePath
    .toThrowError "Expected a directory: '#{filePath}'"

    linkPath = nextLink()
    nodeFs.symlinkSync filePath, linkPath
    expect -> fs.removeDir linkPath
    .toThrowError "Expected a directory: '#{linkPath}'"

  it "protects against deleting directories outside of process.cwd()", ->
    nodeFs.mkdirSync dirPath = nextDir()
    nodeFs.mkdirSync root = nextDir()
    process.chdir root
    dirPath = path.join "..", dirPath
    expect -> fs.removeDir dirPath
    .toThrowError "Cannot use `removeDir` on paths outside of the current directory: '#{dirPath}'"
    process.chdir ".."

describe "fs.removeFile", ->

  it "removes a file", ->
    filePath = nextFile()
    nodeFs.writeFileSync filePath, randomString()
    fs.removeFile filePath
    expect -> nodeFs.unlinkSync filePath
    .toThrowError "ENOENT: no such file or directory, unlink '#{filePath}'"

  it "can remove links", ->
    linkPath = nextLink()
    nodeFs.symlinkSync randomString(), linkPath
    fs.removeFile linkPath
    expect -> nodeFs.readlinkSync linkPath
    .toThrowError "ENOENT: no such file or directory, readlink '#{linkPath}'"

  it "throws for non-existent paths", ->
    filePath = randomString()
    expect -> fs.removeFile filePath
    .toThrowError "Cannot use `removeFile` on a non-existent path: '#{filePath}'"

  it "throws for directory paths", ->
    nodeFs.mkdirSync dirPath = nextDir()
    expect -> fs.removeFile dirPath
    .toThrowError "Cannot use `removeFile` on a directory: '#{dirPath}'"

describe "fs.exists", ->

  it "returns true for paths that exist", ->
    nodeFs.mkdirSync dirPath = nextDir()
    nodeFs.writeFileSync filePath = nextFile(), randomString()
    nodeFs.symlinkSync filePath, linkPath = nextLink()
    expect(fs.exists dirPath).toBe true
    expect(fs.exists filePath).toBe true
    expect(fs.exists linkPath).toBe true

  it "returns false for paths that don't exist", ->
    expect(fs.exists randomString()).toBe false

describe "fs.isDir", ->

  it "returns true for directory paths", ->
    nodeFs.mkdirSync dirPath = nextDir()
    expect(fs.isDir dirPath).toBe true

  it "returns false for non-directory paths", ->
    nodeFs.writeFileSync filePath = nextFile(), randomString()
    nodeFs.symlinkSync randomString(), linkPath = nextLink()
    expect(fs.isDir filePath).toBe false
    expect(fs.isDir linkPath).toBe false
    expect(fs.isDir randomString()).toBe false

describe "fs.isFile", ->

  it "returns true for file paths", ->
    nodeFs.writeFileSync filePath = nextFile(), randomString()
    expect(fs.isFile filePath).toBe true

  it "returns false for non-file paths", ->
    nodeFs.mkdirSync dirPath = nextDir()
    nodeFs.symlinkSync randomString(), linkPath = nextLink()
    expect(fs.isFile dirPath).toBe false
    expect(fs.isFile linkPath).toBe false
    expect(fs.isFile randomString()).toBe false

describe "fs.isLink", ->

  it "returns true for link paths", ->
    nodeFs.symlinkSync randomString(), linkPath = nextLink()
    expect(fs.isLink linkPath).toBe true

  it "returns false for non-link paths", ->
    nodeFs.mkdirSync dirPath = nextDir()
    nodeFs.writeFileSync filePath = nextFile(), randomString()
    expect(fs.isLink dirPath).toBe false
    expect(fs.isLink filePath).toBe false
    expect(fs.isLink randomString()).toBe false

describe "fs.rename", ->

  it "can rename a directory", ->
    nodeFs.mkdirSync dir1 = nextDir()
    nodeFs.mkdirSync path.join dir1, dir2 = nextDir()
    fs.rename dir1, dir3 = nextDir()
    expect ->
      nodeFs.mkdirSync dir1
      nodeFs.readdirSync path.join dir3, dir2
    .not.toThrow()

  it "can rename a file", ->
    nodeFs.writeFileSync file1 = nextFile(), expected = randomString()
    fs.rename file1, file2 = nextFile()
    expect(nodeFs.readFileSync file2, "utf8").toBe expected
    expect -> nodeFs.readFileSync file1
    .toThrowError "ENOENT: no such file or directory, open '#{file1}'"

  it "can rename a link", ->
    filePath = randomString()
    nodeFs.symlinkSync filePath, link1 = nextLink()
    fs.rename link1, link2 = nextLink()
    expect(nodeFs.readlinkSync link2).toBe filePath
    expect -> nodeFs.readlinkSync link1
    .toThrowError "ENOENT: no such file or directory, readlink '#{link1}'"

describe "fs.copy", ->

  it "can copy a directory to a non-existent path", ->
    nodeFs.mkdirSync dir1 = nextDir()
    nodeFs.mkdirSync path.join dir1, dir2 = nextDir()
    nodeFs.writeFileSync path.join(dir1, file1 = nextFile()), randomString()
    nodeFs.writeFileSync path.join(dir1, dir2, file2 = nextFile()), randomString()

    fs.copy dir1, dir3 = nextDir()
    expect(nodeFs.readdirSync dir1).toEqual [dir2, file1]
    expect(nodeFs.readdirSync path.join dir1, dir2).toEqual [file2]

  it "can copy a file to a non-existent path", ->
    nodeFs.writeFileSync file1 = nextFile(), expected = randomString()
    fs.copy file1, file2 = nextFile()
    expect(nodeFs.readFileSync file2, "utf8").toBe expected

  it "can copy a link to a non-existent path", ->
    nodeFs.symlinkSync expected = randomString(), link1 = nextLink()
    fs.copy link1, link2 = nextLink()
    expect(nodeFs.readlinkSync link2).toBe expected

  it "throws if the source path does not exist", ->
    filePath = randomString()
    expect -> fs.copy filePath, randomString()
    .toThrowError "Cannot `copy` non-existent path: '#{filePath}'"

  it "merges the source directory into the destination directory", ->
    nodeFs.mkdirSync srcPath = nextDir()
    nodeFs.mkdirSync destPath = nextDir()

    # This directory exists in both.
    dir1 = nextDir()
    nodeFs.mkdirSync path.join(srcPath, dir1)
    nodeFs.mkdirSync path.join(destPath, dir1)

    # This empty directory should get copied.
    dir2 = nextDir()
    nodeFs.mkdirSync path.join(srcPath, dir2)

    # This file only exists in the `srcPath`.
    file1 = nextFile()
    nodeFs.writeFileSync path.join(srcPath, dir1, file1), randomString()

    # This file only exists in the `destPath`.
    file2 = nextFile()
    nodeFs.writeFileSync path.join(destPath, dir1, file2), randomString()

    # This file exists in both.
    file3 = nextFile()
    nodeFs.writeFileSync path.join(srcPath, dir1, file3), expected = randomString()
    nodeFs.writeFileSync path.join(destPath, dir1, file3), randomString()

    fs.copy srcPath, destPath
    expect(nodeFs.readdirSync destPath).toEqual [dir1, dir2].sort()
    expect(nodeFs.readdirSync path.join(destPath, dir1)).toEqual [file1, file2, file3].sort()
    expect(nodeFs.readFileSync path.join(destPath, dir1, file1), "utf8").toBe nodeFs.readFileSync path.join(srcPath, dir1, file1), "utf8"
    expect(nodeFs.readFileSync path.join(destPath, dir1, file3), "utf8").toBe expected

  it "copies the source file into the destination directory", ->
    nodeFs.mkdirSync dirPath = nextDir()
    nodeFs.writeFileSync filePath = nextFile(), expected = randomString()
    fs.copy filePath, dirPath
    expect(nodeFs.readFileSync path.join(dirPath, filePath), "utf8").toBe expected

  it "overwrites the destination path if it's a file", ->
    nodeFs.writeFileSync file1 = nextFile(), expected = randomString()
    nodeFs.writeFileSync file2 = nextFile(), randomString()
    fs.copy file1, file2
    expect(nodeFs.readFileSync file2, "utf8").toBe expected

  it "overwrites the destination path if it's a link", ->
    nodeFs.writeFileSync file1 = nextFile(), randomString()
    nodeFs.symlinkSync file1, link1 = nextLink()

    nodeFs.writeFileSync file2 = nextFile(), expected = randomString()
    fs.copy file2, link1

    expect(nodeFs.readFileSync link1, "utf8").toBe expected
    expect(nodeFs.readFileSync file1, "utf8").not.toBe expected

afterAll ->

  removeTree = (dir) ->
    nodeFs.readdirSync(dir).forEach (file) ->
      file = path.join dir, file
      try isDir = nodeFs.lstatSync(file).isDirectory()
      if isDir then removeTree file else nodeFs.unlinkSync file
    nodeFs.rmdirSync dir

  process.chdir ".."
  removeTree path.resolve "fixtures"
