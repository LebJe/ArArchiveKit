// Copyright (c) 2021 Jeff Lebrun
//
//  Licensed under the MIT License.
//
//  The full text license can be found in the file named LICENSE.

#if os(macOS)
	import Darwin.C
#elseif os(Linux)
	import Glibc
#elseif os(Windows)
	import ucrt
#endif

import ArArchiveKit

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
USAGE: \(CommandLine.arguments[0]) [--help, -h, -?] [-p] [-b] <file>

Reads the archive at `file` prints information about each file in the archive. Note that `-b` must come AFTER `-p`.

-h, --help, -?  Prints this message.
-p  Print the contents of the files in the archive.
-b  Print the binary representation of the files in the archive.
"""

var shouldPrintFile = false
var printInBinary = false

func parseArgs() {
	if CommandLine.arguments.count < 2 || parseHelpFlag(CommandLine.arguments[1]) {
		print(usage)
		exit(1)
	}

	if CommandLine.arguments.count >= 3, CommandLine.arguments[2] == "-p" {
		shouldPrintFile = true
	}

	if CommandLine.arguments.count >= 4, CommandLine.arguments[3] == "-b" {
		printInBinary = true
	}
}

parseArgs()

let fd = open(CommandLine.arguments[1], O_RDONLY)

let size = Int(lseek(fd, 0, SEEK_END))

lseek(fd, 0, SEEK_SET)

let buf = UnsafeMutableRawBufferPointer.allocate(byteCount: size, alignment: MemoryLayout<UInt8>.alignment)

read(fd, buf.baseAddress, buf.count)

let bufferPointer = buf.bindMemory(to: UInt8.self)

let bytes = Array(bufferPointer)

let reader = try ArArchiveReader(archive: bytes)

for (header, file) in reader {
	print("---------------------------")

	print("Name: " + header.name)
	print("User ID: " + String(header.userID))
	print("Group ID: " + String(header.groupID))
	print("Mode (In Octal): " + String(header.mode, radix: 8))
	print("File Size: " + String(header.size))
	print("File Modification Time: " + String(header.modificationTime))

	print("Contents:\n")

	if shouldPrintFile {
		if printInBinary {
			file.forEach({ print($0) })
		} else {
			print(String(file))
		}
	}
}

print("---------------------------")
