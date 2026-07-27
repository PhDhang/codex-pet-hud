import Darwin
import Foundation

public struct PetGeometryRecord:
    Codable,
    Equatable,
    Sendable
{
    public let window: WindowDescriptor
    public let updatedAt: Date

    public init(
        window: WindowDescriptor,
        updatedAt: Date
    ) {
        self.window = window
        self.updatedAt = updatedAt
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
