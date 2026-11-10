import XCTest

final class LaunchGreetingTests: XCTestCase {
    func testTheWelcomeWinsOverThePromo() {
        XCTAssertEqual(LaunchGreeting.decide(showWelcome: true, hasUsedApp: false, promoAvailable: true), .welcome)
    }

    func testThePromoWaitsUntilAnAppleTVIsPaired() {
        XCTAssertEqual(LaunchGreeting.decide(showWelcome: false, hasUsedApp: false, promoAvailable: true), .nothing)
        XCTAssertEqual(LaunchGreeting.decide(showWelcome: false, hasUsedApp: true, promoAvailable: true), .iPhonePromo)
    }

    func testNothingOnceThePromoIsDismissedOrInTheAppStoreBuild() {
        XCTAssertEqual(LaunchGreeting.decide(showWelcome: false, hasUsedApp: true, promoAvailable: false), .nothing)
    }
}
