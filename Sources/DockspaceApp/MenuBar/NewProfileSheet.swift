import SwiftUI
import DockspaceCore

/// Modal sheet for naming a brand new profile. Created profiles start
/// empty; the user adds apps and spacers in the editor after.
@MainActor
struct NewProfileSheet: View {
    @Environment(AppState.self) private var state
    @Environment(\.dismiss) private var dismiss
    @State private var name: String = "Work"
    @State private var color: ProfileColor = .blue

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("New profile")
                .font(.headline)

            Form {
                TextField("Name", text: $name)
                Picker("Color", selection: $color) {
                    ForEach(ProfileColor.allCases, id: \.self) { c in
                        HStack {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(hex: c.hex))
                                .frame(width: 14, height: 14)
                            Text(c.rawValue.capitalized)
                        }
                        .tag(c)
                    }
                }
            }
            .formStyle(.grouped)

            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button("Create") {
                    do {
                        _ = try state.createProfile(name: name, color: color)
                        dismiss()
                    } catch {
                        // Last error is reflected on AppState, nothing
                        // else to do here.
                    }
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(20)
        .frame(width: 360)
    }
}
