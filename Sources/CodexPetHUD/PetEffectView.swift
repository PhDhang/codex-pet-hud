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
        let leftTravel = layout.leftTravel
        let rightTravel = layout.rightTravel
        let route = leftTravel + rightTravel
        let x =
            movingRight
                ? -leftTravel + eased * route
                : rightTravel - eased * route
        let panicBounce = layout.panicBounce
        let bounce =
            -abs(sin(local * .pi * 2)) *
            panicBounce
        let selection = PetEffectFrameSelection.panic(
            customFrameCount:
                assets.panicCustomFrames?.count ?? 0,
            movingRight: movingRight
        )
        let selectedFrames = panicFrames(for: selection)
        let frameIndex = PetEffectAnimation.frameIndex(
            elapsedTime: date.timeIntervalSinceReferenceDate,
            framesPerSecond: assets.panicFramesPerSecond,
            frameCount: selectedFrames.count,
            reduceMotion: reduceMotion
        )
        let frame = selectedFrames[frameIndex]
        let spriteSize = layout.localPetFrame.size
        let movingX = reduceMotion ? 0 : x
        let movingY = reduceMotion ? 0 : bounce

        return ZStack {
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
        let elapsedTime =
            date.timeIntervalSinceReferenceDate
        let orbitDuration =
            PetEffectAnimation.criticalOrbitDuration
        let progress =
            elapsedTime
                .truncatingRemainder(
                    dividingBy: orbitDuration
                ) /
            orbitDuration
        let fallback = animationFrame(
            progress: reduceMotion ? 0 : progress,
            frames: assets.failedFrames
        )
        let image = assets.criticalImage ?? fallback
        let imageFrame = layout.criticalImageFrame(
            imageSize: CGSize(
                width: image.width,
                height: image.height
            ),
            scale:
                assets.criticalImage == nil
                    ? 1
                    : assets.criticalScale,
            availableFrame:
                assets.criticalImage == nil
                    ? layout.localPetFrame
                    : nil
        )
        let imageSize = imageFrame.size
        let imageOrigin = imageFrame.origin
        let orbit = CriticalOrbitLayout(
            panelSize: layout.panelSize,
            imageFrame: imageFrame,
            headAnchor: assets.headAnchor
        )
        let phase = PetEffectAnimation.orbitPhase(
            elapsedTime: elapsedTime,
            reduceMotion: reduceMotion
        )
        return ZStack {
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
                genericCriticalHeadAura(
                    head: orbit.center,
                    imageSize: imageSize
                )
            }

            criticalOrbit(
                layout: orbit,
                phase: phase
            )
        }
    }

    private func criticalOrbit(
        layout: CriticalOrbitLayout,
        phase: Double
    ) -> some View {
        ZStack {
            orbitingGlyph(
                "🐦",
                size: layout.birdGlyphSize,
                center:
                    layout.birdPosition(
                        index: 0,
                        phase: phase
                    )
            )
            orbitingGlyph(
                "🐦",
                size: layout.birdGlyphSize,
                center:
                    layout.birdPosition(
                        index: 1,
                        phase: phase
                    )
            )
            orbitingGlyph(
                "✨",
                size: layout.sparkleGlyphSize,
                center:
                    layout.sparklePosition(
                        index: 0,
                        phase: phase
                    )
            )
            orbitingGlyph(
                "✨",
                size: layout.sparkleGlyphSize,
                center:
                    layout.sparklePosition(
                        index: 1,
                        phase: phase
                    )
            )
        }
    }

    private func orbitingGlyph(
        _ glyph: String,
        size: CGFloat,
        center: CGPoint
    ) -> some View {
        Group {
            if size > 0 {
                Text(glyph)
                    .font(.system(size: size * 0.82))
                    .frame(
                        width: size,
                        height: size
                    )
                    .clipped()
                    .position(
                        x: center.x,
                        y: center.y
                    )
            }
        }
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

    private func genericCriticalHeadAura(
        head: CGPoint,
        imageSize: CGSize
    ) -> some View {
        let diameter = min(
            imageSize.width * 0.34,
            imageSize.height * 0.24
        )
        return Circle()
            .trim(from: 0.08, to: 0.84)
            .stroke(
                AngularGradient(
                    colors: [
                        Color.red.opacity(0.18),
                        Color.purple.opacity(0.88),
                        Color.cyan.opacity(0.52),
                        Color.red.opacity(0.18),
                    ],
                    center: .center
                ),
                style: StrokeStyle(
                    lineWidth: max(1, diameter * 0.035),
                    lineCap: .round
                )
            )
            .frame(
                width: diameter,
                height: diameter
            )
            .position(
                x: head.x,
                y:
                    head.y -
                    imageSize.height * 0.035
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

}
