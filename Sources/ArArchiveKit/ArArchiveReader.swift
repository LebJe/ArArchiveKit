// Copyright (c) 2021 Jeff Lebrun
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the  Software), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED  AS IS, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.

/// `ArArchiveReader` reads `ar` files.
public struct ArArchiveReader {
	private var data: [UInt8]
	private var currentIndex: Int = 0

	/// Used primarily when in a for loop:
	///
	/// ```swift
	/// let bytes = Array<UInt8>(try Data(contentsOf: myURL))
	/// let reader = try ArArchiveReader(archive: bytes)
	/// for index = in 0..<reader.count {
	/// 	let header = reader.headers[index]
	/// 	let data = reader[headerç]
	/// 	// Use data and header.
	/// }
	/// ```
	///
	public var count: Int {
		self.headers.count
	}

	/// The headers that describe the files in this archive.
	///
	/// Use this to find a file in the archive, then use the provided subscript to get the bytes of the file.
	///
	/// ```swift
	/// let bytes = Array<UInt8>(try Data(contentsOf: myURL))
	/// let reader = try ArArchiveReader(archive: bytes)
	/// let bytes = reader[reader.headers[0]]
	/// // Use bytes...
	/// ```
	///
	public var headers: [Header] = []

	/// The initializer reads all the `ar` headers in preparation for random access to the header's file contents later.
	public init(archive: [UInt8]) throws {
		if archive.isEmpty {
			throw ArArchiveError.emptyArchive
		} else if archive.count < 8 {
			// The global header is missing.
			throw ArArchiveError.invalidArchive
		} else if Array(archive[0...7]) != globalHeader.asciiArray {
			// The global header is invalid.
			throw ArArchiveError.invalidArchive
		}

		// Drop the global header from the byte array.
		self.data = Array(archive[8...])

		var index = 0

		// Read all the headers so we can provide random access to the data later.
		while index < (self.data.count - 1), (index + (headerSize - 1)) < self.data.count - 1 {
			var h = try self.parseHeader(bytes: Array(self.data[index...(index + headerSize - 1)]))

			index += headerSize + 1
			h.contentLocation = index - 1
			index += h.size

			self.headers.append(h)
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
	public subscript(header: Header) -> [UInt8] {
		Array(self.data[header.contentLocation..<header.contentLocation + header.size])
	}

	private func parseHeader(bytes: [UInt8]) throws -> Header {
		var start = 0
		let name = self.readString(from: Array(bytes[start...15]))

		start = 16

		let modificationTime = self.readInt(from: Array(bytes[start...(start + 11)]))

		start += 12
		let userID = self.readInt(from: Array(bytes[start...(start + 5)]))

		start += 6

		let groupID = self.readInt(from: Array(bytes[start...(start + 5)]))

		start += 6

		let mode = UInt32(String(readString(from: Array(bytes[start...(start + 5)])).dropFirst(3)), radix: 8)

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
		h.size = s
		return h
	}

	/// From [blakesmith/r/reader.go: line 62](https://github.com/blakesmith/ar/blob/809d4375e1fb5bb262c159fc3ec2e7a86a8bfd28/reader.go#L62) .
	private func readString(from bytes: [UInt8]) -> String {
		var i = bytes.count - 1

		while i > 0, bytes[i] == 32 /* ASCII space character */ {
			i -= 1
		}

		return String(bytes[0...i].map({ Character(Unicode.Scalar($0)) }))
	}

	private func readInt(from bytes: [UInt8], radix: Int? = nil) -> Int? {
		if let r = radix {
			return Int(self.readString(from: bytes), radix: r)
		} else {
			return Int(self.readString(from: bytes))
		}
	}
}

extension ArArchiveReader: IteratorProtocol, Sequence {
	public typealias Element = [UInt8]

	public mutating func next() -> [UInt8]? {
		if self.currentIndex > self.headers.count - 1 {
			return nil
		}

		let bytes = self[currentIndex]
		currentIndex += 1

		return bytes
	}
}
