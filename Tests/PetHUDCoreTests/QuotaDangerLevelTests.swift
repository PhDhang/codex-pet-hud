import XCTest
@testable import PetHUDCore

final class QuotaDangerLevelTests: XCTestCase {
    func testCanonicalDangerBoundaries() {
        XCTAssertEqual(QuotaDangerLevel.evaluate(10), .none)
        XCTAssertEqual(QuotaDangerLevel.evaluate(9.99), .low)
        XCTAssertEqual(QuotaDangerLevel.evaluate(4), .low)
        XCTAssertEqual(QuotaDangerLevel.evaluate(3.99), .low)
        XCTAssertEqual(QuotaDangerLevel.evaluate(3), .critical)
        XCTAssertEqual(QuotaDangerLevel.evaluate(0), .critical)
    }
}
