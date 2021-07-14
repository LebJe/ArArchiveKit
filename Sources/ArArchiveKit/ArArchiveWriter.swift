// Copyright (c) 2021 Jeff Lebrun
//
//  Licensed under the MIT License.
//
//  The full text of the license can be found in the file named LICENSE.

/// `ArArchiveWriter` creates `ar` files.
///
/// ```swift
/// import Foundation
///
/// var writer = ArArchiveWriter()
/// writer.addFile(header: Header(name: "hello.txt", modificationTime: Int(Date().timeIntervalSince1970)), contents: "Hello, World!")
/// let data = Data(writer.finalize())
/// ```
public struct ArArchiveWriter {
	/// The raw bytes of the archive.
	private var bytes: [UInt8] = []

	public let variant: Variant

	private var headers: [Header] = []
	private var files: [[UInt8]] = []

	/// The `Header` for the archive entry used in GNU `ar` to store filenames longer the 15 characters.
	private let longGNUFilenamesEntryHeader = Header(name: "//", modificationTime: 0)

	/// The archive entry used in GNU `ar` to store filenames longer the 15 characters.
	private var longGNUFilenamesEntry = ""

	private var hasLongGNUFilenames = false
	private var longGNUFilenamesEntryIndex = 0

	public init(variant: Variant = .common) {
		self.variant = variant
	}

	private mutating func write(_ newBytes: [UInt8]) {
		self.bytes += newBytes
		if newBytes.count % 2 != 0 {
			self.bytes += "\n".asciiArray
		}
	}

	private mutating func addMagicBytes() {
		self.write(Constants.globalHeader.asciiArray)
	}

	private func stringToASCII(_ str: String, size: Int) -> [UInt8] {
		var s = str

		while s.count < size {
			s = s + " "
		}

		return s.asciiArray
	}

	private func intToBytes<I: BinaryInteger>(_ int: I, size: Int, radix: Int? = nil, prefix: String? = nil) -> [UInt8] {
		if let r = radix {
			return self.stringToASCII((prefix != nil ? prefix! : "") + String(int, radix: r), size: size)
		} else {
			return self.stringToASCII((prefix != nil ? prefix! : "") + String(int), size: size)
		}
	}

	private mutating func writeString(_ str: String, size: Int) {
		self.bytes += self.stringToASCII(str, size: size)
	}

	private mutating func writeInt<I: BinaryInteger>(_ int: I, size: Int, radix: Int? = nil, prefix: String? = nil) {
		self.bytes += self.intToBytes(int, size: size, radix: radix, prefix: prefix)
	}

	private mutating func headerToBytes(header: Header, contentSize: Int) -> [UInt8] {
		var header = header
		var data: [UInt8] = []

		switch self.variant {
			case .common: data += self.stringToASCII(header.name.truncate(length: 16), size: 16)
			case .bsd:
				data += self.stringToASCII(header.name.count <= 16 && !header.name.contains(" ") ? header.name : "#1/\(header.name.count)", size: 16)
			case .gnu:
				if header.name.count > 15 {
					self.hasLongGNUFilenames = true
					self.longGNUFilenamesEntry += header.name + "/\n"

					data += self.stringToASCII("/\(String(self.longGNUFilenamesEntryIndex))", size: 16)

					self.longGNUFilenamesEntryIndex += header.name.count + 3
				} else {
					data += self.stringToASCII(header.name + "\(header.name == "//" ? "" : "/")", size: 16)
				}
		}

		data += self.intToBytes(header.modificationTime, size: 12, radix: 10)
		data += self.intToBytes(header.userID, size: 6, radix: 10)
		data += self.intToBytes(header.groupID, size: 6, radix: 10)
		data += self.intToBytes(header.mode, size: 8, radix: 8, prefix: "100")

		switch self.variant {
			case .common, .gnu:
				data += self.intToBytes(contentSize, size: 10, radix: 10)
				data += self.stringToASCII("`\n", size: 2)

			case .bsd:
				if header.name.count > 16 || header.name.contains(" ") {
					data += self.intToBytes(contentSize + header.name.count, size: 10, radix: 10)
					data += self.stringToASCII("`\n", size: 2)
					data += self.stringToASCII(header.name, size: header.name.count)
				} else {
					data += self.intToBytes(contentSize, size: 10, radix: 10)
					data += self.stringToASCII("`\n", size: 2)
				}
		}

		header.nameSize = header.name.count > 16 || header.name.contains(" ") ? header.name.count : nil
		header.contentLocation = (self.bytes.endIndex - 1) + contentSize + (contentSize % 2 != 0 ? 1 : 0)

		return data
	}

	/// Adds a `Header` to the archive.
	private mutating func addHeader(header: Header, contentSize: Int) {
		var header = header
		header.size = contentSize
		self.headers.append(header)
	}

	/// Add a file to the archive.
	/// - Parameters:
	///   - header: The header that describes the file.
	///   - contents: The raw bytes of the file.
	public mutating func addFile(header: Header, contents: [UInt8]) {
		if self.variant == .gnu, header.name.count > 15 {
			self.hasLongGNUFilenames = true
		}
		self.addHeader(header: header, contentSize: contents.count)
		self.files.append(contents)
	}

	/// Wrapper function around `ArArchiveWriter.addFile(header:contents:)` which allows you to pass in a `String` instead of raw bytes..
	public mutating func addFile(header: Header, contents: String) {
		self.addFile(header: header, contents: Array(contents.utf8))
	}

	/// Creates an archive and returns the bytes of the created archive.
	/// - Parameter clear: Whether the data in `self.bytes` and `self.headers` should be cleared. If `clear` is `true`, then you can reuse this `ArArchiveWriter`.
	/// - Returns: The bytes of the created archive.
	public mutating func finalize(clear: Bool = true) -> [UInt8] {
		self.addMagicBytes()

		var headerBytes: [[UInt8]] = []

		for i in 0..<self.headers.count {
			headerBytes.append(self.headerToBytes(header: self.headers[i], contentSize: self.headers[i].size))
		}

		// Add the `//` entry if there are long filenames.
		if self.variant == .gnu, self.hasLongGNUFilenames {
			self.bytes += self.headerToBytes(header: self.longGNUFilenamesEntryHeader, contentSize: self.longGNUFilenamesEntry.count)
			self.bytes += self.longGNUFilenamesEntry.utf8Array
		}

		for i in 0..<headerBytes.count {
			self.bytes += headerBytes[i]
			self.write(self.files[i])
		}

		if clear {
			let b = self.bytes

			self.bytes = []
			self.headers = []

			return b
		} else {
			return self.bytes
		}
	}
}
