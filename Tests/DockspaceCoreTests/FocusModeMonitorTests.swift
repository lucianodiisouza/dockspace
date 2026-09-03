import XCTest
@testable import DockspaceCore

final class FocusModeMonitorTests: XCTestCase {
    final class StubProvider: FocusStatusProvider {
        var current: Bool?
        var isFocused: Bool? { current }
        var isAuthorized: Bool { true }
    }

    func test_tick_invokesHandlerOnTransitionToFocused() {
        let provider = StubProvider()
        provider.current = false
        let monitor = FocusModeMonitor(provider: provider, interval: 0.01)

        let exp = expectation(description: "transition to focused")
        monitor.start { isFocused in
            if isFocused {
                exp.fulfill()
            }
        }
        provider.current = true

        wait(for: [exp], timeout: 1)
        monitor.stop()
    }

    func test_tick_doesNotInvokeWhenValueUnchanged() {
        let provider = StubProvider()
        provider.current = false
        let monitor = FocusModeMonitor(provider: provider, interval: 0.01)

        var invocations = 0
        monitor.start { _ in invocations += 1 }

        // Pump the run loop long enough for several ticks.
        let exp = expectation(description: "wait")
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) { exp.fulfill() }
        wait(for: [exp], timeout: 1)

        XCTAssertEqual(invocations, 0, "handler should not fire when isFocused stays the same")
        monitor.stop()
    }
}
