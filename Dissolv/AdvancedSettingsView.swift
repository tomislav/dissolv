import Cocoa
import SwiftUI
import Defaults

struct AdvancedSettingsView: View {
    @State private var customSettings = Defaults[.customAppSettings]
    @State private var selectedBundleIdentifier: String?
    @State private var addSheet: AddSheetState?

    private var selectedIndex: Int? {
        guard let selectedBundleIdentifier else {
            return nil
        }

        return customSettings.firstIndex(where: { $0.bundleIdentifier == selectedBundleIdentifier })
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .top, spacing: 16) {
                Text("Applications:")
                    .font(.body.weight(.semibold))
                    .frame(width: Layout.sectionLabelWidth, alignment: .trailing)

                VStack(alignment: .leading, spacing: 14) {
                    HStack(alignment: .top, spacing: 16) {
                        List(selection: $selectedBundleIdentifier) {
                            ForEach(customSettings, id: \.bundleIdentifier) { setting in
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(setting.appName)
                                    Text("Hide, \(HideAfterOptions.label(forHideAfter: setting.hideAfter))")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .tag(Optional(setting.bundleIdentifier))
                            }
                        }
                        .frame(
                            minWidth: Layout.appListWidth,
                            idealWidth: Layout.appListWidth,
                            maxWidth: Layout.appListWidth + 20,
                            minHeight: Layout.editorHeight
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: Layout.paneCornerRadius, style: .continuous)
                                .stroke(Color.secondary.opacity(Layout.paneBorderOpacity), lineWidth: Layout.paneBorderWidth)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: Layout.paneCornerRadius, style: .continuous))

                        VStack(alignment: .leading, spacing: 12) {
                            if let selectedIndex {
                                let setting = customSettings[selectedIndex]

                                Text(setting.appName)
                                    .font(.headline)

                                HStack(alignment: .firstTextBaseline, spacing: 10) {
                                    Text("Hide after:")
                                        .frame(width: Layout.fieldLabelWidth, alignment: .trailing)
                                    Text(HideAfterOptions.label(forHideAfter: setting.hideAfter))
                                        .font(.body.weight(.medium))
                                }

                                Slider(
                                    value: Binding(
                                        get: { HideAfterOptions.sliderValue(forHideAfter: setting.hideAfter) ?? 0 },
                                        set: { newValue in
                                            updateSelectedHideAfter(withSliderValue: newValue)
                                        }
                                    ),
                                    in: 0...100
                                )
                                .accessibilityLabel("Hide after for \(setting.appName)")

                                Spacer(minLength: 0)
                            } else if customSettings.isEmpty {
                                Text("No custom applications configured.")
                                    .foregroundStyle(.secondary)
                                Spacer(minLength: 0)
                            } else {
                                Text("Select an application from the list.")
                                    .foregroundStyle(.secondary)
                                Spacer(minLength: 0)
                            }
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, minHeight: Layout.editorHeight, alignment: .topLeading)
                        .background(
                            RoundedRectangle(cornerRadius: Layout.paneCornerRadius, style: .continuous)
                                .fill(Color(nsColor: .textBackgroundColor))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: Layout.paneCornerRadius, style: .continuous)
                                .stroke(Color.secondary.opacity(Layout.paneBorderOpacity), lineWidth: Layout.paneBorderWidth)
                        )
                    }

                    HStack(spacing: 10) {
                        Button("Add") {
                            openAddApplicationsSheet()
                        }

                        Button("Remove") {
                            removeSelectedApplication()
                        }
                        .disabled(selectedIndex == nil)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)

                Spacer(minLength: 0)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(24)
        .onAppear {
            if selectedBundleIdentifier == nil {
                selectedBundleIdentifier = customSettings.first?.bundleIdentifier
            }
        }
        .sheet(item: $addSheet) { state in
            AddApplicationsSheet(apps: state.apps) { selectedApps in
                appendApplications(selectedApps)
            }
        }
    }

    private func openAddApplicationsSheet() {
        let discovered = runningApplications(excluding: Set(customSettings.map(identityKey(for:))))
        addSheet = AddSheetState(apps: discovered)
    }

    private func appendApplications(_ apps: [SelectableApplication]) {
        guard !apps.isEmpty else {
            return
        }

        let existingKeys = Set(customSettings.map(identityKey(for:)))
        let addedSettings = apps
            .filter { app in
                let key = identityKey(for: app.bundleIdentifier, appName: app.name)
                return !existingKeys.contains(key)
            }
            .map {
            CustomAppSetting(
                appName: $0.name,
                bundleIdentifier: $0.bundleIdentifier,
                hideAfter: Defaults[.hideAfter]
            )
        }

        guard !addedSettings.isEmpty else {
            return
        }

        customSettings.append(contentsOf: addedSettings)
        Defaults[.customAppSettings] = customSettings

        if let firstAdded = addedSettings.first {
            selectedBundleIdentifier = firstAdded.bundleIdentifier
        }
    }

    private func removeSelectedApplication() {
        guard let selectedIndex else {
            return
        }

        let removed = customSettings.remove(at: selectedIndex)
        Defaults[.customAppSettings] = customSettings
        NotificationCenter.default.post(
            name: .userDidUpdateAppSetting,
            object: nil,
            userInfo: [
                "appIdentifier": removed.bundleIdentifier,
                "appName": removed.appName,
            ]
        )

        selectedBundleIdentifier = customSettings.first?.bundleIdentifier
    }

    private func updateSelectedHideAfter(withSliderValue sliderValue: Double) {
        guard let selectedIndex, let option = HideAfterOptions.option(forSliderValue: sliderValue) else {
            return
        }

        if customSettings[selectedIndex].hideAfter != option.hideAfter {
            customSettings[selectedIndex].hideAfter = option.hideAfter
            Defaults[.customAppSettings] = customSettings

            let app = customSettings[selectedIndex]
            NotificationCenter.default.post(
                name: .userDidUpdateAppSetting,
                object: nil,
                userInfo: [
                    "appIdentifier": app.bundleIdentifier,
                    "appName": app.appName,
                ]
            )
        }
    }

    private func runningApplications(excluding excludedIdentities: Set<String>) -> [SelectableApplication] {
        discoverRunningApplications(excluding: excludedIdentities)
    }

    private func discoverRunningApplications(excluding excludedIdentities: Set<String>) -> [SelectableApplication] {
        var uniqueAppsByIdentity: [String: SelectableApplication] = [:]
        let runningApps = NSWorkspace.shared.runningApplications
            .filter { app in
                app.activationPolicy == .regular && !isAgentStyleBundle(app)
            }

        for app in runningApps {
            let name = app.localizedName ?? app.bundleIdentifier ?? "Process \(app.processIdentifier)"
            guard !name.isEmpty else {
                continue
            }

            guard shouldIncludeRunningApp(name: name, bundleIdentifier: app.bundleIdentifier) else {
                continue
            }

            guard let bundleIdentifier = app.bundleIdentifier, !bundleIdentifier.isEmpty else {
                continue
            }
            let appIdentity = identityKey(for: bundleIdentifier, appName: name)
            guard !excludedIdentities.contains(appIdentity) else {
                continue
            }

            uniqueAppsByIdentity[appIdentity] = SelectableApplication(name: name, bundleIdentifier: bundleIdentifier)
        }

        return uniqueAppsByIdentity.values.sorted {
            $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
    }

    private func shouldIncludeRunningApp(name: String, bundleIdentifier: String?) -> Bool {
        if name == "Dissolv" {
            return false
        }

        let lowerName = name.lowercased()
        let compactName = lowerName.replacingOccurrences(of: " ", with: "")
        let helperNameTokens = [
            "helper",
            "agent",
            "launcher",
            "daemon",
            "updater",
            "plugin",
            "loginitem",
            "menubar",
            "menuextra",
            "statusitem",
        ]
        if helperNameTokens.contains(where: { compactName.contains($0) }) {
            return false
        }

        guard let bundleIdentifier else {
            return true
        }

        let lowerBundleID = bundleIdentifier.lowercased()
        let helperBundleTokens = [
            ".helper",
            ".agent",
            ".launcher",
            ".daemon",
            ".updater",
            ".plugin",
            ".loginitem",
            ".login-item",
            ".menubar",
            ".menuextra",
            ".statusitem",
            ".status-item",
        ]
        return !helperBundleTokens.contains(where: { lowerBundleID.contains($0) })
    }

    private func isAgentStyleBundle(_ app: NSRunningApplication) -> Bool {
        guard let bundleURL = app.bundleURL, let bundle = Bundle(url: bundleURL) else {
            return false
        }

        let isUIElement = bundle.object(forInfoDictionaryKey: "LSUIElement") as? Bool ?? false
        let isBackgroundOnly = bundle.object(forInfoDictionaryKey: "LSBackgroundOnly") as? Bool ?? false
        return isUIElement || isBackgroundOnly
    }

    private func identityKey(for setting: CustomAppSetting) -> String {
        identityKey(for: setting.bundleIdentifier, appName: setting.appName)
    }

    private func identityKey(for bundleIdentifier: String, appName: String) -> String {
        if bundleIdentifier == appName {
            return "name:\(appName)"
        }

        return "bundle:\(bundleIdentifier)"
    }
}

