import SwiftUI

struct SidebarView: View {
    let directories: [TrackedDirectory]
    @Binding var selectedDirectory: TrackedDirectory?
    let onAddDirectory: () -> Void
    let onRemoveDirectory: (TrackedDirectory) -> Void
    let onRescan: (TrackedDirectory) -> Void

    var body: some View {
        List(selection: $selectedDirectory) {
            Section("Tracked Directories") {
                ForEach(directories, id: \.self) { directory in
                    DirectoryRow(directory: directory)
                        .tag(directory)
                        .contextMenu {
                            Button("Rescan") {
                                onRescan(directory)
                            }

                            Button("Open in Finder") {
                                if let path = directory.path {
                                    NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: path)
                                }
                            }

                            Divider()

                            Button("Remove", role: .destructive) {
                                onRemoveDirectory(directory)
                            }
                        }
                }
            }
        }
        .listStyle(.sidebar)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: onAddDirectory) {
                    Label("Add Directory", systemImage: "plus")
                }
            }
        }
        .navigationTitle("Directories")
    }
}

struct DirectoryRow: View {
    @ObservedObject var directory: TrackedDirectory

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: "folder.fill")
                    .foregroundColor(.blue)

                Text(directory.name ?? "Unknown")
                    .fontWeight(.medium)
            }

            if let path = directory.path {
                Text(path)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            if let lastScanned = directory.lastScannedAt {
                Text("Scanned: \(lastScanned.formatted(date: .abbreviated, time: .shortened))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
