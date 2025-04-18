//
//  DefaultsKeys.swift
//  Dissolv
//

import Foundation
import Defaults

extension Defaults.Keys {
    static let hideAfter = Key<Double>("hideAfter", default: 600.0)
    static let customAppSettings = Key<[CustomAppSetting]>("customAppSettings", default: [])
    static let showSettingsOnFirstStart = Key<Bool>("showSettingsOnFirstStart", default: false)
    static let firstRunDate = Key<Date?>("firstRunDate")
}
