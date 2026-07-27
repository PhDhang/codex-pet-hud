import Darwin
import Foundation

public struct PetGeometryRecord:
    Codable,
    Equatable,
    Sendable
{
    public let window: WindowDescriptor
    public let updatedAt: Date

    private enum CodingKeys: String, CodingKey {
        case bounds
        case ownerPID
        case updatedAt
        case window
        case windowID
    }

    public init(
        window: WindowDescriptor,
        updatedAt: Date
    ) {
        self.window = window
        self.updatedAt = updatedAt
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(
            keyedBy: CodingKeys.self
        )
        updatedAt = try container.decode(
            Date.self,
            forKey: .updatedAt
        )
        if let legacyWindow = try container.decodeIfPresent(
            WindowDescriptor.self,
            forKey: .window
        ) {
            window = legacyWindow
            return
        }

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
        window = WindowDescriptor(
            owner: "",
            name: "",
            layer: 0,
            bounds: bounds,
            ownerPID: ownerPID,
            windowID: windowID
        )
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(
            keyedBy: CodingKeys.self
        )
        try container.encode(window.bounds, forKey: .bounds)
        try container.encode(window.ownerPID, forKey: .ownerPID)
        try container.encode(updatedAt, forKey: .updatedAt)
        try container.encode(window.windowID, forKey: .windowID)
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
            record.window.bounds.intersects($0)
        }) else {
            return nil
        }
        return record
    }

    public func save(_ record: PetGeometryRecord) throws {
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(record).write(
            to: url,
            options: .atomic
        )
        guard chmod(url.path, S_IRUSR | S_IWUSR) == 0 else {
            throw CocoaError(.fileWriteNoPermission)
        }
    }
}
