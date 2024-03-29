# ArArchiveKit

**A simple, 0-dependency Swift package for reading and writing [`ar`](<https://en.wikipedia.org/wiki/Ar_(Unix)>) archives. Inspired by [ar](https://github.com/blakesmith/ar).**

[![Swift 5.3](https://img.shields.io/badge/Swift-5.3-brightgreen?logo=swift)](https://swift.org)
[![SPM Compatible](https://img.shields.io/badge/SPM-compatible-brightgreen.svg)](https://swift.org/package-manager)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FLebJe%2FArArchiveKit%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/LebJe/ArArchiveKit)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FLebJe%2FArArchiveKit%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/LebJe/ArArchiveKit)
[![](https://img.shields.io/github/v/tag/LebJe/ArArchiveKit)](https://github.com/LebJe/ArArchiveKit/releases)
[![Build and Test](https://github.com/LebJe/ArArchiveKit/workflows/Build%20and%20Test/badge.svg)](https://github.com/LebJe/ArArchiveKit/actions?query=workflow%3A%22Build+and+Test%22)

# Table of Contents

<!--ts-->

-   [ArArchiveKit](#ararchivekit)
-   [Table of Contents](#table-of-contents)
    -   [ar Variations](#ar-variations)
    -   [Installation](#installation)
        -   [Swift Package Manager](#swift-package-manager)
    -   [Usage](#usage)
        -   [Writing Archives](#writing-archives)
        -   [Reading Archives](#reading-archives)
            -   [Iteration](#iteration)
            -   [Subscript](#subscript)
    -   [Examples](#examples)
    -   [Other Platforms](#other-platforms)
        -   [Windows](#windows)
    -   [Contributing](#contributing)

<!-- Added by: lebje, at: Wed Jul 14 12:30:02 EDT 2021 -->

<!--te-->

Created by [gh-md-toc](https://github.com/ekalinin/github-markdown-toc)

Documentation is available [here](https://lebje.github.io/ArArchiveKit).

## `ar` Variations

ArArchiveKit supports the "Common", BSD, and SVR4/GNU variations of `ar` as described in [FreeBSD manpages](https://www.freebsd.org/cgi/man.cgi?query=ar&sektion=5).

Support for symbol tables may come soon.

## Installation

### Swift Package Manager

Add this to the `dependencies` array in `Package.swift`:

```swift
.package(url: "https://github.com/LebJe/ArArchiveKit.git", from: "0.3.0")
```

Also add this to the `targets` array in the aforementioned file:

```swift
.product(name: "ArArchiveKit", package: "ArArchiveKit")
```

## Usage

### Writing Archives

To write archives, you'll need a `ArArchiveWriter`:

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
	modificationTime: time
)
```

Once you have your `Header`, you can write it, along with the contents of your file, to the archive:

```swift
// Without Foundation
var contents = [
	UInt8(ascii: "H"),
	UInt8(ascii: "e"),
	UInt8(ascii: "l"),
	UInt8(ascii: "l"),
	UInt8(ascii: "o"),
]

// With Foundation

let myData: Data = "Hello".data(using .utf8)!

contents = Array<UInt8>(myData)

writer.addFile(header: header, contents: contents)
```

If you have a text file, use the overloaded version of `addFile`:

```swift
writer.addFile(header: header, contents: "Hello")
```

Once you have added your files, you can get the archive like this:

```swift
// Call finalize to get the binary representation (Array<UInt8>) of the archive.
let bytes = writer.finalize()

// You convert it to data like this:
let data = Data(bytes)

// And write it:
try data.write(to: URL(fileURLWithPath: "myArchive.a"))
```

### Reading Archives

To read archives, you need an `ArArchiveReader`:

```swift
// myData is the bytes of the archive.
let myData: Data = ...

let reader = ArArchiveReader(archive: Array<UInt8>(myData))
```

Once you have your reader, there are several ways you can retrieve the data:

#### Iteration

You can iterate though all the files in the archive like this:

```swift
for (header, data) in reader {
   // `data` is `Array<UInt8>` that contains the raw bytes of the file in the archive.
   // `header` is the `Header` that describes the `data`.

   // if you know `data` is a `String`, then you can use this initializer:
   let str = String(data)
}
```

#### Subscript

Accessing data through the `subscript` is useful when you only need to access a few items in a large archive:

```swift

// The subscript provides you with random access to any file in the archive:
let firstFile = reader[0]
let fifthFile = reader[6]
```

You can also use the version of the subscript that takes a `Header` - useful for when you have a `Header`, but not the index of that header.

```swift
let header = reader.headers.first(where: { $0.name.contains(".swift") })!
let data = reader[header: header]
```

## Examples

-   `Exaples/ReaderAndWriter`: This example shows how to use ArArchiveKit to read or extract entries from any archive using only `Darwin.C` (macOS), `Glibc` (Linux) or `ucrt` (Windows (not tested)).

## Other Platforms

ArArchiveKit doesn't depend on any library, `Foundation`, or `Darwin`/`Glibc`/`ucrt` - only the Swift standard library. It should compile on any platform where the standard library compiles.

### Windows

ArArchiveKit is currently being built on Windows, but not tested, as the [Swift Package Manager Resources](https://github.com/apple/swift-evolution/blob/main/proposals/0271-package-manager-resources.md) doesn't seem to work (or isn't available) on Windows.

## Contributing

Before committing, please install [pre-commit](https://pre-commit.com), and [swift-format](https://github.com/nicklockwood/SwiftFormat) and install the pre-commit hook:

```bash
$ brew bundle # install the packages specified in Brewfile
$ pre-commit install

# Commit your changes.
```

To install pre-commit on other platforms, refer to the [documentation](https://pre-commit.com/#install).
