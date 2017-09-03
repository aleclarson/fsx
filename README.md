
# fsx v1.3.0 ![stable](https://img.shields.io/badge/stability-stable-4EBA0F.svg?style=flat)

Bare essentials `fs` wrapper. Zero dependencies.

```coffee
fs = require "fsx"

# Returns true if the given path is a file, directory, or link.
fs.exists filePath

# Returns true if the given path is the expected type.
fs.isFile filePath
fs.isDir filePath
fs.isLink filePath

# Reads the contents at the given path.
fs.readFile filePath

# Returns an array of filenames that exist as children of the given path.
fs.readDir dirPath

# Returns the path pointed to by the given link path.
fs.readLink linkPath

# Write the contents at the given path.
fs.writeFile filePath, contents

# Link the first path to the second path.
fs.writeLink linkPath, targetPath

# Delete the given file path.
fs.removeFile filePath

# Delete the given directory path, and all its children.
fs.removeDir filePath

# Rename the first path to the second path.
fs.rename oldPath, newPath

# Copy the first path to the second path.
fs.copy srcPath, destPath
```

#### Tips

- You can pass the desired encoding to `fs.readFile` ("utf8" by default). For example, pass `null` to return a `Buffer`.

- You can pass either a string or buffer to `fs.writeFile`.

- Passing a link path to `fs.removeFile` is allowed.

- Passing a directory path to `fs.readFile`, `fs.writeFile`, or `fs.removeFile` will throw an error.

- Using `fs.rename` can overwrite an existing file or link, but trying to overwrite a directory will throw an error.

- If the second argument to `fs.copy` is a directory, the copied path(s) will be put inside.

- You can merge two directories with same name by calling `fs.copy(dirA, dirB)`.

- When merging directories with `fs.copy`, be careful not to accidentally overwrite directories with a file or link.

- When merging directories with `fs.copy`, any sub-directories will merge into pre-existing directories with the same name.

- Using `fs.readFile` on a link path will resolve the link before reading.

- Using `fs.writeFile` on a link path will resolve the link before writing.

- Using `fs.removeFile` on a link path **won't** resolve the link before removing.

- When one or more directories in a path don't exist, `fs.writeDir` will create them for you.

