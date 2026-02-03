import SwiftUI

struct FileDetailView: View {
    @ObservedObject var item: FileItem
    @ObservedObject var viewModel: FileListViewModel

    @State private var editedNotes: String = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                HStack(spacing: 16) {
                    Image(systemName: item.isDirectory ? "folder.fill" : "doc.fill")
                        .font(.system(size: 48))
                        .foregroundColor(item.isDirectory ? .blue : .gray)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.name ?? "Unknown")
                            .font(.title)
                            .fontWeight(.bold)

                        if let path = item.path {
                            Text(path)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .textSelection(.enabled)
                        }
                    }
                }

                Divider()

                // Git Status
                if item.isGitRepo {
                    GroupBox("Git Repository") {
                        HStack {
                            GitStatusBadge(hasChanges: item.hasUncommittedChanges)

                            Text(item.hasUncommittedChanges ? "Has uncommitted changes" : "Clean working tree")
                                .foregroundColor(item.hasUncommittedChanges ? .orange : .green)

                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                }

                // Metadata
                GroupBox("File Information") {
                    VStack(alignment: .leading, spacing: 12) {
                        MetadataRow(label: "Type", value: item.isDirectory ? "Directory" : "File")

                        if !item.isDirectory {
                            MetadataRow(label: "Size", value: formattedSize)
                        }

                        if let created = item.createdAt {
                            MetadataRow(label: "Created", value: created.formatted(date: .long, time: .shortened))
                        }

                        if let modified = item.modifiedAt {
                            MetadataRow(label: "Modified", value: modified.formatted(date: .long, time: .shortened))
                        }

                        if let accessed = item.accessedAt {
                            MetadataRow(label: "Last Accessed", value: accessed.formatted(date: .long, time: .shortened))
                        }
                    }
                    .padding(.vertical, 4)
                }

                // Priority
                GroupBox("Priority") {
                    VStack(alignment: .leading, spacing: 8) {
                        PriorityPicker(priority: Binding(
                            get: { item.priority },
                            set: { viewModel.updatePriority(item, priority: $0) }
                        ))
                    }
                    .padding(.vertical, 4)
                }

                // Notes
                GroupBox("Notes") {
                    VStack(alignment: .leading, spacing: 8) {
                        TextEditor(text: $editedNotes)
                            .font(.body)
                            .frame(minHeight: 100)
                            .scrollContentBackground(.hidden)
                            .background(Color(.textBackgroundColor))
                            .cornerRadius(4)

                        HStack {
                            Spacer()
                            Button("Save Notes") {
                                viewModel.updateNotes(item, notes: editedNotes)
                            }
                            .disabled(editedNotes == (item.notes ?? ""))
                        }
                    }
                    .padding(.vertical, 4)
                }

                // Actions
                GroupBox("Actions") {
                    HStack(spacing: 12) {
                        Button {
                            viewModel.openInFinder(item)
                        } label: {
                            Label("Show in Finder", systemImage: "folder")
                        }

                        if item.isDirectory {
                            Button {
                                viewModel.openInTerminal(item)
                            } label: {
                                Label("Open in Terminal", systemImage: "terminal")
                            }
                        }

                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
            }
            .padding()
        }
        .onAppear {
            editedNotes = item.notes ?? ""
        }
        .onChange(of: item) { _, newItem in
            editedNotes = newItem.notes ?? ""
        }
    }

    private var formattedSize: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: item.fileSize)
    }
}

struct MetadataRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
                .frame(width: 120, alignment: .leading)

            Text(value)
                .textSelection(.enabled)

            Spacer()
        }
    }
}
