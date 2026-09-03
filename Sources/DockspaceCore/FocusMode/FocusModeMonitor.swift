import Foundation
import os

/// Watches `FocusStatusProvider` for transitions and invokes a handler
/// each time `isFocused` flips. Polled because the underlying
/// `INFocusStatusCenter` does not emit KVO notifications on macOS.
public final class FocusModeMonitor: @unchecked Sendable {
    public typealias Handler = @Sendable (_ isFocused: Bool) -> Void

    private let provider: FocusStatusProvider
    private let interval: TimeInterval
    private let logger = Logger(subsystem: "app.dockspace", category: "focus")
    private let queue = DispatchQueue(label: "app.dockspace.focus-monitor", qos: .utility)
    private var timer: DispatchSourceTimer?
    private var lastValue: Bool?
    private var handler: Handler?

    public init(provider: FocusStatusProvider, interval: TimeInterval = 5) {
        self.provider = provider
        self.interval = interval
    }

    public func start(handler: @escaping Handler) {
        stop()
        self.handler = handler
        self.lastValue = provider.isFocused

        let timer = DispatchSource.makeTimerSource(queue: queue)
        timer.schedule(deadline: .now() + interval, repeating: interval)
        timer.setEventHandler { [weak self] in
            self?.tick()
        }
        self.timer = timer
        timer.resume()
        logger.debug("focus monitor started (interval=\(interval, privacy: .public)s)")
    }

    public func stop() {
        timer?.cancel()
        timer = nil
        handler = nil
        logger.debug("focus monitor stopped")
    }

    deinit {
        timer?.cancel()
    }

    private func tick() {
        let current = provider.isFocused
        guard current != lastValue else { return }
        lastValue = current
        if let current, let handler {
            logger.info("focus changed: isFocused=\(current, privacy: .public)")
            handler(current)
        }
    }
}
