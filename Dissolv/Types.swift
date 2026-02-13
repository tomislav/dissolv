//
//  Types.swift
//  Dissolv
//

import Foundation
import Defaults
import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    static let togglePause = Self("togglePause")
    @available(*, deprecated, renamed: "togglePause")
    static let tooglePause = togglePause
}

struct CustomAppSetting: Codable, Defaults.Serializable {
    var appName: String
    var bundleIdentifier: String
    var hideAfter: Double

    init(appName: String, bundleIdentifier: String, hideAfter: Double) {
        self.appName = appName
        self.bundleIdentifier = bundleIdentifier
        self.hideAfter = hideAfter
    }

    private enum CodingKeys: String, CodingKey {
        case appName
        case bundleIdentifier
        case hideAfter
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        appName = try container.decode(String.self, forKey: .appName)
        hideAfter = try container.decode(Double.self, forKey: .hideAfter)

        // Backward compatibility for defaults saved before bundle identifiers were introduced.
        bundleIdentifier = try container.decodeIfPresent(String.self, forKey: .bundleIdentifier) ?? appName
    }
}

struct SelectableApplication: Hashable {
    let name: String
    let bundleIdentifier: String
}
