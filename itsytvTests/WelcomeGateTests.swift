import XCTest

final class WelcomeGateTests: XCTestCase {
    private var defaults: UserDefaults!
    private let suite = "itsytv.tests.welcome"

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: suite)
        defaults.removePersistentDomain(forName: suite)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suite)
        super.tearDown()
    }

    private func gate() -> WelcomeGate { WelcomeGate(defaults: defaults) }

    func testANewUserSeesTheWelcomeOnceWhenTheIconIsVisible() {
        XCTAssertTrue(gate().shouldShow(hasUsedApp: false, iconHidden: false, inDock: false))
        XCTAssertFalse(gate().shouldShow(hasUsedApp: false, iconHidden: false, inDock: false))
    }

    func testItComesBackWhileTheIconIsHiddenAndNothingIsPaired() {
        XCTAssertTrue(gate().shouldShow(hasUsedApp: false, iconHidden: true, inDock: false))
        XCTAssertTrue(gate().shouldShow(hasUsedApp: false, iconHidden: true, inDock: false))
    }

    func testNotOnceItsInTheDock() {
        XCTAssertTrue(gate().shouldShow(hasUsedApp: false, iconHidden: true, inDock: false))
        XCTAssertFalse(gate().shouldShow(hasUsedApp: false, iconHidden: true, inDock: true))
    }

    func testNotOnceAnAppleTVIsPaired() {
        XCTAssertTrue(gate().shouldShow(hasUsedApp: false, iconHidden: true, inDock: false))
        XCTAssertFalse(gate().shouldShow(hasUsedApp: true, iconHidden: true, inDock: false))
    }

    func testSomeoneUpdatingWhoAlreadyUsesTheAppNeverSeesIt() {
        XCTAssertFalse(gate().shouldShow(hasUsedApp: true, iconHidden: false, inDock: false))
        XCTAssertFalse(gate().shouldShow(hasUsedApp: true, iconHidden: true, inDock: false))
    }
}
