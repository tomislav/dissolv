import XCTest
@testable import Dissolv

final class AppSettingsResolverTests: XCTestCase {
    func testUsesBundleIdentifierWhenAvailable() {
        let settings = [
            CustomAppSetting(appName: "Safari", bundleIdentifier: "com.apple.Safari", hideAfter: 120),
            CustomAppSetting(appName: "Mail", bundleIdentifier: "com.apple.mail", hideAfter: 300),
        ]

        let identity = AppIdentity(bundleIdentifier: "com.apple.Safari", localizedName: "Safari")
        let hideAfter = AppSettingsResolver.hideAfter(for: identity, settings: settings, defaultHideAfter: 600)

        XCTAssertEqual(hideAfter, 120)
    }

    func testFallsBackToLegacyNameMatchingWhenBundleIdentifierMissing() {
        let settings = [
            CustomAppSetting(appName: "Notes", bundleIdentifier: "Notes", hideAfter: 180),
        ]

        let identity = AppIdentity(bundleIdentifier: nil, localizedName: "Notes")
        let hideAfter = AppSettingsResolver.hideAfter(for: identity, settings: settings, defaultHideAfter: 600)

        XCTAssertEqual(hideAfter, 180)
    }
}
