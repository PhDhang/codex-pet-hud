import CoreGraphics
import PetHUDCore
import SwiftUI

struct PetEffectView: View {
    let state: PetDistressState
    let assets: PetEffectAssets
    let layout: PetEffectLayout
    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    var body: some View {
        TimelineView(.animation) { timeline in
            GeometryReader { _ in
                ZStack {
                    Color.clear
                        .frame(
                            width: layout.panelSize.width,
                            height: layout.panelSize.height
                        )
                    switch state {
                    case .normal:
                        Color.clear
                    case .panic:
                        panicView(
                            date: timeline.date
                        )
                    case .critical:
                        criticalView(
                            date: timeline.date
                        )
                    }
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func panicView(
        date: Date
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
        let travel = layout.travel
        let x =
            movingRight
                ? -travel + eased * travel * 2
                : travel - eased * travel * 2
        let bounce = -abs(sin(local * .pi * 2)) * 4
        let selection = PetEffectFrameSelection.panic(
            customFrameCount:
                assets.panicCustomFrames?.count ?? 0,
            movingRight: movingRight
        )
        let selectedFrames = panicFrames(for: selection)
        let frameProgress = reduceMotion ? 0 : local
        let frame = animationFrame(
            progress: frameProgress,
            frames: selectedFrames
        )
        let spriteSize = layout.localPetFrame.size
        let movingX = reduceMotion ? 0 : x
        let movingY = reduceMotion ? 0 : bounce
        let spiralAngle = reduceMotion ? 0 : progress * 720

        return ZStack {
            nativePetAura(
                frame: layout.localPetFrame,
                state: .panic
            )

            ZStack {
                Image(
                    decorative: frame,
                    scale: 1,
                    orientation: .up
                )
                .resizable()
                .interpolation(.none)
                .scaledToFit()
                .scaleEffect(
                    x: selection.mirrorsSprite ? -1 : 1,
                    y: 1
                )
                spiralEye(
                    at: assets.leftEye,
                    in: spriteSize,
                    mirrored: selection.mirrorsEyeAnchors,
                    rotation: spiralAngle
                )
                spiralEye(
                    at: assets.rightEye,
                    in: spriteSize,
                    mirrored: selection.mirrorsEyeAnchors,
                    rotation: -spiralAngle
                )
            }
            .frame(
                width: spriteSize.width,
                height: spriteSize.height
            )
            .position(
                x: layout.localPetFrame.midX + movingX,
                y: layout.localPetFrame.midY + movingY
            )
        }
    }

    private func criticalView(
        date: Date
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
        let availableSize =
            assets.criticalImage == nil
                ? layout.localPetFrame.size
                : layout.localEffectFrame.size
        let fittedSize = aspectFitSize(
            image: image,
            in: availableSize
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
            x:
                layout.localPetFrame.midX -
                imageSize.width / 2,
            y:
                layout.localPetFrame.midY -
                imageSize.height / 2
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
            nativePetAura(
                frame: layout.localPetFrame,
                state: .critical
            )

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
        mirrored: Bool,
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
                x:
                    size.width *
                    CGFloat(
                        mirrored
                            ? 1 - anchor.x
                            : anchor.x
                    ),
                y: size.height * CGFloat(anchor.y)
            )
    }

    private func panicFrames(
        for selection: PetEffectFrameSelection
    ) -> [CGImage] {
        switch selection {
        case .custom:
            return assets.panicCustomFrames ??
                assets.panicFramesRight
        case .runningRight:
            return assets.panicFramesRight
        case .runningLeft:
            return assets.panicFramesLeft
        }
    }

    private func nativePetAura(
        frame: CGRect,
        state: PetDistressState
    ) -> some View {
        let accent =
            state == .critical
                ? Color(red: 1, green: 0.12, blue: 0.18)
                : Color(red: 0.62, green: 0.18, blue: 0.92)
        let core = Color(
            red: 0.075,
            green: 0.018,
            blue: 0.11
        )

        return ZStack {
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [
                            core.opacity(0.98),
                            core.opacity(0.96),
                            accent.opacity(0.78),
                            accent.opacity(0.22),
                            .clear,
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius:
                            max(frame.width, frame.height) * 0.58
                    )
                )
                .frame(
                    width: frame.width * 1.10,
                    height: frame.height * 1.06
                )

            Capsule()
                .fill(core.opacity(0.94))
                .overlay {
                    Capsule()
                        .stroke(
                            accent.opacity(0.58),
                            lineWidth: 1
                        )
                }
                .frame(
                    width: frame.width * 0.88,
                    height: frame.height * 0.98
                )
        }
            .shadow(
                color: accent.opacity(0.62),
                radius: 10
            )
            .position(
                x: frame.midX,
                y: frame.midY
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
