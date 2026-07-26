import CoreGraphics
import Foundation
import ImageIO

public enum PetAtlasError: Error, Equatable, Sendable {
    case unreadableImage
    case invalidDimensions
    case cropFailed
}

public enum PetAtlas {
    public static func neutralImage(
        manifest: PetManifest
    ) throws -> CGImage {
        guard
            let source = CGImageSourceCreateWithURL(
                manifest.spritesheetURL as CFURL,
                nil
            ),
            let image = CGImageSourceCreateImageAtIndex(
                source,
                0,
                nil
            )
        else {
            throw PetAtlasError.unreadableImage
        }

        guard
            image.width > 0,
            image.height > 0,
            image.width.isMultiple(of: 8),
            image.height.isMultiple(of: 11)
        else {
            throw PetAtlasError.invalidDimensions
        }

        let cellWidth = image.width / 8
        let cellHeight = image.height / 11
        guard
            let neutral = image.cropping(
                to: CGRect(
                    x: 0,
                    y: 0,
                    width: cellWidth,
                    height: cellHeight
                )
            )
        else {
            throw PetAtlasError.cropFailed
        }
        return neutral
    }
}
