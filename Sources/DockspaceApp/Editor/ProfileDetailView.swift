import DockspaceCore
import SwiftUI

/// Editor for a single profile. Lets the user rename, recolor, reorder
/// items, edit labels, add apps/files/URLs/spacers, and delete items.
@MainActor
struct ProfileDetailView: View {
  @Environment(AppState.self) private var state
  let profileID: UUID

  @State private var draft: Profile?
  @State private var editingItemIndex: Int?
  @State private var editingLabel: String = ""
  @State private var showingAppPicker = false
  @State private var showingFilePicker = false
  @State private var showingURLPicker = false

  var body: some View {
    Group {
      if let draft {
        Form {
          Section("Info") {
            TextField(
              "Name",
              text: Binding(
                get: { draft.name },
                set: { newValue in
                  var copy = draft
                  copy.name = newValue
                  self.draft = copy
                }
              ))
            Picker(
              "Color",
              selection: Binding(
                get: { draft.color },
                set: { newValue in
                  var copy = draft
                  copy.color = newValue
                  self.draft = copy
                }
              )
            ) {
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
              itemRow(item: item, index: index)
            }
            .onMove(perform: moveItems)

            HStack {
              Menu {
                Button("App…") { showingAppPicker = true }
                Button("File or Folder…") { showingFilePicker = true }
                Button("URL…") { showingURLPicker = true }
                Divider()
                ForEach(SpacerVariant.allCases, id: \.self) { variant in
                  Button(spacerLabel(variant)) {
                    insertSpacer(variant)
                  }
                }
              } label: {
                Label("Add item", systemImage: "plus")
              }
              Spacer()
            }
          }

          Section("Hotkey") {
            HotkeyRecorderView(
              hotkey: Binding(
                get: { draft.hotkey },
                set: { newValue in
                  var copy = draft
                  copy.hotkey = newValue
                  self.draft = copy
                }
              ))
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
    .sheet(isPresented: $showingFilePicker) {
      AddFileSheet { fileEntry in
        insertFile(fileEntry)
      }
    }
    .sheet(isPresented: $showingURLPicker) {
      AddURLSheet { urlEntry in
        insertURL(urlEntry)
      }
    }
  }

  // MARK: - Item rows

  @ViewBuilder
  private func itemRow(item: DockItem, index: Int) -> some View {
    HStack(spacing: 10) {
      ItemIconView(item: item)
      if editingItemIndex == index, canEditLabel(item) {
        TextField("Label", text: $editingLabel)
          .textFieldStyle(.roundedBorder)
          .onSubmit { commitLabelEdit() }
        Button("Save") { commitLabelEdit() }
          .buttonStyle(.borderless)
        Button("Cancel") { cancelLabelEdit() }
          .buttonStyle(.borderless)
      } else {
        VStack(alignment: .leading, spacing: 2) {
          Text(item.displayName)
            .lineLimit(1)
          if let subtitle = itemSubtitle(item) {
            Text(subtitle)
              .font(.caption2)
              .foregroundStyle(.secondary)
              .lineLimit(1)
          }
        }
        Spacer()
        if canEditLabel(item) {
          Button {
            beginLabelEdit(at: index, current: item.displayName)
          } label: {
            Image(systemName: "pencil")
          }
          .buttonStyle(.borderless)
          .help("Rename")
        }
        Button {
          removeItem(at: index)
        } label: {
          Image(systemName: "minus.circle")
        }
        .buttonStyle(.borderless)
        .help("Remove")
      }
    }
    .contextMenu {
      if canEditLabel(item) {
        Button("Rename") {
          beginLabelEdit(at: index, current: item.displayName)
        }
      }
      Button("Remove", role: .destructive) {
        removeItem(at: index)
      }
    }
  }

  private func itemSubtitle(_ item: DockItem) -> String? {
    switch item {
    case .app(let entry):
      return entry.path
    case .file(let entry):
      return entry.path
    case .url(let entry):
      return entry.url
    case .spacer:
      return nil
    }
  }

  private func canEditLabel(_ item: DockItem) -> Bool {
    switch item {
    case .app, .file, .url: return true
    case .spacer: return false
    }
  }

  private func beginLabelEdit(at index: Int, current: String) {
    editingItemIndex = index
    editingLabel = current
  }

  private func commitLabelEdit() {
    guard let index = editingItemIndex, var copy = draft else {
      cancelLabelEdit()
      return
    }
    let trimmed = editingLabel.trimmingCharacters(in: .whitespacesAndNewlines)
    let next: DockItem? = {
      guard copy.items.indices.contains(index) else { return nil }
      let item = copy.items[index]
      switch item {
      case .app(let entry):
        return .app(
          AppEntry(
            path: entry.path,
            bundleIdentifier: entry.bundleIdentifier,
            displayName: trimmed.isEmpty ? nil : trimmed
          ))
      case .file(let entry):
        return .file(
          FileEntry(
            path: entry.path,
            displayName: trimmed.isEmpty ? nil : trimmed,
            isDirectory: entry.isDirectory
          ))
      case .url(let entry):
        return .url(
          URLEntry(
            url: entry.url,
            displayName: trimmed.isEmpty ? nil : trimmed
          ))
      case .spacer:
        return nil
      }
    }()
    if let next {
      copy.items[index] = next
      draft = copy
    }
    cancelLabelEdit()
  }

  private func cancelLabelEdit() {
    editingItemIndex = nil
    editingLabel = ""
  }

  private func spacerLabel(_ variant: SpacerVariant) -> String {
    switch variant {
    case .small: return "Small spacer"
    case .flex: return "Flex spacer"
    case .default: return "Spacer"
    }
  }

  // MARK: - Mutators

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

  private func insertFile(_ entry: FileEntry) {
    guard var copy = draft else { return }
    copy.items.append(.file(entry))
    draft = copy
  }

  private func insertURL(_ entry: URLEntry) {
    guard var copy = draft else { return }
    copy.items.append(.url(entry))
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
    if editingItemIndex == index {
      cancelLabelEdit()
    } else if let editing = editingItemIndex, editing > index {
      editingItemIndex = editing - 1
    }
  }

  private func moveItems(from source: IndexSet, to destination: Int) {
    guard var copy = draft else { return }
    copy.items.move(fromOffsets: source, toOffset: destination)
    draft = copy
    if let editing = editingItemIndex {
      cancelLabelEdit()
      _ = editing
    }
  }
}
