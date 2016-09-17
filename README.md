
# fsx v1.0.0 ![stable](https://img.shields.io/badge/stability-stable-4EBA0F.svg?style=flat)

Bare essentials `fs` wrapper. Zero dependencies.

```coffee
fs = require "fsx"
```

- `fs.exists(filePath) -> bool`
- `fs.isFile(filePath) -> bool`
- `fs.isDir(filePath) -> bool`
- `fs.isLink(filePath) -> bool`
- `fs.readFile(filePath) -> string`
- `fs.readDir(dirPath) -> [string]`
- `fs.readLink(linkPath) -> string`
