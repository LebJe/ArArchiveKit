
/// `ArArchiveWriter` creates `ar` files.
public struct ArArchiveWriter {
	/// The raw bytes of the archive.
	public var bytes: [UInt8] = []

	public init() {
		self.addGlobalHeader()
	}

	private mutating func write(_ newBytes: [UInt8]) {
		self.bytes += newBytes
		if newBytes.count % 2 == 1 {
			self.bytes += "\n".asciiArray
		}
	}

	private mutating func addGlobalHeader() {
		self.write(Array("!<arch>\n".map({ $0.asciiValue! })))
	}

	private mutating func writeString(_ str: String, size: Int) {
		var s = str
		while s.count < size {
			s = s + " "
		}

		self.bytes += Array(s.asciiArray)
	}

	private mutating func writeInt<I: BinaryInteger>(_ int: I, size: Int, radix: Int? = nil, prefix: String? = nil) {
		if let r = radix {
			self.writeString((prefix != nil ? prefix! : "") + String(int, radix: r), size: size)
		} else {
			self.writeString((prefix != nil ? prefix! : "") + String(int), size: size)
		}
	}

	/// Add a file to the archive.
	/// - Parameters:
	///   - header: The header that describes the file.
	///   - contents: The raw bytes of the file.
	public mutating func addFile(header: Header, contents: [UInt8]) {
		self.writeString(header.name.truncate(length: 16), size: 16)
		self.writeInt(header.modificationTime, size: 12, radix: 10)
		self.writeInt(header.userID, size: 6, radix: 10)
		self.writeInt(header.groupID, size: 6, radix: 10)
		self.writeInt(header.mode, size: 8, radix: 8, prefix: "100")
		self.writeInt(contents.count, size: 10, radix: 10)
		self.writeString("`\n", size: 2)
		self.write(contents)
	}

	/// Wrapper function around `ArArchiveWriter.addFile(header:contents:)` which allows you to pass in a `String` instead of raw bytes..
	public mutating func addFile(header: Header, contents: String) {
		self.addFile(header: header, contents: Array(contents.utf8))
	}
}
