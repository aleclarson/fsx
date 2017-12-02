
# fsx v1.5.0 ![stable](https://img.shields.io/badge/stability-stable-4EBA0F.svg?style=flat)

Bare essentials `fs` wrapper. Zero dependencies.

```coffee
fs = require "fsx"

# Returns true if the given path is a file, directory, or link.
fs.exists filePath

# Returns true if the given path is the expected type.
fs.isDir filePath
fs.isFile filePath
fs.isLink filePath

# Returns an array of filenames that exist as children of the given path.
fs.readDir dirPath

# Reads the contents at the given path.
fs.readFile filePath

# Returns the path pointed to by the given link path.
fs.readLink linkPath

# Returns the first non-link path pointed to by the given link path.
fs.readLinks linkPath

# Create a directory at the given path.
fs.writeDir dirPath

# Write the contents at the given path.
fs.writeFile filePath, contents

# Link the first path to the second path.
fs.writeLink linkPath, targetPath

# Delete the given directory path, and all its children.
fs.removeDir filePath

# Delete the given file path.
fs.removeFile filePath

# Rename the first path to the second path.
fs.rename oldPath, newPath

# Copy the first path to the second path.
fs.copy srcPath, destPath
```

#### Tips

- When one or more directories in a path don't exist, `fs.writeDir` will create them for you.

- You can pass the desired encoding to `fs.readFile` ("utf8" by default). For example, pass `null` to return a `Buffer`.

- You can pass either a string or buffer to `fs.writeFile`.

- Passing a link path to `fs.removeFile` is allowed.

- Passing a directory path to `fs.readFile`, `fs.writeFile`, or `fs.removeFile` will throw an error.

- Using `fs.rename` can overwrite an existing file or link, but trying to overwrite a directory will throw an error.

- You can copy a file or link into a directory by calling `fs.copy(file, dir)`.

- You can merge a directory into another by calling `fs.copy(dirA, dirB)`.

- When merging directories with `fs.copy`, be careful not to accidentally overwrite directories with a file or link.

- When merging directories with `fs.copy`, any sub-directories will merge into pre-existing directories with the same name.

- Using `fs.readFile` on a link path will resolve the link before reading.

- Using `fs.writeFile` on a link path will resolve the link before writing.

- Using `fs.removeFile` on a link path **won't** resolve the link before removing.

