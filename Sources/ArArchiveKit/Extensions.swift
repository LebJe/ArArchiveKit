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

extension String {
	var utf8Array: [UInt8] {
		Array(self.utf8)
	}

	var asciiArray: [UInt8] {
		Array(self.map({ $0.asciiValue! }))
	}
}

extension String {
	// From https://gist.github.com/budidino/8585eecd55fd4284afaaef762450f98e .
	/**
	 Truncates the string to the specified length number of characters and appends an optional trailing string if longer.
	 - Parameter length: Desired maximum lengths of a string
	 - Parameter trailing: A 'String' that will be appended after the truncation.

	 - Returns: 'String' object.
	 */
	func truncate(length: Int, trailing: String = "") -> String {
		(self.count > length) ? self.prefix(length) + trailing : self
	}
}

public extension String {
	/// Initialize `String` from an array of bytes.
	init(_ ascii: [UInt8]) {
		self = String(ascii.map({ Character(Unicode.Scalar($0)) }))
	}
}
