import XCTest

@testable import DockspaceCore

final class FocusModeMonitorTests: XCTestCase {
  /// Stub provider with a single mutable Bool?. Wrapped in a lock so it
  /// is safe to share between the test and the monitor's polling
  /// queue under Swift 6 strict concurrency.
  final class StubProvider: FocusStatusProvider, @unchecked Sendable {
    private let lock = NSLock()
    private var _current: Bool?

    var current: Bool? {
      get {
        lock.lock()
        defer { lock.unlock() }
        return _current
      }
      set {
        lock.lock()
        defer { lock.unlock() }
        _current = newValue
      }
    }

    var isFocused: Bool? { current }
    var isAuthorized: Bool { true }
  }

  /// Thread-safe counter used to assert how many times a handler fires.
  final class InvocationCounter: @unchecked Sendable {
    private let lock = NSLock()
    private var count = 0

    func increment() {
      lock.lock()
      defer { lock.unlock() }
      count += 1
    }

    var value: Int {
      lock.lock()
      defer { lock.unlock() }
      return count
    }
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

    let invocations = InvocationCounter()
    monitor.start { _ in invocations.increment() }

    // Pump the run loop long enough for several ticks.
    let exp = expectation(description: "wait")
    DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) { exp.fulfill() }
    wait(for: [exp], timeout: 1)

    XCTAssertEqual(invocations.value, 0, "handler should not fire when isFocused stays the same")
    monitor.stop()
  }
}
