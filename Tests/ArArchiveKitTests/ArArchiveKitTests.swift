// Copyright (c) 2021 Jeff Lebrun
//
//  Licensed under the MIT License.
//
//  The full text of the license can be found in the file named LICENSE.

@testable import ArArchiveKit
import Foundation
import XCTest

final class ArArchiveKitTests: XCTestCase {
	func testWriteSingleArchive() throws {
		let data = try Data(contentsOf: Bundle.module.url(forResource: "test-files/archive", withExtension: "a")!)

		var writer = ArArchiveWriter()
		writer.addFile(
			header: Header(
				name: "hello.txt",
				userID: 501,
				groupID: 20,
				mode: 0o644,
				modificationTime: 1615990791
			),
			contents: "Hello, World!"
		)

		XCTAssertEqual(writer.finalize(), Array(data))
	}

	func testWriteLargeMultiArchive() throws {
		var writer = ArArchiveWriter()
		writer.addFile(
			header: Header(
				name: "hello.txt",
				userID: 501,
				groupID: 20,
				mode: 0o644,
				modificationTime: 1615990791
			),
			contents: "Hello, World!"
		)

		// Generate a BIG archive.
		for i in 0..<99 {
			writer.addFile(
				header: Header(
					name: "hello\(i).txt",
					userID: 501,
					groupID: 20,
					mode: 0o644,
					modificationTime: 1615990791
				),
				contents: Array(repeating: "Hello, World!", count: 200).joined(separator: "\n")
			)
		}

		let data = try Data(contentsOf: Bundle.module.url(forResource: "test-files/multi-archive", withExtension: "a")!)

		XCTAssertEqual(Data(writer.finalize()), data)
	}

	func testReadLargeArchive() throws {
		let bytes = Array<UInt8>(try Data(contentsOf: Bundle.module.url(forResource: "test-files/multi-archive", withExtension: "a")!))
		let reader = try ArArchiveReader(archive: bytes)

		XCTAssertEqual(reader.headers.count, 100)
		XCTAssertEqual(String(reader[0]), "Hello, World!")
	}

	func testReadArchive() throws {
		let bytes = Array<UInt8>(try Data(contentsOf: Bundle.module.url(forResource: "test-files/archive", withExtension: "a")!))
		let reader = try ArArchiveReader(archive: bytes)

		let h = reader.headers[0]

		XCTAssertEqual(h.name, "hello.txt")
		XCTAssertEqual(h.userID, 501)
		XCTAssertEqual(h.groupID, 20)
		XCTAssertEqual(h.mode, 0o644)
		XCTAssertEqual(h.modificationTime, 1615990791)
		XCTAssertEqual(h.size, 13)
	}

	func testReadBSDArchiveWithLongFilenames() throws {
		let bytes = Array<UInt8>(try Data(contentsOf: Bundle.module.url(forResource: "test-files/bsd-archive", withExtension: "a")!))
		let reader = try ArArchiveReader(archive: bytes)

		let h = reader.headers[0]
		let h2 = reader.headers[1]

		let expectedHeaders = [
			Header(
				name: "VeryLongFilename With Spaces.txt",
				userID: 501,
				groupID: 20,
				mode: 0o644,
				modificationTime: 1617373995
			),
			Header(
				name: "VeryLongFilenameWithoutSpaces.txt",
				userID: 501,
				groupID: 20,
				mode: 0o644,
				modificationTime: 1617373995
			),
		]

		// First header.
		XCTAssertEqual(String(reader[0]), "Contents of the first file.")
		XCTAssertEqual(h.name, expectedHeaders[0].name)
		XCTAssertEqual(h.userID, expectedHeaders[0].userID)
		XCTAssertEqual(h.groupID, expectedHeaders[0].groupID)
		XCTAssertEqual(h.mode, expectedHeaders[0].mode)
		XCTAssertEqual(h.modificationTime, expectedHeaders[0].modificationTime)
		XCTAssertEqual(h.size, 27)

		// Second header.
		XCTAssertEqual(String(reader[1]), "Contents of the second file.")
		XCTAssertEqual(h2.name, expectedHeaders[1].name)
		XCTAssertEqual(h2.userID, expectedHeaders[1].userID)
		XCTAssertEqual(h2.groupID, expectedHeaders[1].groupID)
		XCTAssertEqual(h2.mode, expectedHeaders[1].mode)
		XCTAssertEqual(h2.modificationTime, expectedHeaders[1].modificationTime)
		XCTAssertEqual(h2.size, 28)
	}

