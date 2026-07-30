import PetHUDCore
import SwiftUI

struct QuotaMeterPalette {
    let shadow: Color
    let body: Color
    let highlight: Color

    var gradient: LinearGradient {
        LinearGradient(
            colors: [shadow, body, highlight],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}

struct QuotaMeterFillView: View {
    let fraction: Double
    let palette: QuotaMeterPalette
    let mode: MPPresentationMode
    let dangerLevel: QuotaDangerLevel
    let centeredText: String?

    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion
    @State private var flowAtEnd = false
    @State private var showsWhitePulse = false
    @State private var motionGeneration = 0
    private static let criticalIntensityMagnitude = 0.22

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Capsule()
                    .fill(Color.black.opacity(0.72))
                filledCapsule(
                    width:
                        geometry.size.width *
                        min(1, max(0, fraction))
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
            restartMotion()
        }
        .onChange(of: motionPolicy) {
            restartMotion()
        }
        .onDisappear {
            motionGeneration += 1
            resetMotion()
        }
    }

    private func filledCapsule(width: CGFloat) -> some View {
        ZStack {
            if dangerLevel != .none && reduceMotion {
                Capsule()
                    .fill(palette.highlight)
            } else {
                Capsule()
                    .fill(palette.gradient)
            }
            GeometryReader { geometry in
                Capsule()
                    .fill(flowGradient)
                    .frame(width: max(10, geometry.size.width * 0.28))
                    .offset(
                        x:
                            flowAtEnd
                            ? geometry.size.width
                            : -max(10, geometry.size.width * 0.28)
                    )
            }
            Capsule()
                .fill(Color.white.opacity(pulseOpacity))
        }
        .brightness(criticalIntensity)
        .frame(width: width)
        .clipShape(Capsule())
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var flowGradient: LinearGradient {
        LinearGradient(
            colors: [
                palette.highlight.opacity(0),
                palette.highlight.opacity(0.15),
                palette.highlight.opacity(0),
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    private var pulseOpacity: Double {
        showsWhitePulse ? 1 : 0
    }

    private var motionPolicy: QuotaMeterMotionPolicy {
        QuotaMeterMotionPolicy.evaluate(
            mode: mode,
            fraction: fraction,
            dangerLevel: dangerLevel,
            reduceMotion: reduceMotion
        )
    }

    private var criticalIntensity: Double {
        guard dangerLevel == .critical && !reduceMotion else {
            return 0
        }
        return showsWhitePulse ? Self.criticalIntensityMagnitude : 0
    }

    private var flowAnimation: Animation {
        .linear(duration: 2.4)
            .repeatForever(autoreverses: false)
    }

    private func pulseAnimation(duration: TimeInterval) -> Animation {
        .easeInOut(duration: duration)
            .repeatForever(autoreverses: true)
    }

    private func restartMotion() {
        motionGeneration += 1
        let generation = motionGeneration
        resetMotion()

        if motionPolicy.allowsFlow {
            DispatchQueue.main.async {
                guard generation == motionGeneration else {
                    return
                }
                withAnimation(flowAnimation) {
                    flowAtEnd = true
                }
            }
            return
        }

        guard let pulseDuration = motionPolicy.pulseDuration else {
            return
        }
        DispatchQueue.main.async {
            guard generation == motionGeneration else {
                return
            }
            withAnimation(pulseAnimation(duration: pulseDuration)) {
                showsWhitePulse = true
            }
        }
    }

    private func resetMotion() {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            flowAtEnd = false
            showsWhitePulse = false
        }
    }
}
