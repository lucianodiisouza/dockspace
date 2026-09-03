import DockspaceCore
import Foundation

/// Reads and writes the user profile collection to disk.
///
/// Holds a single `ProfilesFile` envelope in memory and persists it
/// atomically on every mutation. Methods are not thread-safe — call
/// them from a single actor (e.g. `@MainActor AppState`).
public final class ProfileStore {
  public let url: URL

  /// Whether the on-disk profiles file existed at the moment this store
  /// was initialized. Lets the caller distinguish a real first launch
  /// (file never written) from a state where the user has deleted every
  /// profile but the file itself still exists.
  public let fileExistedOnLoad: Bool

  private(set) public var file: ProfilesFile

  public init(url: URL) throws {
    self.url = url
    self.fileExistedOnLoad = FileManager.default.fileExists(atPath: url.path)
    if self.fileExistedOnLoad {
      let data = try Data(contentsOf: url)
      let decoder = JSONDecoder()
      self.file = try decoder.decode(ProfilesFile.self, from: data)
    } else {
      self.file = .empty
    }
  }

  /// Persists the current state to disk atomically.
  public func save() throws {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    let data = try encoder.encode(file)
    try data.write(to: url, options: .atomic)
  }

  // MARK: - Profile CRUD

  /// Inserts a new profile and persists. Returns the inserted profile
  /// so callers can grab the assigned id.
  @discardableResult
  public func create(_ profile: Profile) throws -> Profile {
    var copy = profile
    // Defensive: ensure name is non-empty.
    if copy.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
      copy.name = "Untitled"
    }
    file.profiles.append(copy)
    try save()
    return copy
  }

  /// Updates the profile with the same id in place. Throws
  /// `DockError.profileNotFound` if no matching profile exists.
  public func update(_ profile: Profile) throws {
    guard let index = file.profiles.firstIndex(where: { $0.id == profile.id }) else {
      throw DockError.profileNotFound(profile.id.uuidString)
    }
    file.profiles[index] = profile
    try save()
  }

  /// Removes the profile with the given id. No-op if absent. Also
  /// clears `activeProfileId` if it pointed at the removed profile.
  public func delete(id: UUID) throws {
    file.profiles.removeAll { $0.id == id }
    if file.activeProfileId == id {
      file.activeProfileId = nil
    }
    try save()
  }

  public func profile(id: UUID) -> Profile? {
    file.profiles.first { $0.id == id }
  }

  public func setActive(id: UUID?) throws {
    file.activeProfileId = id
    try save()
  }
}
