import CoreGraphics
import SwiftUI

struct CriticalEffectView: View {
    let petImage: CGImage?

    var body: some View {
        TimelineView(.animation) { timeline in
            GeometryReader { geometry in
                let phase =
                    timeline.date.timeIntervalSinceReferenceDate
                    .truncatingRemainder(dividingBy: 3.2) /
                    3.2 *
                    .pi *
                    2
                ZStack {
                    RoundedRectangle(cornerRadius: 30)
                        .fill(Color.black.opacity(0.48))
                    if let petImage {
                        Image(
                            decorative: petImage,
                            scale: 1,
                            orientation: .up
                        )
                        .resizable()
                        .scaledToFit()
                        .saturation(0.45)
                        .brightness(-0.18)
                        .rotationEffect(.degrees(76))
                        .frame(
                            width: geometry.size.width * 0.72,
                            height: geometry.size.height * 0.72
                        )
                        .offset(y: geometry.size.height * 0.18)
                    }
                    orbitingGlyph(
                        "🐦",
                        phase: phase,
                        radiusX: geometry.size.width * 0.30,
                        radiusY: geometry.size.height * 0.12,
                        center: CGPoint(
                            x: geometry.size.width * 0.5,
                            y: geometry.size.height * 0.34
                        )
                    )
                    orbitingGlyph(
                        "🐦",
                        phase: phase + .pi,
                        radiusX: geometry.size.width * 0.30,
                        radiusY: geometry.size.height * 0.12,
                        center: CGPoint(
                            x: geometry.size.width * 0.5,
                            y: geometry.size.height * 0.34
                        )
                    )
                    orbitingGlyph(
                        "✦",
                        phase: phase + .pi / 2,
                        radiusX: geometry.size.width * 0.22,
                        radiusY: geometry.size.height * 0.09,
                        center: CGPoint(
                            x: geometry.size.width * 0.5,
                            y: geometry.size.height * 0.33
                        )
                    )
                    .foregroundStyle(Color.yellow)
                }
            }
        }
    }

    private func orbitingGlyph(
        _ glyph: String,
        phase: Double,
        radiusX: CGFloat,
        radiusY: CGFloat,
        center: CGPoint
    ) -> some View {
        Text(glyph)
            .font(.system(size: glyph == "✦" ? 18 : 22))
            .shadow(
                color: Color.yellow.opacity(0.45),
                radius: 6
            )
            .position(
                x: center.x + cos(phase) * radiusX,
                y: center.y + sin(phase) * radiusY
            )
    }
}

