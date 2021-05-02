// Copyright (c) 2021 Jeff Lebrun
//
//  Licensed under the MIT License.
//
//  The full text of the license can be found in the file named LICENSE.

/// `ArArchiveWriter` creates `ar` files.
public struct ArArchiveWriter {
	/// The raw bytes of the archive.
	public var bytes: [UInt8] = []

	public let variant: Variant

	private var headers: [Header] = []

	public init(variant: Variant = .common) {
		self.variant = variant
		self.addMagicBytes()
	}

	private mutating func write(_ newBytes: [UInt8]) {
		self.bytes += newBytes
		if newBytes.count % 2 != 0 {
			self.bytes += "\n".asciiArray
		}
	}

	private mutating func addMagicBytes() {
		self.write(globalHeader.asciiArray)
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

	private func headerToBytes(header: Header, contentSize: Int) -> [UInt8] {
		var header = header
		var data: [UInt8] = []

		switch self.variant {
			case .common: data += self.stringToASCII(header.name.truncate(length: 16), size: 16)
			case .bsd:
				data += self.stringToASCII(header.name.count <= 16 && !header.name.contains(" ") ? header.name : "#1/\(header.name.count)", size: 16)
		}

		data += self.intToBytes(header.modificationTime, size: 12, radix: 10)
		data += self.intToBytes(header.userID, size: 6, radix: 10)
		data += self.intToBytes(header.groupID, size: 6, radix: 10)
		data += self.intToBytes(header.mode, size: 8, radix: 8, prefix: "100")

		switch self.variant {
			case .common:
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
		header.startingLocation = self.bytes.endIndex - 1
		self.bytes += self.headerToBytes(header: header, contentSize: contentSize)
		header.endingLocation = (self.bytes.endIndex - 1) + contentSize
		header.size = contentSize

		self.headers.append(header)
	}

	/// Add a file to the archive.
	/// - Parameters:
	///   - header: The header that describes the file.
	///   - contents: The raw bytes of the file.
	public mutating func addFile(header: Header, contents: [UInt8]) {
		self.addHeader(header: header, contentSize: contents.count)
		self.write(contents)
	}

	/// Wrapper function around `ArArchiveWriter.addFile(header:contents:)` which allows you to pass in a `String` instead of raw bytes..
	public mutating func addFile(header: Header, contents: String) {
		self.addFile(header: header, contents: Array(contents.utf8))
	}
}
