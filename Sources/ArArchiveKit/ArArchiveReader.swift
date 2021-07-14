// Copyright (c) 2021 Jeff Lebrun
//
//  Licensed under the MIT License.
//
//  The full text of the license can be found in the file named LICENSE.

/// `ArArchiveReader` reads `ar` files.
///
/// ```swift
/// let archiveData: Data = ...
/// let reader = ArArchiveReader(archive: Array(archiveData))
///
/// print("Name: \(reader.headers[0])")
/// print("Contents:\n \(String(reader[0]))")
/// ```
public struct ArArchiveReader {
	private var data: [UInt8]
	private var currentIndex: Int = 0

	/// The headers that describe the files in this archive.
	///
	/// Use this to find a file in the archive, then use the provided subscript to get the bytes of the file.
	///
	/// ```swift
	/// let bytes = Array<UInt8>(try Data(contentsOf: myURL))
	/// let reader = try ArArchiveReader(archive: bytes)
	/// let bytes = reader[header: reader.headers[0]]
	/// // Use bytes...
	/// ```
	///
	public var headers: [Header] = []

	/// The amount of files in this archive.
	public var count: Int { self.headers.count }

	/// The `Variant` of this archive.
	public private(set) var variant: Variant

	/// The initializer reads all the `ar` headers in preparation for random access to the header's file contents later.
	///
	/// - Parameters:
	///   - archive: The bytes of the archive you want to read.
	/// - Throws: `ArArchiveError`.
	public init(archive: [UInt8]) throws {
		// Validate archive.
		if archive.isEmpty {
			throw ArArchiveError.emptyArchive
		} else if archive.count < 8 {
			// The global header is missing.
			throw ArArchiveError.missingMagicBytes
		} else if Array(archive[0...7]) != Constants.globalHeader.asciiArray {
			// The global header is invalid.
			throw ArArchiveError.invalidMagicBytes
		}

		// Remove the global header from the byte array.
		self.data = Array(archive[8...])

		if self.data.isEmpty {
			throw ArArchiveError.noEntries
		}

		var index = 0

		self.variant = .common

		// Read all the headers so we can provide random access to the data later.
		while index < (self.data.count - 1), (index + (Constants.headerSize - 1)) < self.data.count - 1 {
			var h = try self.parseHeader(bytes: Array(self.data[index...(index + Constants.headerSize - 1)]))

			h.contentLocation = (index + Constants.headerSize) + (h.nameSize != nil ? h.nameSize! : 0)

			// Jump past the header.
			index += Constants.headerSize

			h.name = h.nameSize != nil ? String(Array(self.data[h.contentLocation - h.nameSize!..<h.contentLocation])) : h.name

			// Jump past the content of the file.
			index += (h.size % 2 != 0 ? h.size + 1 : h.size) + (h.nameSize != nil ? h.nameSize! : 0)

			self.headers.append(h)
		}

		let nameTableHeaderIndex: Int? = self.headers[0].name == "//" ? 0 : self.headers.count >= 2 ? self.headers[1].name == "//" ? 1 : nil : nil

		if let nameTableHeaderIndex = nameTableHeaderIndex {
			let offsets = self.getNamesFromGNUNameTable(table: String(self[nameTableHeaderIndex]))

			self.variant = .gnu

			for i in 0..<self.headers.count {
				if self.headers[i].name.first == "/", let offset = Int(String(self.headers[i].name.dropFirst())) {
					self.headers[i].name = offsets[offset] ?? self.headers[i].name
				}
			}

			self.headers.remove(at: nameTableHeaderIndex)
		}

		if self.headers[0].name == "/" {
			self.headers.remove(at: 0)
		}
	}

	/// Retrieves the bytes of the item at `index`, where index is the index of the `header` stored in the `headers` property of the reader.
	///
	/// Internally, the `Header` stored at `index` is used to find the file.
	public subscript(index: Int) -> [UInt8] {
		Array(self.data[self.headers[index].contentLocation..<self.headers[index].contentLocation + self.headers[index].size])
	}

	/// Retrieves the bytes of the file described in `header`.
	///
	/// - Parameter header: The `Header` that describes the file you wish to retrieves.
	///
	/// `header` MUST be a `Header` contained in the `headers` property of this `ArArchiveReader` or else you will get a "index out of range" error.
	public subscript(header header: Header) -> [UInt8] {
		Array(self.data[header.contentLocation..<header.contentLocation + header.size])
	}

