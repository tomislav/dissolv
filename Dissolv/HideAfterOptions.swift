import Foundation

struct HideAfterOption: Equatable {
    let upperBound: Double
    let snappedSliderValue: Double
    let hideAfter: Double
    let label: String
}

enum HideAfterOptions {
    static let unknownLabel = "Unknown"

    private static let options: [HideAfterOption] = [
        HideAfterOption(upperBound: 0.5, snappedSliderValue: 0, hideAfter: 30, label: "30 seconds"),
        HideAfterOption(upperBound: 1, snappedSliderValue: 0.75, hideAfter: 60, label: "1 minute"),
        HideAfterOption(upperBound: 2, snappedSliderValue: 1.5, hideAfter: 120, label: "2 minutes"),
        HideAfterOption(upperBound: 3, snappedSliderValue: 2.5, hideAfter: 180, label: "3 minutes"),
        HideAfterOption(upperBound: 4, snappedSliderValue: 3.5, hideAfter: 240, label: "4 minutes"),
        HideAfterOption(upperBound: 6, snappedSliderValue: 5, hideAfter: 300, label: "5 minutes"),
        HideAfterOption(upperBound: 8, snappedSliderValue: 7, hideAfter: 600, label: "10 minutes"),
        HideAfterOption(upperBound: 12, snappedSliderValue: 10, hideAfter: 900, label: "15 minutes"),
        HideAfterOption(upperBound: 15, snappedSliderValue: 13.5, hideAfter: 1200, label: "20 minutes"),
        HideAfterOption(upperBound: 17.5, snappedSliderValue: 16.25, hideAfter: 1500, label: "25 minutes"),
        HideAfterOption(upperBound: 22.5, snappedSliderValue: 20, hideAfter: 1800, label: "30 minutes"),
        HideAfterOption(upperBound: 25, snappedSliderValue: 23.75, hideAfter: 35 * 60, label: "35 minutes"),
        HideAfterOption(upperBound: 27.5, snappedSliderValue: 26.25, hideAfter: 40 * 60, label: "40 minutes"),
        HideAfterOption(upperBound: 32.5, snappedSliderValue: 30, hideAfter: 45 * 60, label: "45 minutes"),
        HideAfterOption(upperBound: 35, snappedSliderValue: 33.75, hideAfter: 50 * 60, label: "50 minutes"),
        HideAfterOption(upperBound: 37.5, snappedSliderValue: 36.25, hideAfter: 55 * 60, label: "55 minutes"),
        HideAfterOption(upperBound: 45, snappedSliderValue: 40, hideAfter: 60 * 60, label: "1 hour"),
        HideAfterOption(upperBound: 55, snappedSliderValue: 50, hideAfter: 2 * 60 * 60, label: "2 hours"),
        HideAfterOption(upperBound: 65, snappedSliderValue: 60, hideAfter: 3 * 60 * 60, label: "3 hours"),
        HideAfterOption(upperBound: 75, snappedSliderValue: 70, hideAfter: 4 * 60 * 60, label: "4 hours"),
        HideAfterOption(upperBound: 85, snappedSliderValue: 80, hideAfter: 5 * 60 * 60, label: "5 hours"),
        HideAfterOption(upperBound: 95, snappedSliderValue: 90, hideAfter: 6 * 60 * 60, label: "6 hours"),
        HideAfterOption(upperBound: 100, snappedSliderValue: 100, hideAfter: 0, label: "Never"),
    ]

    static func option(forSliderValue sliderValue: Double) -> HideAfterOption? {
        guard (0...100).contains(sliderValue) else {
            return nil
        }

        return options.first(where: { sliderValue <= $0.upperBound })
    }

    static func option(forHideAfter hideAfter: Double) -> HideAfterOption? {
        options.first(where: { $0.hideAfter == hideAfter })
    }

    static func sliderValue(forHideAfter hideAfter: Double) -> Double? {
        option(forHideAfter: hideAfter)?.snappedSliderValue
    }

    static func label(forHideAfter hideAfter: Double) -> String {
        option(forHideAfter: hideAfter)?.label ?? unknownLabel
    }
}
