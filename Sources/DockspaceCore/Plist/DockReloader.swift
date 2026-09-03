import Foundation

/// Strategy for telling the macOS Dock to re-read its preferences plist
/// after we write to it. Injected into `DockSwapper` so tests can
/// avoid the real `killall` call.
public protocol DockReloader: Sendable {
    func reload() throws
}

/// Production reloader: runs `killall cfprefsd Dock` via `/bin/sh` so
/// the cached preferences daemon flushes and the Dock re-reads the
/// file. Side effect: minimized windows come back to normal (this is
/// the well-known behavior of `killall Dock`).
public struct SystemDockReloader: DockReloader {
    public init() {}

    public func reload() throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/sh")
        process.arguments = ["-c", "killall cfprefsd Dock"]

        let stderr = Pipe()
        process.standardError = stderr
        process.standardOutput = Pipe()

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            throw DockError.dockReloadFailed("failed to launch killall: \(error.localizedDescription)")
        }

        if process.terminationStatus != 0 {
            let data = stderr.fileHandleForReading.readDataToEndOfFile()
            let message = String(data: data, encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines)
            throw DockError.dockReloadFailed(
                "killall exited with \(process.terminationStatus)"
                + (message.map { ": \($0)" } ?? "")
            )
        }
    }
}

/// No-op reloader used in tests. Optionally records how many times
/// `reload` was invoked so tests can assert on it.
public final class NoOpDockReloader: DockReloader, @unchecked Sendable {
    private let lock = NSLock()
    private var _callCount: Int = 0

    public init() {}

    public var callCount: Int {
        lock.lock(); defer { lock.unlock() }
        return _callCount
    }

    public func reload() throws {
        lock.lock()
        _callCount += 1
        lock.unlock()
    }
}