	private mutating func parseHeader(bytes: [UInt8]) throws -> Header {
		var start = 0
		var name = self.readString(from: Array(bytes[start...15]))

		start = 16

		let modificationTime = self.readInt(from: Array(bytes[start...(start + 11)]))

		start += 12

		let userID = self.readInt(from: Array(bytes[start...(start + 5)]))

		start += 6

		let groupID = self.readInt(from: Array(bytes[start...(start + 5)]))

		start += 6

		let modeBytes = Array(bytes[start...(start + 5)]).filter({ $0 != 32 })
		let mode: UInt32?

		if modeBytes.isEmpty {
			mode = 0
		} else if modeBytes.count > 3, modeBytes[0..<3] == [49, 48, 48] /* 100 */ {
			mode = UInt32(String(self.readString(from: Array(modeBytes.dropFirst(3)))), radix: 8)
		} else {
			mode = UInt32(String(self.readString(from: modeBytes)), radix: 8)
		}

		start += 8

		let size = self.readInt(from: Array(bytes[start...(start + 7)]))

		guard
			let mT = modificationTime,
			let u = userID,
			let g = groupID,
			let m = mode,
			let s = size
		else { throw ArArchiveError.invalidHeader }

		var h = Header(name: name, userID: u, groupID: g, mode: m, modificationTime: mT)

		// BSD archive
		if name.hasPrefix("#1/") {
			self.variant = .bsd
			name.removeSubrange(name.startIndex..<name.index(name.startIndex, offsetBy: 3))

			guard let nameSize = Int(name) else { throw ArArchiveError.invalidHeader }

			h.size = s - nameSize
			h.nameSize = nameSize
			// GNU archive
		} else if name.hasSuffix("/"), h.name != "//", h.name != "/" {
			h.name = String(h.name.dropLast())
			h.size = s
			// Common archive
		} else {
			h.size = s
		}

		return h
	}

	/// From [blakesmith/ar/reader.go: line 62](https://github.com/blakesmith/ar/blob/809d4375e1fb5bb262c159fc3ec2e7a86a8bfd28/reader.go#L62).
	private func readString(from bytes: [UInt8]) -> String {
		if bytes.count == 1 {
			return String(Character(Unicode.Scalar(bytes[0])))
		}

		var i = bytes.count - 1

		while i > 0, bytes[i] == 32 /* ASCII space character */ {
			i -= 1
		}

		return String(bytes[0...i].map({ Character(Unicode.Scalar($0)) }))
	}

	private func readInt(from bytes: [UInt8], radix: Int? = nil) -> Int? {
		var s = self.readString(from: bytes).filter({ $0 != " " })
		if s == "" { s = "0" }

		if let r = radix {
			return Int(s, radix: r)
		} else {
			return Int(s)
		}
	}

	/// Extracts the filenames from a GNU archive name table and generates the offsets to those filenames.
	/// - Parameter table: The table to extract the filenames from.
	/// - Returns: A `Dictionary<Int, String>`, whose keys are the filename offsets, and whose values are the filenames.
	///
	/// Before:
	///
	/// ```
	/// Very Long Filename With Spaces.txt/
	/// Very Long Filename With Spaces 2.txt/
	/// ```
	///
	/// After:
	///
	/// ```swift
	/// [
	///     0: "Very Long Filename With Spaces.txt",
	///     36: "Very Long Filename With Spaces 2.txt"
	/// ]
	/// ```
	private func getNamesFromGNUNameTable(table: String) -> [Int: String] {
		var offsetsAndNames: [Int: String] = [:]
		var offset = 0
		var names: [String] = []
		var currentName = ""
		var skipNextChar = false

		// Collect all the names.
		for i in 0..<table.count {
			if skipNextChar {
				skipNextChar = false
				continue
			}

			if
				table[table.index(table.startIndex, offsetBy: i)] == "/",
				let index = table.index(table.startIndex, offsetBy: i + 1, limitedBy: table.endIndex),
				table[index] == "\n"
			{
				skipNextChar = true
				names.append(currentName)
				currentName = ""
			} else {
				currentName.append(table[table.index(table.startIndex, offsetBy: i)])
			}
		}

		for name in names {
			offsetsAndNames[offset] = name

			offset += name.count + 3
		}

		return offsetsAndNames
	}
}

extension ArArchiveReader: Sequence {
	public func makeIterator() -> ArArchiveReaderIterator {
		ArArchiveReaderIterator(archive: self)
	}
}

public struct ArArchiveReaderIterator: IteratorProtocol {
	public typealias Element = (Header, [UInt8])

	let archive: ArArchiveReader
	var currentIndex = 0

	public mutating func next() -> (Header, [UInt8])? {
		if self.currentIndex > self.archive.headers.count - 1 {
			return nil
		}

		let bytes = self.archive[self.currentIndex]
		let h = self.archive.headers[self.currentIndex]
		self.currentIndex += 1

		return (h, bytes)
	}
}
