import XCTest
@testable import PetHUDCore

final class QuotaMeterMotionPolicyTests: XCTestCase {
    func testSafeMeasuredMeterAllowsDecorativeFlowWithoutPulse() {
        let policy = QuotaMeterMotionPolicy.evaluate(
            mode: .measured,
            fraction: 0.75,
            dangerLevel: .none,
            reduceMotion: false
        )

        XCTAssertTrue(policy.allowsFlow)
        XCTAssertNil(policy.pulseDuration)
    }

    func testExactlyFullMeasuredMeterIsStatic() {
        let policy = QuotaMeterMotionPolicy.evaluate(
            mode: .measured,
            fraction: 1,
            dangerLevel: .none,
            reduceMotion: false
        )

        XCTAssertFalse(policy.allowsFlow)
        XCTAssertNil(policy.pulseDuration)
    }

    func testUnlimitedMeterIsStatic() {
        let policy = QuotaMeterMotionPolicy.evaluate(
            mode: .unlimited,
            fraction: 1,
            dangerLevel: .none,
            reduceMotion: false
        )

        XCTAssertFalse(policy.allowsFlow)
        XCTAssertNil(policy.pulseDuration)
    }

    func testUnavailableMeterIsStatic() {
        let policy = QuotaMeterMotionPolicy.evaluate(
            mode: .unavailable,
            fraction: 0,
            dangerLevel: .none,
            reduceMotion: false
        )

        XCTAssertFalse(policy.allowsFlow)
        XCTAssertNil(policy.pulseDuration)
    }

    func testLowDangerUsesSlowPulseWithoutFlow() {
        let policy = QuotaMeterMotionPolicy.evaluate(
            mode: .measured,
            fraction: 0.09,
            dangerLevel: .low,
            reduceMotion: false
        )

        XCTAssertFalse(policy.allowsFlow)
        XCTAssertEqual(policy.pulseDuration, 0.9)
    }

    func testCriticalDangerUsesFastPulseWithoutFlow() {
        let policy = QuotaMeterMotionPolicy.evaluate(
            mode: .measured,
            fraction: 0.03,
            dangerLevel: .critical,
            reduceMotion: false
        )

        XCTAssertFalse(policy.allowsFlow)
        XCTAssertEqual(policy.pulseDuration, 0.45)
    }

    func testReduceMotionDisablesFlowAndPulse() {
        let policy = QuotaMeterMotionPolicy.evaluate(
            mode: .measured,
            fraction: 0.03,
            dangerLevel: .critical,
            reduceMotion: true
        )

        XCTAssertFalse(policy.allowsFlow)
        XCTAssertNil(policy.pulseDuration)
    }
}
