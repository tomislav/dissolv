import XCTest
@testable import Dissolv

final class HideAfterOptionsTests: XCTestCase {
    func testSliderValueMapsToExpectedHideAfterOption() {
        let option = HideAfterOptions.option(forSliderValue: 26.5)

        XCTAssertEqual(option?.hideAfter, 40 * 60)
        XCTAssertEqual(option?.snappedSliderValue, 26.25)
        XCTAssertEqual(option?.label, "40 minutes")
    }

    func testHideAfterLabelAndSliderValueAreConsistent() {
        XCTAssertEqual(HideAfterOptions.label(forHideAfter: 0), "Never")
        XCTAssertEqual(HideAfterOptions.sliderValue(forHideAfter: 0), 100)
        XCTAssertEqual(HideAfterOptions.label(forHideAfter: 999), HideAfterOptions.unknownLabel)
        XCTAssertNil(HideAfterOptions.sliderValue(forHideAfter: 999))
    }
}
