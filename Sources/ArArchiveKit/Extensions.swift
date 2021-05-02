// Copyright (c) 2021 Jeff Lebrun
//
//  Licensed under the MIT License.
//
//  The full text of the license can be found in the file named LICENSE.

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
	init(_ bytes: [UInt8]) {
		self = String(bytes.map({ Character(Unicode.Scalar($0)) }))
	}
}
