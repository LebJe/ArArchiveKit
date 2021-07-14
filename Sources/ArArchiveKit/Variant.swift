// Copyright (c) 2021 Jeff Lebrun
//
//  Licensed under the MIT License.
//
//  The full text of the license can be found in the file named LICENSE.

/// The different formats of the `ar` archive.
public enum Variant: String {
	/// The "common" format. This format is used by Debian `deb` packages.
	case common = "Common"

	/// Used by the BSD and MacOS implementation of the `ar` command. This format is backwards-compatible with the "common" format.
	case bsd = "BSD"

	/// The System V (or GNU) variant. Used by the GNU implementation of the `ar` command, and on Windows.
	/// This format is **not** backwards-compatible with the "common" format.
	case gnu = "GNU"
}
