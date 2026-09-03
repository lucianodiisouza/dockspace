// DockspaceStorage
//
// Profile persistence + backup. Depends on DockspaceCore for model types.
// Responsibilities:
//   - ProfileStore: CRUD on JSON at
//     ~/Library/Application Support/Dockspace/profiles.json
//   - BackupManager: timestamped snapshots before each Dock swap
//
// Never touches the Dock directly — that's DockspaceCore's job.
