//
//  Types.swift
//  Dissolv
//

import Foundation
import Defaults
import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    static let tooglePause = Self("togglePause")
}

public enum AppAction : Codable, Defaults.Serializable {
    case hide
    case quit
}

struct CustomAppSetting: Codable, Defaults.Serializable {
    var appName: String
    var hideAfter: Double
    var action: AppAction = .hide
}
