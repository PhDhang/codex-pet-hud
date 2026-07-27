import CoreGraphics
import XCTest
@testable import PetHUDCore

final class TacticalHUDLayoutMetricsTests: XCTestCase {
    func testStandardPanelUsesIntendedReadableMetrics() {
        let metrics = TacticalHUDLayoutMetrics(
            frameSize: CGSize(width: 210, height: 58)
        )

        XCTAssertEqual(metrics.meterFontSize, 10)
        XCTAssertEqual(metrics.statusFontSize, 8)
        XCTAssertEqual(metrics.flameWidth, 13)
        XCTAssertEqual(metrics.flameSpacing, 3)
        XCTAssertLessThanOrEqual(metrics.spRowWidth, 210)
        XCTAssertLessThanOrEqual(metrics.contentHeight, 58)
    }

    func testCompactPanelUsesFloorsAndFitsSevenFlames() {
        let metrics = TacticalHUDLayoutMetrics(
            frameSize: CGSize(width: 136.5, height: 37.7)
        )

        XCTAssertEqual(metrics.meterFontSize, 8)
        XCTAssertEqual(metrics.statusFontSize, 7)
        XCTAssertEqual(metrics.flameWidth, 9)
        XCTAssertEqual(metrics.flameSpacing, 1.5)
        XCTAssertLessThanOrEqual(metrics.spRowWidth, 136.5)
        XCTAssertLessThanOrEqual(metrics.contentHeight, 37.7)
    }

    func testExpandedPanelCapsMetricsAtStandardSize() {
        let standard = TacticalHUDLayoutMetrics(
            frameSize: CGSize(width: 210, height: 58)
        )
        let expanded = TacticalHUDLayoutMetrics(
            frameSize: CGSize(width: 576, height: 92.8)
        )

        XCTAssertEqual(expanded, standard)
    }
}