private struct AddSheetState: Identifiable {
    let id = UUID()
    let apps: [SelectableApplication]
}

private enum Layout {
    static let sectionLabelWidth: CGFloat = 170
    static let fieldLabelWidth: CGFloat = 80
    static let appListWidth: CGFloat = 220
    static let editorHeight: CGFloat = 220
    static let paneCornerRadius: CGFloat = 10
    static let paneBorderWidth: CGFloat = 1
    static let paneBorderOpacity: Double = 0.22
}

private struct AddApplicationsSheet: View {
    let apps: [SelectableApplication]
    let onAdd: ([SelectableApplication]) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selectedBundleIdentifiers = Set<String>()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Add Applications")
                .font(.headline)

            if apps.isEmpty {
                Text("No running applications found.")
                    .foregroundStyle(.secondary)
            } else {
                List(apps, id: \.bundleIdentifier) { app in
                    Toggle(isOn: binding(for: app.bundleIdentifier)) {
                        Text(app.name)
                    }
                    .toggleStyle(.checkbox)
                }
                .frame(minWidth: 360, minHeight: 260)
            }

            HStack {
                Spacer()

                Button("Cancel") {
                    dismiss()
                }

                Button("Add") {
                    let selectedApps = apps.filter { selectedBundleIdentifiers.contains($0.bundleIdentifier) }
                    onAdd(selectedApps)
                    dismiss()
                }
                .disabled(selectedBundleIdentifiers.isEmpty)
            }
        }
        .padding(16)
    }

    private func binding(for bundleIdentifier: String) -> Binding<Bool> {
        Binding(
            get: { selectedBundleIdentifiers.contains(bundleIdentifier) },
            set: { isSelected in
                if isSelected {
                    selectedBundleIdentifiers.insert(bundleIdentifier)
                } else {
                    selectedBundleIdentifiers.remove(bundleIdentifier)
                }
            }
        )
    }
}
