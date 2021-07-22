// Copyright (c) 2021 Jeff Lebrun
//
//  Licensed under the MIT License.
//
//  The full text of the license can be found in the file named LICENSE.

#if os(macOS)
	import Darwin.C
#elseif os(Linux)
	import Glibc
#elseif os(Windows)
	import ucrt
#endif

import ArArchiveKit

// MARK: - Extensions

// MARK: - Exit Codes and Errors

enum ExitCode: Int32 {
	case invalidArgument = 1
	case arParserError = 2
	case otherError = 3
}

// MARK: - Arguments

// // MARK: - Argument Parsing

func parseHelpFlag(_ s: String) -> Bool {
	switch s {
		case "-h": return true
		case "-help": return true
		case "--help": return true
		case "-?": return true
		default:
			return false
	}
}

let usage = """
USAGE: \(CommandLine.arguments[0]) [--help, -h, -?] <file> [directory]

Extracts the archive at `file` into the current directory, or into `derectory` if that argument was provided.

-h, --help, -?  Prints this message.
"""

if CommandLine.arguments.count < 2 || parseHelpFlag(CommandLine.arguments[1]) {
	print(usage)
	exit(0)
}

func main() throws {
	guard let fp = fopen(CommandLine.arguments[1], "rb") else {
		print("Unable to open \(CommandLine.arguments[1])")
		exit(2)
	}

	let fpNumber = fileno(fp)
	let size = Int(lseek(fpNumber, 0, SEEK_END))

	lseek(fpNumber, 0, SEEK_SET)

	let buf = UnsafeMutableRawBufferPointer.allocate(byteCount: size, alignment: MemoryLayout<UInt8>.alignment)

	read(fpNumber, buf.baseAddress, buf.count)

	let bytes = Array(buf.bindMemory(to: UInt8.self))

	let reader = try ArArchiveReader(archive: bytes)

	for (header, file) in reader {
		var dir = CommandLine.arguments.last

		if dir?.last == "/" { dir = String(dir!.dropLast()) }

		let path = dir != nil ? "\(dir!)/\(header.name)" : header.name

		let fp = fopen(path, "wb")

		if fp == nil {
			print("Failed to open \(path).")
			continue
		}
		_ = file.withUnsafeBytes({ buff in
			fwrite(buff.baseAddress!, MemoryLayout<UInt8>.stride, buff.count, fp)
		})
	}
}

do {
	try main()
} catch ArArchiveError.invalidHeader {
	fputs("One of the headers in \"\(CommandLine.arguments[1])\" is invalid.", stderr)
	exit(ExitCode.arParserError.rawValue)
} catch ArArchiveError.invalidArchive {
	fputs("The archive \"\(CommandLine.arguments[1])\" is invalid.", stderr)
	exit(ExitCode.arParserError.rawValue)
} catch {
	fputs("An error occured: \(error)", stderr)
	exit(ExitCode.otherError.rawValue)
}
