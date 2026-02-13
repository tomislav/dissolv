import Foundation

struct AppIdentity {
    let bundleIdentifier: String?
    let localizedName: String?
}

enum AppSettingsResolver {
    static func customSetting(for identity: AppIdentity, in settings: [CustomAppSetting]) -> CustomAppSetting? {
        if let bundleIdentifier = identity.bundleIdentifier {
            if let match = settings.first(where: { $0.bundleIdentifier == bundleIdentifier }) {
                return match
            }
        }

        guard let localizedName = identity.localizedName else {
            return nil
        }

        // Legacy fallback for settings persisted before bundle identifier support.
        return settings.first(where: { $0.bundleIdentifier == $0.appName && $0.appName == localizedName })
    }

    static func hideAfter(for identity: AppIdentity, settings: [CustomAppSetting], defaultHideAfter: Double) -> Double {
        customSetting(for: identity, in: settings)?.hideAfter ?? defaultHideAfter
    }
}
