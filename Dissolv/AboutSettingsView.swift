import AppKit
import SwiftUI

struct AboutSettingsView: View {
    @State private var showingAcknowledgements = false

    private var versionLabel: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
        return "v\(version) (\(build))"
    }

    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 8) {
                Text("Dissolv")
                    .font(.title3.weight(.semibold))
                    .frame(maxWidth: .infinity, alignment: .center)

                Text(versionLabel)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)

                Text("Copyright 2020-2026 7sols")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
            }

            HStack(spacing: 10) {
                Button("Contact Us") {
                    guard let url = URL(string: "mailto:support+dissolv@7sols.com") else {
                        return
                    }

                    NSWorkspace.shared.open(url)
                }

                Button("Website") {
                    guard let url = URL(string: "https://www.7sols.com/dissolv") else {
                        return
                    }

                    NSWorkspace.shared.open(url)
                }

                Button("Acknowledgements") {
                    showingAcknowledgements = true
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(24)
        .sheet(isPresented: $showingAcknowledgements) {
            AcknowledgementsSheet()
        }
    }
}

private struct AcknowledgementsSheet: View {
    @Environment(\.dismiss) private var dismiss

    private var attributedContent: AttributedString {
        guard
            let rtfFile = Bundle.main.url(forResource: "Acknowledgements", withExtension: "rtf"),
            let data = try? Data(contentsOf: rtfFile),
            let nsAttributedString = try? NSAttributedString(
                data: data,
                options: [.documentType: NSAttributedString.DocumentType.rtf],
                documentAttributes: nil
            )
        else {
            return AttributedString("Acknowledgements could not be loaded.")
        }

        return AttributedString(nsAttributedString)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Acknowledgements")
                .font(.headline)

            ScrollView {
                Text(attributedContent)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(minWidth: 500, minHeight: 320)

            HStack {
                Spacer()
                Button("Close") {
                    dismiss()
                }
            }
        }
        .padding(16)
    }
}
