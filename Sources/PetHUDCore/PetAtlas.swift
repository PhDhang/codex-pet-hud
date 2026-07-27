import CoreGraphics
import Foundation
import ImageIO

public enum PetAtlasError: Error, Equatable, Sendable {
    case unreadableImage
    case invalidDimensions
    case cropFailed
}

public enum PetAtlasRow: Int, Sendable {
    case idle = 0
    case runningRight = 1
    case runningLeft = 2
    case failed = 5
}

public enum PetAtlas {
    public static func neutralImage(
        manifest: PetManifest
    ) throws -> CGImage {
        try image(manifest: manifest, row: .idle, column: 0)
    }

    public static func image(url: URL) throws -> CGImage {
        try loadImage(url: url)
    }

    public static func image(
        manifest: PetManifest,
        row: PetAtlasRow,
        column: Int
    ) throws -> CGImage {
        guard (0..<8).contains(column) else {
            throw PetAtlasError.invalidDimensions
        }
        let source = try image(url: manifest.spritesheetURL)
        guard
            source.width > 0,
            source.height > 0,
            source.width.isMultiple(of: 8),
            source.height.isMultiple(of: 11)
        else {
            throw PetAtlasError.invalidDimensions
        }
        let cellWidth = source.width / 8
        let cellHeight = source.height / 11
        return try croppedImage(
            source,
            rect: CGRect(
                x: column * cellWidth,
                y: row.rawValue * cellHeight,
                width: cellWidth,
                height: cellHeight
            )
        )
    }

    public static func rowImages(
        manifest: PetManifest,
        row: PetAtlasRow
    ) throws -> [CGImage] {
        try (0..<8).map {
            try image(manifest: manifest, row: row, column: $0)
        }
    }

    public static func stripImages(
        url: URL,
        columns: Int
    ) throws -> [CGImage] {
        guard columns > 0 else {
            throw PetAtlasError.invalidDimensions
        }
        let source = try image(url: url)
        guard
            source.width > 0,
            source.height > 0,
            source.width.isMultiple(of: columns)
        else {
            throw PetAtlasError.invalidDimensions
        }
        let cellWidth = source.width / columns
        return try (0..<columns).map {
            try croppedImage(
                source,
                rect: CGRect(
                    x: $0 * cellWidth,
                    y: 0,
                    width: cellWidth,
                    height: source.height
                )
            )
        }
    }

    private static func loadImage(url: URL) throws -> CGImage {
        guard
            let source = CGImageSourceCreateWithURL(url as CFURL, nil),
            let image = CGImageSourceCreateImageAtIndex(source, 0, nil)
        else {
            throw PetAtlasError.unreadableImage
        }
        return image
    }

    private static func croppedImage(
        _ image: CGImage,
        rect: CGRect
    ) throws -> CGImage {
        guard let cropped = image.cropping(to: rect) else {
            throw PetAtlasError.cropFailed
        }
        return cropped
    }
}
