# ArArchiveKit

**A simple, `Foundation`-less Swift package for creating `ar` archives.**

[![Swift 5.3](https://img.shields.io/badge/Swift-5.3-brightgreen?logo=swift)](https://swift.org)
[![SPM Compatible](https://img.shields.io/badge/SPM-compatible-brightgreen.svg)](https://swift.org/package-manager)
[![https://img.shields.io/badge/Platforms-iOS%20%7C%20Mac%20%7C%20Linux%20%7C%20Windows-lightgrey](https://img.shields.io/badge/Platforms-MacOS%20%7C%20Linux-lightgrey)](https://img.shields.io/badge/Platforms-MacOS%20%7C%20Linux-lightgrey)
[![](https://img.shields.io/github/v/tag/LebJe/ArArchiveKit)](https://github.com/LebJe/ArArchiveKit/releases)
[![Build and Test](https://github.com/LebJe/ArArchiveKit/workflows/Build%20and%20Test/badge.svg)](https://github.com/LebJe/ArArchiveKit/actions?query=workflow%3A%22Build+and+Test%22)

# Table of Contents

<!--ts-->
   * [ArArchiveKit](#ararchivekit)
   * [Table of Contents](#table-of-contents)
      * [Coming Soon](#coming-soon)
      * [Installation](#installation)
         * [Swift Package Manager](#swift-package-manager)
      * [Usage](#usage)
      * [Contributing](#contributing)

<!-- Added by: lebje, at: Wed Mar 17 11:47:40 EDT 2021 -->

<!--te-->

Created by [gh-md-toc](https://github.com/ekalinin/github-markdown-toc)

## Coming Soon

-   Reading `ar` archives

## Installation

### Swift Package Manager

Add this to the `dependencies` array in `Package.swift`:

```swift
.package(url: "https://github.com/LebJe/ArArchiveKit.git", from: “0.0.1”)
```

. Also add this to the `targets` array in the aforementioned file:

```swift
.product(name: "ArARchiveKit", package: "ArArchiveKit")
```

## Usage

First, initialize your `ArArchiveWriter`:

```swift
var writer = ArArchiveWriter()
```

Once you have your writer, you must create a `Header`, that describes the file you wish to add to your archive:

```swift
var time: Int = 1615929568

// You can also use date
let date: Date = ...
time = Int(date.timeIntervalSince1970)

let header = Header(
	// `name` will be truncated to 16 characters.
	name: "hello.txt",
	userID: 501,
	groupID: 20,
	modificationTime: time
)
```

Once you have your `Header`, you can write it, along with the contents of your file, to the archive:

```swift
let contents = [
	UInt8(ascii: "H"),
	UInt8(ascii: "e"),
	UInt8(ascii: "l"),
	UInt8(ascii: "l"),
	UInt8(ascii: "o"),
]

archive.addFile(header: header, contents: contents)
```

If you have a text file, use the overloaded version of `addFile`:

```swift
archive.addFile(header: header, contents: "Hello")
```

Once you have added your files, you can get the archive like this:

```swift
// The binary representation (Array<UInt8>) of the archive.
let bytes = archive.bytes
// You convert it to data like this:
let data = Data(bytes)

// And write it:
try data.write(to: URL(fileURLWithPath: "myArchive.a"))
```

## Contributing

Before committing, please install [pre-commit](https://pre-commit.com), and [swift-format](https://github.com/nicklockwood/SwiftFormat) and install the pre-commit hook:

```bash
$ brew bundle # install the packages specified in Brewfile
$ pre-commit install

# Commit your changes.
```

To install pre-commit on other platforms, refer to the [documentation](https://pre-commit.com/#install).
