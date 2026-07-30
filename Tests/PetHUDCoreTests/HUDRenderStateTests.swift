import CoreGraphics
import XCTest
@testable import PetHUDCore

final class HUDRenderStateTests: XCTestCase {
    func testDuplicateRequestDoesNotRefreshContent() {
        let data = HUDPresentationData.make(
            petName: "一茬",
            state: .offline,
            now: Date(timeIntervalSince1970: 0)
        )
        let frame = CGRect(x: 48, y: 224, width: 240, height: 67)
        var state = HUDRenderState()

        XCTAssertTrue(
            state.shouldRefreshContent(
                data: data,
                frameSize: frame.size
            )
        )
        XCTAssertFalse(
            state.shouldRefreshContent(
                data: data,
                frameSize: frame.size
            )
        )
    }
}
