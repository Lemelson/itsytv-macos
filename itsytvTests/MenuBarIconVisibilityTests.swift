import XCTest

/// Frames as macOS reports them on a 16" MacBook Pro (1728 × 1117 pt): the notch spans x 771–957 of
/// the menu bar, the menu bar is the top 37 pt.
final class MenuBarIconVisibilityTests: XCTestCase {
    private let screen = CGRect(x: 0, y: 0, width: 1728, height: 1117)
    private let leftOfNotch = CGRect(x: 0, y: 1080, width: 771, height: 37)
    private let rightOfNotch = CGRect(x: 957, y: 1080, width: 771, height: 37)
    private var notchGap: CGRect? { MenuBarIconVisibility.notchGap(left: leftOfNotch, right: rightOfNotch) }

    func testNotchGapLiesBetweenTheAreasEitherSideOfIt() {
        XCTAssertEqual(notchGap, CGRect(x: 771, y: 1080, width: 186, height: 37))
    }

    func testNoNotchWithoutBothAreas() {
        XCTAssertNil(MenuBarIconVisibility.notchGap(left: nil, right: rightOfNotch))
        XCTAssertNil(MenuBarIconVisibility.notchGap(left: leftOfNotch, right: nil))
    }

    func testIconRightOfTheNotchIsVisible() {
        let icon = CGRect(x: 1400, y: 1080, width: 24, height: 37)
        XCTAssertFalse(MenuBarIconVisibility.isHidden(windowVisible: true, iconFrame: icon, screenFrame: screen, notchGap: notchGap))
    }

    func testIconPushedIntoTheNotchIsHidden() {
        let icon = CGRect(x: 850, y: 1080, width: 24, height: 37)
        XCTAssertTrue(MenuBarIconVisibility.isHidden(windowVisible: true, iconFrame: icon, screenFrame: screen, notchGap: notchGap))
    }

    func testIconTouchingTheNotchEdgeIsVisible() {
        let icon = CGRect(x: 957, y: 1080, width: 24, height: 37)
        XCTAssertFalse(MenuBarIconVisibility.isHidden(windowVisible: true, iconFrame: icon, screenFrame: screen, notchGap: notchGap))
    }

    func testIconWhoseWindowLostVisibleIsHidden() {
        let icon = CGRect(x: 1400, y: 1080, width: 24, height: 37)
        XCTAssertTrue(MenuBarIconVisibility.isHidden(windowVisible: false, iconFrame: icon, screenFrame: screen, notchGap: notchGap))
    }

    func testIconOffTheLeftEdgeIsHidden() {
        let icon = CGRect(x: -30, y: 1080, width: 24, height: 37)
        XCTAssertTrue(MenuBarIconVisibility.isHidden(windowVisible: true, iconFrame: icon, screenFrame: screen, notchGap: nil))
    }

    func testIconWithoutAWindowIsHidden() {
        XCTAssertTrue(MenuBarIconVisibility.isHidden(windowVisible: true, iconFrame: nil, screenFrame: screen, notchGap: nil))
    }

    func testIconOnAScreenWithoutANotchIsVisible() {
        let icon = CGRect(x: 850, y: 1080, width: 24, height: 37)
        XCTAssertFalse(MenuBarIconVisibility.isHidden(windowVisible: true, iconFrame: icon, screenFrame: screen, notchGap: nil))
    }

    func testFallbackSitsTopCentreUnderTheMenuBar() {
        let visible = CGRect(x: 0, y: 0, width: 1728, height: 1080)
        XCTAssertEqual(MenuBarIconVisibility.fallbackTopLeft(visibleFrame: visible, width: 260), CGPoint(x: 734, y: 1080))
    }
}
