import SwiftUI
import CoreData

struct MainView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var directoryVM = DirectoryListViewModel()
    @StateObject private var fileVM = FileListViewModel()

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \TrackedDirectory.name, ascending: true)],
        animation: .default
    )
    private var directories: FetchedResults<TrackedDirectory>

    var body: some View {
        NavigationSplitView {
            SidebarView(
                directories: Array(directories),
                selectedDirectory: $directoryVM.selectedDirectory,
                onAddDirectory: directoryVM.addDirectory,
                onRemoveDirectory: directoryVM.removeDirectory,
                onRescan: { directory in
                    Task {
                        await directoryVM.scanDirectory(directory)
                    }
                }
            )
            .frame(minWidth: 200)
        } content: {
            if let directory = directoryVM.selectedDirectory {
                FileListView(
                    directory: directory,
                    viewModel: fileVM
                )
                .frame(minWidth: 400)
            } else {
                ContentUnavailableView(
                    "Select a Directory",
                    systemImage: "folder",
                    description: Text("Choose a directory from the sidebar or add a new one")
                )
            }
        } detail: {
            if let item = fileVM.selectedItem {
                FileDetailView(item: item, viewModel: fileVM)
                    .frame(minWidth: 300)
            } else {
                ContentUnavailableView(
                    "Select an Item",
                    systemImage: "doc",
                    description: Text("Choose an item to view its details")
                )
            }
        }
        .onAppear {
            directoryVM.startAllMonitors(directories: Array(directories))
        }
        .onDisappear {
            directoryVM.stopAllMonitors()
        }
        .onReceive(NotificationCenter.default.publisher(for: .addDirectory)) { _ in
            directoryVM.addDirectory()
        }
        .overlay {
            if directoryVM.isScanning {
                ScanProgressOverlay(progress: directoryVM.scanProgress)
            }
        }
    }
}

struct ScanProgressOverlay: View {
    let progress: DirectoryScanner.ScanProgress?

    var body: some View {
        ZStack {
            Color.black.opacity(0.3)

            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)

                if let progress = progress {
                    Text("Scanning... \(progress.current)/\(progress.total)")
                        .font(.headline)

                    Text(progress.currentPath)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }
            .padding(32)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        }
    }
}

#Preview {
    MainView()
        .environment(\.managedObjectContext, PersistenceController.shared.viewContext)
}
