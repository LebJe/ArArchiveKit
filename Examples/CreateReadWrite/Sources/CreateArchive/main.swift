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

enum ExitCode: Int32 {
	case invalidArgument = 1
	case arParserError = 2
	case otherError = 3
}

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
USAGE: \(CommandLine.arguments[0]) [--help, -h, -?] <files...>

Creates an `ar` archive from `files`.

-h, --help, -?  Prints this message.
"""

if CommandLine.arguments.count < 2 || parseHelpFlag(CommandLine.arguments[1]) {
	print(usage)
	exit(0)
}

func main() throws {
	var writer = ArArchiveWriter()

	for item in CommandLine.arguments.dropFirst() {
		// Open `item`.
		guard let fp = fopen(item, "rb") else {
			print("Unable to open \(item)")
			exit(2)
		}

		print("Adding \(item) to archive...")

		let fpNumber = fileno(fp)

		// Make sure `item` is a file.
		let statPointer = UnsafeMutablePointer<stat>.allocate(capacity: 1)
		fstat(fileno(fp), statPointer)

		switch statPointer.pointee.st_mode & S_IFMT {
			case S_IFREG: break
			case S_IFDIR, S_IFLNK:
				print("Can't add directory \"\(item)\" to archive! Directories are not alloed.")
				exit(1)
			default:
				print("Can't add directory \"\(item)\" to archive! Directories are not alloed.")
				exit(1)
		}

		// Load `item` into memory.
		let size = Int(lseek(fpNumber, 0, SEEK_END))

		lseek(fpNumber, 0, SEEK_SET)

		let buf = UnsafeMutableRawBufferPointer.allocate(byteCount: size, alignment: MemoryLayout<UInt8>.alignment)

		read(fpNumber, buf.baseAddress, buf.count)

		let bufferPointer = buf.bindMemory(to: UInt8.self)
		let bytes = Array(bufferPointer)

		let stat = statPointer.pointee

		#if os(Linux) || os(Android) || os(Windows)
			let statTime = stat.st_mtim.tv_sec
		#else
			let statTime = stat.st_mtimespec.tv_sec
		#endif

		writer.addFile(
			header: Header(
				name: item,
				userID: Int(stat.st_uid),
				groupID: Int(stat.st_gid),
				mode: UInt32(stat.st_mode & (S_IRWXU | S_IRWXG | S_IRWXO)),
				modificationTime: Int(statTime)
			),
			contents: bytes
		)

		fclose(fp)
	}

	guard let fp = fopen("output.a", "wb") else {
		print("Unable to open output.a")
		exit(4)
	}

	let bytes = writer.finalize()

	if bytes.withUnsafeBytes({ write(fileno(fp), $0.baseAddress!, bytes.count) }) != -1 {
		print("Successfully wrote output.a!")
		exit(0)
	} else {
		print("Unable to write output.a")
		exit(6)
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
