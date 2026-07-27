import Foundation

public enum PetEffectManifestError: Error, Equatable, Sendable {
    case invalidManifest
    case unsupportedVersion
    case unsafeAssetPath
    case missingAsset
}

public struct NormalizedPoint: Codable, Equatable, Sendable {
    public let x: Double
    public let y: Double

    public init(x: Double, y: Double) {
        self.x = min(1, max(0, x))
        self.y = min(1, max(0, y))
    }

    public init(from decoder: any Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let x = try container.decode(Double.self)
        let y = try container.decode(Double.self)
        guard container.isAtEnd else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Expected a two-number point."
            )
        }
        self.init(x: x, y: y)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(x)
        try container.encode(y)
    }
}

public struct PanicEffectDescriptor: Equatable, Sendable {
    public let spritesheetURL: URL?
    public let columns: Int
    public let framesPerSecond: Double
    public let leftEye: NormalizedPoint
    public let rightEye: NormalizedPoint
    public let eyeScale: Double
}

public struct CriticalEffectDescriptor: Equatable, Sendable {
    public let imageURL: URL
    public let headAnchor: NormalizedPoint
    public let scale: Double
}

public struct PetEffectManifest: Equatable, Sendable {
    public let panic: PanicEffectDescriptor?
    public let critical: CriticalEffectDescriptor?

    private struct Document: Decodable {
        let version: Int
        let panic: PanicDocument?
        let critical: CriticalDocument?
    }

    private struct PanicDocument: Decodable {
        let spritesheet: String?
        let columns: Int?
        let framesPerSecond: Double?
        let leftEye: NormalizedPoint
        let rightEye: NormalizedPoint
        let eyeScale: Double?
    }

    private struct CriticalDocument: Decodable {
        let image: String
        let headAnchor: NormalizedPoint
        let scale: Double?
    }

    public static func load(directory: URL) throws -> PetEffectManifest? {
        let resolvedDirectory = directory
            .resolvingSymlinksInPath()
            .standardizedFileURL
        let manifestURL = resolvedDirectory
            .appendingPathComponent("hud-effects.json")

        guard FileManager.default.fileExists(atPath: manifestURL.path) else {
            return nil
        }
        let resolvedManifestURL = manifestURL
            .resolvingSymlinksInPath()
            .standardizedFileURL
        guard isContained(manifestURL, in: resolvedDirectory),
              isContained(resolvedManifestURL, in: resolvedDirectory)
        else {
            throw PetEffectManifestError.unsafeAssetPath
        }

        let document: Document
        do {
            document = try JSONDecoder().decode(
                Document.self,
                from: Data(contentsOf: resolvedManifestURL)
            )
        } catch {
            throw PetEffectManifestError.invalidManifest
        }

        guard document.version == 1 else {
            throw PetEffectManifestError.unsupportedVersion
        }

        let panic = try document.panic.map {
            PanicEffectDescriptor(
                spritesheetURL: try $0.spritesheet.map {
                    try assetURL(
                        for: $0,
                        in: resolvedDirectory
                    )
                },
                columns: min(16, max(1, $0.columns ?? 8)),
                framesPerSecond: min(
                    24,
                    max(1, $0.framesPerSecond ?? 8)
                ),
                leftEye: $0.leftEye,
                rightEye: $0.rightEye,
                eyeScale: min(2, max(0.5, $0.eyeScale ?? 1))
            )
        }
        let critical = try document.critical.map {
            CriticalEffectDescriptor(
                imageURL: try assetURL(
                    for: $0.image,
                    in: resolvedDirectory
                ),
                headAnchor: $0.headAnchor,
                scale: min(2, max(0.5, $0.scale ?? 1))
            )
        }

        return PetEffectManifest(panic: panic, critical: critical)
    }

    private static func assetURL(
        for path: String,
        in directory: URL
    ) throws -> URL {
        guard !path.isEmpty, !NSString(string: path).isAbsolutePath else {
            throw PetEffectManifestError.unsafeAssetPath
        }
        let candidate = directory
            .appendingPathComponent(path)
            .standardizedFileURL
        let resolvedCandidate = candidate
            .resolvingSymlinksInPath()
            .standardizedFileURL
        guard isContained(candidate, in: directory),
              isContained(resolvedCandidate, in: directory)
        else {
            throw PetEffectManifestError.unsafeAssetPath
        }
        guard FileManager.default.fileExists(
            atPath: resolvedCandidate.path
        ),
            (try? resolvedCandidate.resourceValues(
                forKeys: [.isRegularFileKey]
            ).isRegularFile) == true
        else {
            throw PetEffectManifestError.missingAsset
        }
        return resolvedCandidate
    }

    private static func isContained(
        _ url: URL,
        in directory: URL
    ) -> Bool {
        let directoryPath = directory.path.hasSuffix("/")
            ? directory.path
            : directory.path + "/"
        return url.path.hasPrefix(directoryPath)
    }
}
