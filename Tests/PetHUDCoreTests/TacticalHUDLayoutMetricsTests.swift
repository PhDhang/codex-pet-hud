import CoreGraphics
import XCTest
@testable import PetHUDCore

final class TacticalHUDLayoutMetricsTests: XCTestCase {
    func testStandardPanelUsesIntendedReadableMetrics() {
        let metrics = TacticalHUDLayoutMetrics(
            frameSize: CGSize(width: 210, height: 75)
        )

        XCTAssertEqual(metrics.meterFontSize, 10)
        XCTAssertEqual(metrics.statusFontSize, 8)
        XCTAssertEqual(metrics.flameWidth, 13)
        XCTAssertEqual(metrics.flameSpacing, 3)
        XCTAssertLessThanOrEqual(metrics.spRowWidth, 210)
        XCTAssertLessThanOrEqual(metrics.contentHeight, 75)
    }

    func testCompactPanelUsesFloorsAndFitsSevenFlames() {
        let metrics = TacticalHUDLayoutMetrics(
            frameSize: CGSize(width: 136.5, height: 48.75)
        )

        XCTAssertEqual(metrics.meterFontSize, 8)
        XCTAssertEqual(metrics.statusFontSize, 7)
        XCTAssertEqual(metrics.flameWidth, 9)
        XCTAssertEqual(metrics.flameSpacing, 1.5)
        XCTAssertLessThanOrEqual(metrics.spRowWidth, 136.5)
        XCTAssertLessThanOrEqual(metrics.contentHeight, 48.75)
    }

    func testCompactPanelReservesFiveCharacterHPLabel() {
        let metrics = TacticalHUDLayoutMetrics(
            frameSize: CGSize(width: 136.5, height: 48.75)
        )

        XCTAssertGreaterThanOrEqual(metrics.trailingWidth, 31)
        XCTAssertLessThanOrEqual(metrics.spRowWidth, 136.5)
    }

    func testExpandedPanelCapsMetricsAtStandardSize() {
        let standard = TacticalHUDLayoutMetrics(
            frameSize: CGSize(width: 210, height: 75)
        )
        let expanded = TacticalHUDLayoutMetrics(
            frameSize: CGSize(width: 576, height: 120)
        )

        XCTAssertEqual(expanded, standard)
    }
}
