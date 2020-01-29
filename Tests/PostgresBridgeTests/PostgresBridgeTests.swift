import XCTest
@testable import PostgresBridge

final class PostgresBridgeTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(PostgresBridge().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
