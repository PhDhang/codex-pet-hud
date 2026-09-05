import Foundation

struct NativePetSettingsReader {
    private struct Stamp: Equatable {
        let url: URL
        let modified: Date
        let size: UInt64

        init?(_ url: URL) {
            guard let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
                  let modified = attributes[.modificationDate] as? Date,
                  let size = attributes[.size] as? NSNumber
            else { return nil }
            self.url = url
            self.modified = modified
            self.size = size.uint64Value
        }
    }

    private var stamps: [Stamp] = []
    private var settings: NativePetSettings?

    mutating func load(codexHome: URL) -> NativePetSettings? {
        let stateURL = codexHome.appendingPathComponent(".codex-global-state.json")
        let configURL = codexHome.appendingPathComponent("config.toml")
        guard let stateStamp = Stamp(stateURL), let configStamp = Stamp(configURL) else {
            stamps = []
            settings = nil
            return nil
        }
        let currentStamps = [stateStamp, configStamp]
        if currentStamps == stamps { return settings }
        settings = nil
        guard let data = try? Data(contentsOf: stateURL),
              let config = try? String(contentsOf: configURL, encoding: .utf8)
        else { return nil }
        stamps = currentStamps
        settings = NativePetSettings.parse(globalState: data, configTOML: config)
        return settings
    }
}
