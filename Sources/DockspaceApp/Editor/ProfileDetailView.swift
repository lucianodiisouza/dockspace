import SwiftUI
import DockspaceCore

/// Editor for a single profile. Lets the user rename, recolor, reorder
/// items, add apps and spacers, and delete items.
struct ProfileDetailView: View {
    @Environment(AppState.self) private var state
    let profileID: UUID

    @State private var draft: Profile?
    @State private var showingAppPicker = false

    var body: some View {
        Group {
            if let draft {
                Form {
                    Section("Info") {
                        TextField("Name", text: Binding(
                            get: { draft.name },
                            set: { newValue in
                                var copy = draft
                                copy.name = newValue
                                self.draft = copy
                            }
                        ))
                        Picker("Color", selection: Binding(
                            get: { draft.color },
                            set: { newValue in
                                var copy = draft
                                copy.color = newValue
                                self.draft = copy
                            }
                        )) {
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

                    Section("Items") {
                        ForEach(Array(draft.items.enumerated()), id: \.offset) { index, item in
                            HStack {
                                ItemBadgeView(item: item)
                                Text(item.displayName)
                                    .lineLimit(1)
                                Spacer()
                                Button {
                                    removeItem(at: index)
                                } label: {
                                    Image(systemName: "minus.circle")
                                }
                                .buttonStyle(.borderless)
                            }
                        }
                        .onMove(perform: moveItems)

                        HStack {
                            Button {
                                showingAppPicker = true
                            } label: {
                                Label("Add app", systemImage: "plus.app")
                            }
                            Spacer()
                            Menu {
                                ForEach(SpacerVariant.allCases, id: \.self) { variant in
                                    Button(variant.rawValue.replacingOccurrences(of: "-tile", with: "").capitalized) {
                                        insertSpacer(variant)
                                    }
                                }
                            } label: {
                                Label("Add spacer", systemImage: "rectangle.split.3x1")
                            }
                        }
                    }
                }
                .formStyle(.grouped)
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button("Save") { save() }
                            .keyboardShortcut("s", modifiers: .command)
                    }
                }
            } else {
                ProgressView()
            }
        }
        .onAppear { draft = currentProfile() }
        .onChange(of: profileID) { _, _ in draft = currentProfile() }
        .sheet(isPresented: $showingAppPicker) {
            AppPickerView { appEntry in
                insertApp(appEntry)
            }
        }
    }

    private func currentProfile() -> Profile? {
        state.profiles.first { $0.id == profileID }
    }

    private func save() {
        guard let draft else { return }
        try? state.updateProfile(draft)
    }

    private func insertApp(_ entry: AppEntry) {
        guard var copy = draft else { return }
        copy.items.append(.app(entry))
        draft = copy
    }

    private func insertSpacer(_ variant: SpacerVariant) {
        guard var copy = draft else { return }
        copy.items.append(.spacer(variant))
        draft = copy
    }

    private func removeItem(at index: Int) {
        guard var copy = draft, copy.items.indices.contains(index) else { return }
        copy.items.remove(at: index)
        draft = copy
    }

    private func moveItems(from source: IndexSet, to destination: Int) {
        guard var copy = draft else { return }
        copy.items.move(fromOffsets: source, toOffset: destination)
        draft = copy
    }
}

/// Small visual badge for each `DockItem` row inside the detail form.
struct ItemBadgeView: View {
    let item: DockItem

    var body: some View {
        Group {
            switch item {
            case .app:
                Image(systemName: "app.fill")
                    .foregroundStyle(.tint)
            case .spacer:
                Image(systemName: "rectangle.split.3x1")
                    .foregroundStyle(.secondary)
            case .file:
                Image(systemName: "doc")
                    .foregroundStyle(.secondary)
            case .url:
                Image(systemName: "link")
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 22)
    }
}
