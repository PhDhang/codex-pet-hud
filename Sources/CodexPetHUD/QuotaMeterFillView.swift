import PetHUDCore
import SwiftUI

struct QuotaMeterFillView: View {
    let fraction: Double
    let baseColor: Color
    let dangerColor: Color
    let dangerLevel: QuotaDangerLevel
    let centeredText: String?

    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion
    @State private var showsDangerColor = false
    @State private var pulseGeneration = 0
    private static let criticalIntensityMagnitude = 0.22

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Capsule()
                    .fill(Color.black.opacity(0.72))
                Capsule()
                    .fill(displayColor)
                    .brightness(criticalIntensity)
                    .frame(
                        width:
                            geometry.size.width *
                            min(1, max(0, fraction))
                    )
                    .frame(
                        maxWidth: .infinity,
                        alignment: .leading
                    )
                if let centeredText {
                    Text(centeredText)
                        .font(
                            .system(
                                size: 8,
                                weight: .black,
                                design: .monospaced
                            )
                        )
                        .foregroundStyle(Color.white)
                }
            }
        }
        .onAppear {
            restartPulse()
        }
        .onChange(of: dangerLevel) {
            restartPulse()
        }
        .onChange(of: reduceMotion) {
            restartPulse()
        }
        .onDisappear {
            pulseGeneration += 1
            setDangerColor(false)
        }
    }

    private var displayColor: Color {
        guard dangerLevel != .none else {
            return baseColor
        }
        if reduceMotion {
            return dangerColor
        }
        switch dangerLevel {
        case .none:
            return baseColor
        case .low:
            return showsDangerColor ? dangerColor : baseColor
        case .critical:
            return showsDangerColor ? dangerColor : baseColor
        }
    }

    private var criticalIntensity: Double {
        guard dangerLevel == .critical && !reduceMotion else {
            return 0
        }
        return showsDangerColor ? Self.criticalIntensityMagnitude : 0
    }

    private var dangerAnimation: Animation? {
        guard !reduceMotion else {
            return nil
        }
        switch dangerLevel {
        case .none:
            return nil
        case .low:
            return .easeInOut(duration: 0.9)
                .repeatForever(autoreverses: true)
        case .critical:
            return .easeInOut(duration: 0.45)
                .repeatForever(autoreverses: true)
        }
    }

    private func restartPulse() {
        pulseGeneration += 1
        let generation = pulseGeneration
        setDangerColor(false)

        guard dangerLevel != .none else {
            return
        }
        if reduceMotion {
            setDangerColor(true)
            return
        }

        DispatchQueue.main.async {
            guard generation == pulseGeneration else {
                return
            }
            withAnimation(dangerAnimation) {
                showsDangerColor = true
            }
        }
    }

    private func setDangerColor(_ visible: Bool) {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            showsDangerColor = visible
        }
    }
}
