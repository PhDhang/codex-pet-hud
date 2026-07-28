import XCTest
@testable import PetHUDCore

final class ResetProgressTests: XCTestCase {
    func testSevenDayResetUsesElapsedWholeDays() {
        let day: TimeInterval = 86_400
        XCTAssertEqual(
            ResetProgress.cellsLit(
                secondsRemaining: 7 * day,
                windowDuration: 7 * day
            ),
            0
        )
        XCTAssertEqual(
            ResetProgress.cellsLit(
                secondsRemaining: 5 * day,
                windowDuration: 7 * day
            ),
            2
        )
        XCTAssertEqual(
            ResetProgress.cellsLit(
                secondsRemaining: 2 * day,
                windowDuration: 7 * day
            ),
            5
        )
        XCTAssertEqual(
            ResetProgress.cellsLit(
                secondsRemaining: 0,
                windowDuration: 7 * day
            ),
            7
        )
    }

    func testInvalidWindowDurationLightsNoCells() {
        XCTAssertEqual(
            ResetProgress.cellsLit(
                secondsRemaining: 0,
                windowDuration: 0
            ),
            0
        )
    }
}
