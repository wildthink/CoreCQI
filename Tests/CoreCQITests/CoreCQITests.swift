import XCTest
@testable import CoreCQI

final class CoreCQITests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(CoreCQI().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
