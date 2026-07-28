import Darwin
import Foundation

public enum PetGeometryCacheError:
    Error,
    Equatable,
    Sendable
{
    case legacyUnversioned
    case unsupportedVersion(Int)
    case nonPersistentSource
}

public struct PetGeometryRecord:
    Codable,
    Equatable,
    Sendable
{
    public static let currentVersion = 1

    public let version: Int
    public let geometry: PetVisualGeometry
    public let updatedAt: Date

    private enum CodingKeys: String, CodingKey {
        case bounds
        case ownerPID
        case source
        case updatedAt
        case version
        case windowID
    }

    fileprivate init(
        geometry: PetVisualGeometry,
        updatedAt: Date
    ) {
        version = Self.currentVersion
        self.geometry = geometry
        self.updatedAt = updatedAt
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(
            keyedBy: CodingKeys.self
        )
        guard container.contains(.version) else {
            throw PetGeometryCacheError.legacyUnversioned
        }
        let decodedVersion = try container.decode(
            Int.self,
            forKey: .version
        )
        guard decodedVersion == Self.currentVersion else {
            throw PetGeometryCacheError.unsupportedVersion(
                decodedVersion
            )
        }
        let source = try container.decode(
            PetVisualGeometrySource.self,
            forKey: .source
        )
        guard source == .shellDerived else {
            throw PetGeometryCacheError.nonPersistentSource
        }
        version = decodedVersion
        updatedAt = try container.decode(
            Date.self,
            forKey: .updatedAt
        )

        let bounds = try container.decode(
            CGRect.self,
            forKey: .bounds
        )
        let ownerPID = try container.decode(
            Int.self,
            forKey: .ownerPID
        )
        let windowID = try container.decode(
            Int.self,
            forKey: .windowID
        )
        geometry = PetVisualGeometry(
            window: WindowDescriptor(
                owner: "ChatGPT",
                name: PetWindowLocator.visualWindowName,
                layer: 3,
                bounds: bounds,
                ownerPID: ownerPID,
                windowID: windowID
            ),
            source: source
        )
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(
            keyedBy: CodingKeys.self
        )
        try container.encode(version, forKey: .version)
        try container.encode(geometry.source, forKey: .source)
        try container.encode(
            geometry.window.bounds,
            forKey: .bounds
        )
        try container.encode(
            geometry.window.ownerPID,
            forKey: .ownerPID
        )
        try container.encode(updatedAt, forKey: .updatedAt)
        try container.encode(
            geometry.window.windowID,
            forKey: .windowID
        )
    }
}

public struct PetGeometryCache: Sendable {
    public let url: URL

    public init(url: URL) {
        self.url = url
    }

    public func load() throws -> PetGeometryRecord? {
        guard FileManager.default.fileExists(
            atPath: url.path
        ) else {
            return nil
        }
        return try JSONDecoder().decode(
            PetGeometryRecord.self,
            from: Data(contentsOf: url)
        )
    }

    public func load(
        intersecting displays: [CGRect]
    ) throws -> PetGeometryRecord? {
        guard let record = try load() else {
            return nil
        }
        guard displays.contains(where: {
            record.geometry.window.bounds.intersects($0)
        }) else {
            return nil
        }
        return record
    }

    @discardableResult
    public func save(
        _ geometry: PetVisualGeometry,
        updatedAt: Date
    ) throws -> Bool {
        guard geometry.source == .shellDerived else {
            return false
        }
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let record = PetGeometryRecord(
            geometry: geometry,
            updatedAt: updatedAt
        )
        try encoder.encode(record).write(
            to: url,
            options: .atomic
        )
        guard chmod(url.path, S_IRUSR | S_IWUSR) == 0 else {
            throw CocoaError(.fileWriteNoPermission)
        }
        return true
    }
}
