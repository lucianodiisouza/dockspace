import SwiftUI
import AppKit
import DockspaceCore

/// Small inline view that captures a key combination from the user
/// and reports the resulting `Hotkey` via a binding. Tapping the
/// button makes the next keystroke the new binding.
struct HotkeyRecorderView: View {
    @Binding var hotkey: Hotkey?
    @State private var isRecording = false

    var body: some View {
        HStack(spacing: 8) {
            if let current = hotkey {
                Text(current.displayString)
                    .font(.system(.body, design: .monospaced))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.secondary.opacity(0.15), in: RoundedRectangle(cornerRadius: 6))
                Button("Change") { isRecording = true }
                Button("Clear") {
                    hotkey = nil
                }
            } else {
                Text("None")
                    .foregroundStyle(.secondary)
                Button("Record") { isRecording = true }
            }
        }
        .sheet(isPresented: $isRecording) {
            RecordingSheet(isPresented: $isRecording) { new in
                hotkey = new
            }
        }
    }
}

private struct RecordingSheet: View {
    @Binding var isPresented: Bool
    var onCapture: (Hotkey) -> Void

    @State private var eventMonitor: Any?
    @State private var status: String = "Press a key combination…"

    var body: some View {
        VStack(spacing: 16) {
            Text("Record hotkey")
                .font(.headline)
            Text(status)
                .font(.callout)
                .foregroundStyle(.secondary)
            HStack {
                Spacer()
                Button("Cancel") {
                    isPresented = false
                }
                .keyboardShortcut(.cancelAction)
            }
        }
        .padding(20)
        .frame(width: 360)
        .onAppear { startMonitoring() }
        .onDisappear { stopMonitoring() }
    }

    private func startMonitoring() {
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            // Escape cancels.
            if event.keyCode == 0x35 {
                isPresented = false
                return nil
            }
            if let hotkey = HotkeyFromNSEvent.hotkey(from: event) {
                onCapture(hotkey)
                isPresented = false
                return nil
            }
            status = "Need at least one modifier (⌘ ⌥ ⌃ ⇧). Try again."
            return nil
        }
    }

    private func stopMonitoring() {
        if let eventMonitor {
            NSEvent.removeMonitor(eventMonitor)
        }
        eventMonitor = nil
    }
}
