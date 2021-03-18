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
		self.write(globalHeader.asciiArray)
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
