import XCTest

final class ReopenActionTests: XCTestCase {
    func testOpenRemoteComesToTheFront() {
        XCTAssertEqual(ReopenAction.decide(remoteIsOpen: true, lastPairedDeviceNearby: "tv-1"), .focusRemote)
    }

    func testPairedAppleTVNearbyOpensItsRemote() {
        XCTAssertEqual(ReopenAction.decide(remoteIsOpen: false, lastPairedDeviceNearby: "tv-1"), .openRemote(deviceID: "tv-1"))
    }

    func testWithoutAPairedAppleTVTheDeviceMenuOpens() {
        XCTAssertEqual(ReopenAction.decide(remoteIsOpen: false, lastPairedDeviceNearby: nil), .showDevices)
    }
}