	func testWriteBSDArchiveWithLongFilenames() throws {
		var writer = ArArchiveWriter(variant: .bsd)

		writer.addFile(
			header:
			Header(
				name: "VeryLongFilename With Spaces.txt",
				userID: 501,
				groupID: 20,
				mode: 0o644,
				modificationTime: 1617373995
			),
			contents: "Contents of the first file."
		)

		writer.addFile(
			header:
			Header(
				name: "VeryLongFilenameWithoutSpaces.txt",
				userID: 501,
				groupID: 20,
				mode: 0o644,
				modificationTime: 1617373995
			),
			contents: "Contents of the second file."
		)

		let data = try Data(contentsOf: Bundle.module.url(forResource: "test-files/bsd-archive", withExtension: "a")!)

		XCTAssertEqual(Data(writer.finalize()), data)
	}

	func testWriteGNUArchive() throws {
		var writer = ArArchiveWriter(variant: .gnu)

		writer.addFile(
			header: Header(name: "Very Long Filename With Spaces.txt", modificationTime: 1626214982),
			contents: "Hello, World!"
		)

		writer.addFile(
			header: Header(name: "Very Long Filename With Spaces 2.txt", modificationTime: 1626214982),
			contents: "Hello, Again!"
		)

		writer.addFile(
			header: Header(name: "ShortName.txt", modificationTime: 1626214982),
			contents: "Hello!"
		)

		let data = try Data(contentsOf: Bundle.module.url(forResource: "test-files/gnu-archive", withExtension: "a")!)

		XCTAssertEqual(Data(writer.finalize()), data)
	}

	func testReadGNUArchive() throws {
		let data = try Array(Data(contentsOf: Bundle.module.url(forResource: "test-files/gnu-archive", withExtension: "a")!))
		let reader = try ArArchiveReader(archive: data)
		let expectedHeaders = [
			Header(name: "Very Long Filename With Spaces.txt", userID: 0, groupID: 0, mode: 420, modificationTime: 1626214982),
			Header(name: "Very Long Filename With Spaces 2.txt", userID: 0, groupID: 0, mode: 420, modificationTime: 1626214982),
			Header(name: "ShortName.txt", userID: 0, groupID: 0, mode: 420, modificationTime: 1626214982),
		]

		XCTAssertEqual(reader.headers[0].name, expectedHeaders[0].name)
		XCTAssertEqual(reader.headers[0].userID, expectedHeaders[0].userID)
		XCTAssertEqual(reader.headers[0].groupID, expectedHeaders[0].groupID)
		XCTAssertEqual(reader.headers[0].mode, expectedHeaders[0].mode)
		XCTAssertEqual(reader.headers[0].modificationTime, expectedHeaders[0].modificationTime)

		XCTAssertEqual(reader.headers[1].name, expectedHeaders[1].name)
		XCTAssertEqual(reader.headers[1].userID, expectedHeaders[1].userID)
		XCTAssertEqual(reader.headers[1].groupID, expectedHeaders[1].groupID)
		XCTAssertEqual(reader.headers[1].mode, expectedHeaders[1].mode)
		XCTAssertEqual(reader.headers[1].modificationTime, expectedHeaders[1].modificationTime)

		XCTAssertEqual(reader.headers[2].name, expectedHeaders[2].name)
		XCTAssertEqual(reader.headers[2].userID, expectedHeaders[2].userID)
		XCTAssertEqual(reader.headers[2].groupID, expectedHeaders[2].groupID)
		XCTAssertEqual(reader.headers[2].mode, expectedHeaders[2].mode)
		XCTAssertEqual(reader.headers[2].modificationTime, expectedHeaders[2].modificationTime)
	}

	func testArchiveReaderSubscripts() throws {
		let bytes = Array<UInt8>(try Data(contentsOf: Bundle.module.url(forResource: "test-files/medium-archive", withExtension: "a")!))
		let reader = try ArArchiveReader(archive: bytes)

		// Shouldn't crash
		_ = reader[header: reader.headers[2]]

		// Shouldn't crash
		_ = reader[2]
	}

	func testIterateArchiveContents() throws {
		let bytes = Array<UInt8>(try Data(contentsOf: Bundle.module.url(forResource: "test-files/multi-archive", withExtension: "a")!))
		let reader = try ArArchiveReader(archive: bytes)

		for (_, _) in reader {
			// This shouldn't crash.
		}
	}

	static var allTests = [
		("Test Writing Single Archive", testWriteSingleArchive),
		("Test Writing Large Multi-Archive", testWriteLargeMultiArchive),
		("Test Read Large Archive", testReadLargeArchive),
		("Test Iterating Over Archive's Contents", testIterateArchiveContents),
		("Test Archive Reader Subscripts", testArchiveReaderSubscripts),
		("Test Read BSD Archive With Long Filenames", testReadBSDArchiveWithLongFilenames),
		("Test Writing GNU Archive", testWriteGNUArchive),
		("Test Reading GNU Archive", testReadGNUArchive),
	]
}
