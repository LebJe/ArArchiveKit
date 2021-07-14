// Copyright (c) 2021 Jeff Lebrun
//
//  Licensed under the MIT License.
//
//  The full text of the license can be found in the file named LICENSE.

/// Errors that occur while reading or writing an `ar` archive.
public enum ArArchiveError: Error {
	/// The archive was empty.
	case emptyArchive

	/// There were no entries in the archive.
	case noEntries

	/// The archive was invalid. It may not contain a global header,
	/// the file headers may be ill formatted, or something else my be wrong.
	case invalidArchive

	/// The archive did not contain the correct sequence of bytes that identifies it as a `ar` archive.
	case invalidMagicBytes

	/// The archive did not contain the sequence of bytes that identifies it as a `ar` archive.
	case missingMagicBytes

	/// The header may contain invalid characters and/or bytes, or may be missing certain fields.
	case invalidHeader
}
