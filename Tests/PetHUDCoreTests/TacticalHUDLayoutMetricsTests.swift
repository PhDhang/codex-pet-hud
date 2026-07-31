import CoreGraphics
import XCTest
@testable import PetHUDCore

final class TacticalHUDLayoutMetricsTests: XCTestCase {
    func testStandardPanelUsesIntendedReadableMetrics() {
        let metrics = TacticalHUDLayoutMetrics(
            frameSize: CGSize(width: 190, height: 72)
        )

        XCTAssertEqual(metrics.meterFontSize, 10)
        XCTAssertEqual(metrics.statusFontSize, 8)
        XCTAssertEqual(metrics.flameWidth, 13)
        XCTAssertEqual(metrics.flameSpacing, 3)
        XCTAssertLessThanOrEqual(metrics.spRowWidth, 190)
        XCTAssertLessThanOrEqual(metrics.contentHeight, 72)
    }

    func testCompactPanelUsesFloorsAndFitsSevenFlames() {
        let metrics = TacticalHUDLayoutMetrics(
            frameSize: CGSize(width: 123.5, height: 46.8)
        )

        XCTAssertEqual(metrics.meterFontSize, 8)
        XCTAssertEqual(metrics.statusFontSize, 7)
        XCTAssertEqual(metrics.flameWidth, 9)
        XCTAssertEqual(metrics.flameSpacing, 1.5)
        XCTAssertLessThanOrEqual(metrics.spRowWidth, 123.5)
        XCTAssertLessThanOrEqual(metrics.contentHeight, 46.8)
    }

    func testCompactPanelProvidesReadableCenteredMeterWidth() {
        let metrics = TacticalHUDLayoutMetrics(
            frameSize: CGSize(width: 123.5, height: 46.8)
        )
        let frameSize = CGSize(width: 123.5, height: 46.8)
        let meterWidth =
            frameSize.width -
            metrics.horizontalPadding * 2 -
            metrics.labelWidth -
            metrics.columnSpacing

        XCTAssertGreaterThanOrEqual(meterWidth, 88)
        XCTAssertLessThanOrEqual(metrics.spRowWidth, frameSize.width)
    }

    func testExpandedPanelCapsMetricsAtStandardSize() {
        let standard = TacticalHUDLayoutMetrics(
            frameSize: CGSize(width: 190, height: 72)
        )
        let expanded = TacticalHUDLayoutMetrics(
            frameSize: CGSize(width: 576, height: 120)
        )

        XCTAssertEqual(expanded, standard)
    }
}
