import Darwin
import Foundation

public struct SnapshotCache: Sendable {
    public let url: URL

    public init(url: URL) {
        self.url = url
    }

    public func load() throws -> QuotaSnapshot? {
        guard FileManager.default.fileExists(
            atPath: url.path
        ) else {
            return nil
        }
        return try JSONDecoder().decode(
            QuotaSnapshot.self,
            from: Data(contentsOf: url)
        )
    }

    public func save(
        _ snapshot: QuotaSnapshot
    ) throws {
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(snapshot).write(
            to: url,
            options: .atomic
        )
        guard chmod(url.path, S_IRUSR | S_IWUSR) == 0 else {
            throw CocoaError(.fileWriteNoPermission)
        }
    }
}

