import SwiftUI
import Defaults
import LaunchAtLogin
import KeyboardShortcuts

struct GeneralSettingsView: View {
    @State private var launchAtLoginEnabled = LaunchAtLogin.isEnabled
    @State private var hideAfter = Defaults[.hideAfter]
    @State private var sliderValue = HideAfterOptions.sliderValue(forHideAfter: Defaults[.hideAfter]) ?? 0
    private let sliderMarkers = ["30 sec", "30 min", "1 hr", "3 hrs", "6 hrs", "Never"]

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .top, spacing: 16) {
                Text("System:")
                    .font(.body.weight(.semibold))
                    .frame(width: Layout.sectionLabelWidth, alignment: .trailing)

                VStack(alignment: .leading, spacing: 12) {
                    Toggle("Launch at login", isOn: Binding(
                        get: { launchAtLoginEnabled },
                        set: { newValue in
                            launchAtLoginEnabled = newValue
                            LaunchAtLogin.isEnabled = newValue
                        }
                    ))
                    .toggleStyle(.checkbox)

                    HStack(alignment: .center, spacing: 10) {
                        Text("Pause hiding:")
                            .frame(width: Layout.fieldLabelWidth, alignment: .trailing)
                        KeyboardShortcuts.Recorder(for: .togglePause)
                            .frame(width: Layout.shortcutRecorderWidth, alignment: .leading)
                    }
                }

                Spacer(minLength: 0)
            }

            Divider()

            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .firstTextBaseline, spacing: 16) {
                    Text("Hide applications after:")
                        .font(.body.weight(.semibold))
                        .frame(width: Layout.sectionLabelWidth, alignment: .trailing)
                    Text(HideAfterOptions.label(forHideAfter: hideAfter))
                        .font(.body.weight(.medium))
                }

                Slider(value: Binding(
                    get: { sliderValue },
                    set: { newValue in
                        sliderValue = newValue

                        guard let option = HideAfterOptions.option(forSliderValue: newValue) else {
                            return
                        }

                        hideAfter = option.hideAfter
                        sliderValue = option.snappedSliderValue
                        Defaults[.hideAfter] = option.hideAfter
                    }
                ), in: 0...100)
                .accessibilityLabel("Hide applications after")

                HStack(spacing: 0) {
                    ForEach(Array(sliderMarkers.enumerated()), id: \.offset) { index, label in
                        Text(label)
                            .frame(
                                maxWidth: .infinity,
                                alignment: index == 0
                                    ? .leading
                                    : (index == sliderMarkers.count - 1 ? .trailing : .center)
                            )
                    }
                }
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(24)
    }
}

private enum Layout {
    static let sectionLabelWidth: CGFloat = 170
    static let fieldLabelWidth: CGFloat = 100
    static let shortcutRecorderWidth: CGFloat = 210
}
