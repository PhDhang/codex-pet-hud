import Foundation

public enum PetManifestError: Error, Equatable, Sendable {
    case missingManifest
    case invalidManifest
    case unsupportedVersion
    case unsafeSpritesheetPath
    case missingSpritesheet
}

public struct PetManifest: Equatable, Sendable {
    public let id: String
    public let displayName: String
    public let description: String?
    public let spriteVersionNumber: Int
    public let spritesheetPath: String
    public let directoryURL: URL
    public let spritesheetURL: URL

    private struct Document: Decodable {
        let id: String
        let displayName: String
        let description: String?
        let spriteVersionNumber: Int
        let spritesheetPath: String
    }

    public static func load(
        directory: URL
    ) throws -> PetManifest {
        let normalizedDirectory = directory.standardizedFileURL
        let manifestURL = normalizedDirectory
            .appendingPathComponent("pet.json")

        guard FileManager.default.fileExists(
            atPath: manifestURL.path
        ) else {
            throw PetManifestError.missingManifest
        }

        let document: Document
        do {
            document = try JSONDecoder().decode(
                Document.self,
                from: Data(contentsOf: manifestURL)
            )
        } catch {
            throw PetManifestError.invalidManifest
        }

        guard document.spriteVersionNumber == 2 else {
            throw PetManifestError.unsupportedVersion
        }

        let spritesheetURL = normalizedDirectory
            .appendingPathComponent(document.spritesheetPath)
            .standardizedFileURL
        let directoryPrefix = normalizedDirectory.path
            .hasSuffix("/")
            ? normalizedDirectory.path
            : normalizedDirectory.path + "/"
        guard spritesheetURL.path.hasPrefix(directoryPrefix) else {
            throw PetManifestError.unsafeSpritesheetPath
        }
        guard FileManager.default.fileExists(
            atPath: spritesheetURL.path
        ) else {
            throw PetManifestError.missingSpritesheet
        }

        return PetManifest(
            id: document.id,
            displayName: document.displayName,
            description: document.description,
            spriteVersionNumber: document.spriteVersionNumber,
            spritesheetPath: document.spritesheetPath,
            directoryURL: normalizedDirectory,
            spritesheetURL: spritesheetURL
        )
    }
}

public enum PetDiscovery {
    public static func discover(
        configuredPath: URL?,
        petsRoot: URL
    ) throws -> PetManifest? {
        if let configuredPath {
            return try PetManifest.load(directory: configuredPath)
        }

        let directories = try FileManager.default
            .contentsOfDirectory(
                at: petsRoot,
                includingPropertiesForKeys: [.isDirectoryKey],
                options: [.skipsHiddenFiles]
            )
            .sorted { $0.path < $1.path }

        let validPets = directories.compactMap { directory in
            try? PetManifest.load(directory: directory)
        }
        guard validPets.count == 1 else {
            return nil
        }
        return validPets[0]
    }
}
