import CoreGraphics
import PetHUDCore
import SwiftUI

struct PetEffectView: View {
    let state: PetDistressState
    let assets: PetEffectAssets
    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    var body: some View {
        TimelineView(.animation) { timeline in
            GeometryReader { geometry in
                switch state {
                case .normal:
                    Color.clear
                case .panic:
                    panicView(
                        date: timeline.date,
                        geometry: geometry
                    )
                case .critical:
                    criticalView(
                        date: timeline.date,
                        geometry: geometry
                    )
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func panicView(
        date: Date,
        geometry: GeometryProxy
    ) -> some View {
        let duration = 2.4
        let progress =
            date.timeIntervalSinceReferenceDate
                .truncatingRemainder(dividingBy: duration) /
            duration
        let movingRight = reduceMotion || progress < 0.5
        let local =
            movingRight
                ? progress * 2
                : (progress - 0.5) * 2
        let eased = 0.5 - cos(local * .pi) / 2
        let travel = min(geometry.size.width * 0.18, 28)
        let x =
            movingRight
                ? -travel + eased * travel * 2
                : travel - eased * travel * 2
        let bounce = -abs(sin(local * .pi * 2)) * 4
        let frames =
            movingRight
                ? assets.panicFramesRight
                : assets.panicFramesLeft
        let frameProgress = reduceMotion ? 0 : local
        let frame = animationFrame(
            progress: frameProgress,
            frames: frames
        )
        let spriteSize = CGSize(
            width: geometry.size.width / 1.35,
            height: geometry.size.height / 1.10
        )
        let movingX = reduceMotion ? 0 : x
        let movingY = reduceMotion ? 0 : bounce
        let spiralAngle = reduceMotion ? 0 : progress * 720

        return ZStack {
            RoundedRectangle(cornerRadius: 26)
                .fill(
                    Color(
                        red: 0.28,
                        green: 0.02,
                        blue: 0.06
                    )
                    .opacity(0.82)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 26)
                        .stroke(
                            Color.red.opacity(0.28),
                            lineWidth: 1
                        )
                }

            ZStack {
                Image(
                    decorative: frame,
                    scale: 1,
                    orientation: .up
                )
                .resizable()
                .interpolation(.none)
                .scaledToFit()
                spiralEye(
                    at: assets.leftEye,
                    in: spriteSize,
                    rotation: spiralAngle
                )
                spiralEye(
                    at: assets.rightEye,
                    in: spriteSize,
                    rotation: -spiralAngle
                )
            }
            .frame(
                width: spriteSize.width,
                height: spriteSize.height
            )
            .offset(x: movingX, y: movingY)
        }
    }

    private func criticalView(
        date: Date,
        geometry: GeometryProxy
    ) -> some View {
        let orbitDuration = 3.0
        let progress =
            date.timeIntervalSinceReferenceDate
                .truncatingRemainder(
                    dividingBy: orbitDuration
                ) /
            orbitDuration
        let fallback = animationFrame(
            progress: reduceMotion ? 0 : progress,
            frames: assets.failedFrames
        )
        let image = assets.criticalImage ?? fallback
        let fittedSize = aspectFitSize(
            image: image,
            in: geometry.size
        )
        let imageSize = CGSize(
            width:
                fittedSize.width *
                CGFloat(assets.criticalScale),
            height:
                fittedSize.height *
                CGFloat(assets.criticalScale)
        )
        let imageOrigin = CGPoint(
            x: (geometry.size.width - imageSize.width) / 2,
            y: geometry.size.height - imageSize.height
        )
        let head = CGPoint(
            x:
                imageOrigin.x +
                imageSize.width * CGFloat(assets.headAnchor.x),
            y:
                imageOrigin.y +
                imageSize.height * CGFloat(assets.headAnchor.y)
        )
        let phase =
            reduceMotion
                ? 0
                : progress * .pi * 2
        let radiusX = min(imageSize.width * 0.20, 44)
        let radiusY = min(imageSize.height * 0.12, 24)

        return ZStack {
            RoundedRectangle(cornerRadius: 26)
                .fill(Color.red.opacity(0.12))

            Image(
                decorative: image,
                scale: 1,
                orientation: .up
            )
            .resizable()
            .interpolation(.none)
            .scaledToFit()
            .frame(
                width: imageSize.width,
                height: imageSize.height
            )
            .position(
                x: imageOrigin.x + imageSize.width / 2,
                y: imageOrigin.y + imageSize.height / 2
            )

            if assets.criticalImage == nil {
                fallbackSpiralEyes(
                    head: head,
                    imageSize: imageSize
                )
            }

            orbitingGlyph(
                "🐦",
                phase: phase,
                radiusX: radiusX,
                radiusY: radiusY,
                center: head
            )
            orbitingGlyph(
                "🐦",
                phase: phase + .pi,
                radiusX: radiusX,
                radiusY: radiusY,
                center: head
            )
            orbitingGlyph(
                "✦",
                phase: phase + .pi / 2,
                radiusX: radiusX * 0.72,
                radiusY: radiusY * 0.72,
                center: head
            )
            .foregroundStyle(Color.yellow)
            orbitingGlyph(
                "✧",
                phase: phase + .pi * 1.5,
                radiusX: radiusX * 0.72,
                radiusY: radiusY * 0.72,
                center: head
            )
            .foregroundStyle(Color.yellow)
        }
    }

    private func spiralEye(
        at anchor: NormalizedPoint,
        in size: CGSize,
        rotation: Double
    ) -> some View {
        Text("🌀")
            .font(
                .system(
                    size: spiralSize(for: size)
                )
            )
            .rotationEffect(.degrees(rotation))
            .position(
                x: size.width * CGFloat(anchor.x),
                y: size.height * CGFloat(anchor.y)
            )
    }

    private func fallbackSpiralEyes(
        head: CGPoint,
        imageSize: CGSize
    ) -> some View {
        let eyeOffset = imageSize.width * 0.035
        let size = spiralSize(for: imageSize)
        return ZStack {
            Text("🌀")
                .font(.system(size: size))
                .position(
                    x: head.x - eyeOffset,
                    y: head.y
                )
            Text("🌀")
                .font(.system(size: size))
                .position(
                    x: head.x + eyeOffset,
                    y: head.y
                )
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
            .font(
                .system(size: glyph == "🐦" ? 22 : 18)
            )
            .shadow(
                color: Color.yellow.opacity(0.45),
                radius: 6
            )
            .position(
                x: center.x + cos(phase) * radiusX,
                y: center.y + sin(phase) * radiusY
            )
    }

    private func animationFrame(
        progress: Double,
        frames: [CGImage]
    ) -> CGImage {
        let index = min(
            Int(progress * Double(frames.count)),
            frames.count - 1
        )
        return frames[index]
    }

    private func spiralSize(
        for size: CGSize
    ) -> CGFloat {
        max(
            8,
            min(size.width, size.height) *
                0.07 *
                CGFloat(assets.eyeScale)
        )
    }

    private func aspectFitSize(
        image: CGImage,
        in bounds: CGSize
    ) -> CGSize {
        let imageSize = CGSize(
            width: image.width,
            height: image.height
        )
        let scale = min(
            bounds.width / imageSize.width,
            bounds.height / imageSize.height
        )
        return CGSize(
            width: imageSize.width * scale,
            height: imageSize.height * scale
        )
    }
}
