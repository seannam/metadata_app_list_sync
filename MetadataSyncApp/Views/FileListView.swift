import SwiftUI
import CoreData

struct FileListView: View {
    let directory: TrackedDirectory
    @ObservedObject var viewModel: FileListViewModel

    @FetchRequest private var items: FetchedResults<FileItem>
    @State private var showExportSheet = false

    init(directory: TrackedDirectory, viewModel: FileListViewModel) {
        self.directory = directory
        self.viewModel = viewModel

        _items = FetchRequest(
            sortDescriptors: [viewModel.sortOption.sortDescriptor],
            predicate: NSPredicate(format: "directory == %@", directory),
            animation: .default
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack {
                // Search
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search files...", text: $viewModel.searchText)
                        .textFieldStyle(.plain)
                }
                .padding(8)
                .background(Color(.textBackgroundColor))
                .cornerRadius(8)

                Spacer()

                // Filters
                Toggle("Folders only", isOn: $viewModel.showDirectoriesOnly)
                    .toggleStyle(.checkbox)

                Toggle("Git repos", isOn: $viewModel.showGitReposOnly)
                    .toggleStyle(.checkbox)

                // Sort picker
                Picker("Sort by", selection: $viewModel.sortOption) {
                    ForEach(SortOption.allCases, id: \.self) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 120)

                // Export button
                Button {
                    showExportSheet = true
                } label: {
                    Label("Export", systemImage: "square.and.arrow.up")
                }
            }
            .padding()
            .background(Color(.windowBackgroundColor))

            Divider()

            // File list
            List(filteredItems, id: \.self, selection: $viewModel.selectedItem) { item in
                FileRow(item: item)
                    .tag(item)
                    .contextMenu {
                        Button("Open in Finder") {
                            viewModel.openInFinder(item)
                        }

                        if item.isDirectory {
                            Button("Open in Terminal") {
                                viewModel.openInTerminal(item)
                            }
                        }

                        Divider()

                        Menu("Set Priority") {
                            ForEach(0...5, id: \.self) { priority in
                                Button(priority == 0 ? "None" : String(repeating: "★", count: priority)) {
                                    viewModel.updatePriority(item, priority: Int16(priority))
                                }
                            }
                        }
                    }
            }
            .listStyle(.inset)

            // Status bar
            HStack {
                Text("\(filteredItems.count) items")
                    .foregroundColor(.secondary)

                Spacer()

                if let directory = directory as TrackedDirectory?, let lastScanned = directory.lastScannedAt {
                    Text("Last scanned: \(lastScanned.formatted(date: .abbreviated, time: .shortened))")
                        .foregroundColor(.secondary)
                }
            }
            .font(.caption)
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(.windowBackgroundColor))
        }
        .navigationTitle(directory.name ?? "Files")
        .sheet(isPresented: $showExportSheet) {
            ExportOptionsSheet(directory: directory, items: filteredItems)
        }
    }

    private var filteredItems: [FileItem] {
        var result = Array(items)

        if !viewModel.searchText.isEmpty {
            result = result.filter { ($0.name ?? "").localizedCaseInsensitiveContains(viewModel.searchText) }
        }

        if viewModel.showDirectoriesOnly {
            result = result.filter { $0.isDirectory }
        }

        if viewModel.showGitReposOnly {
            result = result.filter { $0.isGitRepo }
        }

        return result
    }
}

struct FileRow: View {
    @ObservedObject var item: FileItem

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: item.isDirectory ? "folder.fill" : "doc.fill")
                .foregroundColor(item.isDirectory ? .blue : .gray)
                .frame(width: 24)

            // Name and path
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(item.name ?? "Unknown")
                        .fontWeight(.medium)

                    if item.isGitRepo {
                        GitStatusBadge(hasChanges: item.hasUncommittedChanges)
                    }
                }

                if !item.isDirectory {
                    Text(formattedSize)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Priority
            if item.priority > 0 {
                PriorityBadge(priority: item.priority)
            }

            // Modified date
            if let modified = item.modifiedAt {
                Text(modified.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(width: 80, alignment: .trailing)
            }
        }
        .padding(.vertical, 4)
    }

    private var formattedSize: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: item.fileSize)
    }
}

struct PriorityBadge: View {
    let priority: Int16

    var body: some View {
        HStack(spacing: 2) {
            ForEach(1...Int(priority), id: \.self) { _ in
                Image(systemName: "star.fill")
                    .font(.system(size: 10))
            }
        }
        .foregroundColor(.orange)
    }
}
