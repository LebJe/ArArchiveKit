@testable import ArArchiveKit
import Foundation
import XCTest

final class ArArchiveKitTests: XCTestCase {
	func testSingleArchive() throws {
		// This is an example of a functional test case.
		// Use XCTAssert and related functions to verify your tests produce the correct
		// results.

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

	func testMultiArchive() throws {
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

		writer.addFile(
			header: Header(
				name: "hello2.txt",
				userID: 501,
				groupID: 20,
				mode: 0o644,
				modificationTime: 1615990791
			),
			contents: "Hello, World!\nHello again!"
		)

		let data = try Data(contentsOf: Bundle.module.url(forResource: "test-files/multi-archive", withExtension: "a")!)

		XCTAssertEqual(Data(writer.bytes), data)
	}

	static var allTests = [
		("Test Single Archive", testSingleArchive),
		("Test Multi-Archive", testMultiArchive),
	]
}
