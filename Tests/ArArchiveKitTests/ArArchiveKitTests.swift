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

		XCTAssertEqual(Data(writer.bytes), data)
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

		XCTAssertEqual(Data(writer.bytes), data)
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
	]
}
