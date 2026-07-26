import Foundation

func fixture(named name: String) throws -> Data {
    let testFile = URL(fileURLWithPath: #filePath)
    let packageRoot = testFile
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()
    return try Data(
        contentsOf: packageRoot
            .appendingPathComponent("Fixtures", isDirectory: true)
            .appendingPathComponent(name)
    )
}

func withTemporaryDirectory<T>(
    _ body: (URL) throws -> T
) throws -> T {
    let root = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString, isDirectory: true)
    try FileManager.default.createDirectory(
        at: root,
        withIntermediateDirectories: true
    )
    defer {
        try? FileManager.default.removeItem(at: root)
    }
    return try body(root)
}

