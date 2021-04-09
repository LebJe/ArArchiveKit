// Copyright (c) 2021 Jeff Lebrun
//
//  Licensed under the MIT License.
//
//  The full text license can be found in the file named LICENSE.

/// `ArArchiveWriter` creates `ar` files.
public struct ArArchiveWriter {
	/// The raw bytes of the archive.
	public var bytes: [UInt8] = []

	public let variant: Variant

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

	private mutating func writeString(_ str: String, size: Int) {
		var s = str

		while s.count < size {
			s = s + " "
		}

		self.bytes += s.asciiArray
	}

	private mutating func writeInt<I: BinaryInteger>(_ int: I, size: Int, radix: Int? = nil, prefix: String? = nil) {
		if let r = radix {
			self.writeString((prefix != nil ? prefix! : "") + String(int, radix: r), size: size)
		} else {
			self.writeString((prefix != nil ? prefix! : "") + String(int), size: size)
		}
	}

	/// Adds a `Header` to the archive.
	private mutating func addHeader(header: Header, contentSize: Int) {
		switch self.variant {
			case .common: self.writeString(header.name.truncate(length: 16), size: 16)
			case .bsd:
				self.writeString(header.name.count <= 16 && !header.name.contains(" ") ? header.name : "#1/\(header.name.count)", size: 16)
		}

		self.writeInt(header.modificationTime, size: 12, radix: 10)
		self.writeInt(header.userID, size: 6, radix: 10)
		self.writeInt(header.groupID, size: 6, radix: 10)
		self.writeInt(header.mode, size: 8, radix: 8, prefix: "100")

		switch self.variant {
			case .common:
				self.writeInt(contentSize, size: 10, radix: 10)
				self.writeString("`\n", size: 2)
			case .bsd:
				if header.name.count > 16 || header.name.contains(" ") {
					self.writeInt(contentSize + header.name.count, size: 10, radix: 10)
					self.writeString("`\n", size: 2)
					self.writeString(header.name, size: header.name.count)
				} else {
					self.writeInt(contentSize, size: 10, radix: 10)
					self.writeString("`\n", size: 2)
				}
		}
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
