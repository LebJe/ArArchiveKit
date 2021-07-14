// Copyright (c) 2021 Jeff Lebrun
//
//  Licensed under the MIT License.
//
//  The full text of the license can be found in the file named LICENSE.

enum Constants {
	/// The file signature placed atop an `ar` archive.
	static let globalHeader = "!<arch>\n"

	static let headerSize = 60
}
