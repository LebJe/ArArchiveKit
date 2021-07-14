# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.3.0](https://github.com/LebJe/ArArchiveKit/releases/tag/0.3.0) - 2021-07-14

### Added

-   Added support for the [GNU `ar` format](<https://en.wikipedia.org/wiki/Ar_(Unix)#System_V_(or_GNU)_variant>).
-   Added a `variant` field to `ArArchiveReader`. This field contains the `Variant ` of the archive that was parsed.
-   Add a `noEntries` case to `ArArchiveError`.

### Changed

-   `ArArchiveWriter` now requires users to call `finalize` to access the bytes of the archive.

### Fixed

-   Correctly parse archive headers whose `mode` field is 0.

### Removed

-   `ArArchiveWriter.bytes`.

## [0.2.3](https://github.com/LebJe/ArArchiveKit/releases/tag/0.2.3) - 2021-06-22

### Added

-   Added `ArArchiveReaderIterator`.

## [0.2.2](https://github.com/LebJe/ArArchiveKit/releases/tag/0.2.2) - 2021-06-11

### Fixed

-   Replaced the compiler-generated `CodingKey` with a hand-written one so `contentLocation` isn't encoded or decoded.

## [0.2.1](https://github.com/LebJe/ArArchiveKit/releases/tag/0.2.1) - 2021-06-11

### Added

-   `Header` now conforms to `Codable`.
-   `ArArchiveReader` now has a `count` property.

## [0.2.0](https://github.com/LebJe/ArArchiveKit/releases/tag/0.2.0) - 2021-05-02

### Added

-   Added three new options to Foundationless.
-   Added support for changing the amount of characters/bytes printed, whether to print in binary of hexadecimal, and changing the line width in Foundationless.

### Fixed

-   Fixed a bug that occurred when parsing a file in an archive that contained a `\n` after it's content.

## [0.1.0](https://github.com/LebJe/ArArchiveKit/releases/tag/0.1.0) - 2021-04-09

### Added

-   Support for reading and writing [BSD variant](https://www.freebsd.org/cgi/man.cgi?query=ar&sektion=5) `ar` archives.

## [0.0.2](https://github.com/LebJe/ArArchiveKit/releases/tag/0.0.2) - 2021-03-18

### Added

-   Support for reading `ar` archives.

## [0.0.1](https://github.com/LebJe/ArArchiveKit/releases/tag/0.0.1) - 2021-03-17

### Added

-   Support for creating `ar` archives.
