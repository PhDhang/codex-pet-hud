import CoreGraphics
import PetHUDCore

struct PetEffectAssets {
    let panicFramesRight: [CGImage]
    let panicFramesLeft: [CGImage]
    let panicCustomFrames: [CGImage]?
    let criticalImage: CGImage?
    let failedFrames: [CGImage]
    let headAnchor: NormalizedPoint
    let criticalScale: Double

    static func load(
        manifest: PetManifest
    ) -> PetEffectAssets? {
        guard
            let right = try? PetAtlas.rowImages(
                manifest: manifest,
                row: .runningRight
            ),
            let left = try? PetAtlas.rowImages(
                manifest: manifest,
                row: .runningLeft
            ),
            let failed = try? PetAtlas.rowImages(
                manifest: manifest,
                row: .failed
            )
        else {
            return nil
        }
        let metadata =
            (try? PetEffectManifest.load(
                directory: manifest.directoryURL
            )) ?? nil
        let panic = metadata?.panic
        let critical = metadata?.critical
        return PetEffectAssets(
            panicFramesRight: right,
            panicFramesLeft: left,
            panicCustomFrames: panic?.spritesheetURL.flatMap {
                try? PetAtlas.stripImages(
                    url: $0,
                    columns: panic?.columns ?? 8
                )
            },
            criticalImage: critical.flatMap {
                try? PetAtlas.image(url: $0.imageURL)
            },
            failedFrames: failed,
            headAnchor: critical?.headAnchor ??
                NormalizedPoint(x: 0.5, y: 0.30),
            criticalScale: critical?.scale ?? 1
        )
    }
}
