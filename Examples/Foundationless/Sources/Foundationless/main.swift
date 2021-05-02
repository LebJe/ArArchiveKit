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

// From: https://www.hackingwithswift.com/example-code/language/how-to-split-an-array-into-chunks
extension Array {
	func chunked(into size: Int) -> [[Element]] {
		stride(from: 0, to: self.count, by: size).map {
			Array(self[$0..<Swift.min($0 + size, self.count)])
		}
	}
}

// MARK: - Exit Codes and Errors

enum ExitCode: Int32 {
	case invalidArgument = 1
	case arParserError = 2
	case otherError = 3
}

enum FoundationlessEror: Error {
	case indexOutOfRange
}

// MARK: - Arguments

enum Format: String {
	case binary, hexadecimal = "hex"
}

var shouldPrintFile = false
var printInBinary = false
var width: Int = 30
var amountOfBytes = -1
var format: Format = .hexadecimal

// MARK: - Argument Parsing

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
USAGE: \(CommandLine.arguments[0]) [--help, -h, -?] [-p] [-b] [-w <value>] [-a <value>] <file>

Reads the archive at `file` and prints information about each file in the archive.

-h, --help, -?             Prints this message.
-p                         Print the contents of the files in the archive.
-b                         Print the binary representation of the files in the archive.
-w <value> (defalut: \(width))   The amount of characters shown horizontally when printing the contents of a file in binary or ASCII/Unicode.
-a <value> (default: \(amountOfBytes))   The amount of characters/bytes you want print from each file in the archive. Use \"-1\" (with the quotes) to print the full file. If the number is greater than the amount of bytes in the file, then it will equal the amount of bytes in the file.
-f <value> (default: \(format.rawValue))  The format you want the file to be printed in. you can choose either \(Format.binary.rawValue) or \(Format.hexadecimal.rawValue).
"""

func parseArgs() {
	if CommandLine.arguments.count < 2 || parseHelpFlag(CommandLine.arguments[1]) {
		print(usage)
		exit(0)
	}

	if CommandLine.arguments.firstIndex(of: "-p") != nil {
		shouldPrintFile = true
	}

	if CommandLine.arguments.firstIndex(of: "-b") != nil {
		printInBinary = true
	}

	if let index = CommandLine.arguments.firstIndex(of: "-w") {
		if let w = Int(CommandLine.arguments[index + 1]) {
			width = w
		} else {
			print("\"\(CommandLine.arguments[index + 1])\" is not valid value for -w.")
			exit(ExitCode.invalidArgument.rawValue)
		}
	}

	if let index = CommandLine.arguments.firstIndex(of: "-a") {
		if let a = Int(CommandLine.arguments[index + 1]) {
			amountOfBytes = a
		} else {
			print("\"\(CommandLine.arguments[index + 1])\" is not valid value for -a.")
			exit(ExitCode.invalidArgument.rawValue)
		}
	}

	if let index = CommandLine.arguments.firstIndex(of: "-f") {
		if let f = Format(rawValue: CommandLine.arguments[index + 1]) {
			format = f
		} else {
			print("\"\(CommandLine.arguments[index + 1])\" is not valid value for -f.")
			exit(ExitCode.invalidArgument.rawValue)
		}
	}
}

parseArgs()

// MARK: - Main Code

func printContents(from bytes: [UInt8]) {
	if printInBinary {
		bytes
			.chunked(into: width)
			.forEach({
				$0.forEach({ byte in
					switch format {
						case .binary:
							print(String(byte, radix: 2), terminator: " ")
						case .hexadecimal:
							print("0x\(String(byte, radix: 16))", terminator: " ")
					}
				})

				print()
			})
	} else {
		print(String(bytes))
	}
}

func main() throws {
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

		if shouldPrintFile {
			print("Contents:\n")
			if amountOfBytes != -1 {
				amountOfBytes = amountOfBytes > file.count ? file.count : amountOfBytes
				printContents(from: Array(file[0..<amountOfBytes]))
			} else {
				printContents(from: file)
			}
		}
	}

	print("---------------------------")
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
