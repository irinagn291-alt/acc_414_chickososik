#if DEBUG
import Foundation

enum StoreFrame: String, CaseIterable {
    case sunlitLane = "sunlit-lane"
    case trailAtlas = "trail-atlas"
    case forkHint = "fork-hint"
    case millCrossing = "mill-crossing"
    case orchardLanes = "orchard-lanes"
    case allTrailsHome = "all-trails-home"

    static let current: Self? = {
        let process = ProcessInfo.processInfo
        func argument(_ flag: String) -> String? {
            guard let index = process.arguments.firstIndex(of: flag),
                  index + 1 < process.arguments.count else { return nil }
            return process.arguments[index + 1]
        }
        if let key = argument("-ReviewScreen") { return Self(rawValue: key) }
        guard process.arguments.contains("-AppStoreScreenshots") || process.environment["APPSTORE_SCREENSHOTS"] == "1" else { return nil }
        let value = argument("-AppStoreScreenshotScreen") ?? process.environment["APPSTORE_SCREENSHOT_SCREEN"] ?? "0"
        guard let index = Int(value), allCases.indices.contains(index) else { return nil }
        return allCases[index]
    }()
}
#endif
