import XCTest
@testable import PetHUDCore

final class ResetProgressTests: XCTestCase {
    func testSevenDaysRemainingLightsNoCells() {
        XCTAssertEqual(
            ResetProgress.cellsLit(
                secondsRemaining: 604_800,
                windowDuration: 604_800
            ),
            0
        )
    }

    func testTwoDaysRemainingLightsFiveCells() {
        XCTAssertEqual(
            ResetProgress.cellsLit(
                secondsRemaining: 172_800,
                windowDuration: 604_800
            ),
            5
        )
    }

    func testImminentResetLightsSevenCells() {
        XCTAssertEqual(
            ResetProgress.cellsLit(
                secondsRemaining: 0,
                windowDuration: 604_800
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
