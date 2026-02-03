import Foundation
import CoreData
import SwiftUI

@MainActor
class DirectoryListViewModel: ObservableObject {
    @Published var isScanning = false
    @Published var scanProgress: DirectoryScanner.ScanProgress?
    @Published var selectedDirectory: TrackedDirectory?

    private let persistenceController: PersistenceController
    private let scanner: DirectoryScanner
    private var monitors: [String: FileSystemMonitor] = [:]

    init(persistenceController: PersistenceController = .shared) {
        self.persistenceController = persistenceController
        self.scanner = DirectoryScanner(persistenceController: persistenceController)
    }

    func addDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.message = "Select a directory to track"

        panel.begin { [weak self] response in
            guard response == .OK, let url = panel.url else { return }

            Task { @MainActor in
                self?.createTrackedDirectory(at: url)
            }
        }
    }

    private func createTrackedDirectory(at url: URL) {
        let context = persistenceController.viewContext

        // Check if already tracking this path
        let fetchRequest: NSFetchRequest<TrackedDirectory> = TrackedDirectory.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "path == %@", url.path)

        if let existing = try? context.fetch(fetchRequest), !existing.isEmpty {
            return
        }

        let directory = TrackedDirectory(context: context)
        directory.id = UUID()
        directory.path = url.path
        directory.name = url.lastPathComponent
        directory.isActive = true

        persistenceController.save()

        Task {
            await scanDirectory(directory)
            startMonitoring(directory)
        }
    }

    func scanDirectory(_ directory: TrackedDirectory) async {
        isScanning = true
        scanProgress = nil

        do {
            try await scanner.scanDirectory(directory) { [weak self] progress in
                Task { @MainActor in
                    self?.scanProgress = progress
                }
            }
        } catch {
            print("Error scanning directory: \(error)")
        }

        isScanning = false
        scanProgress = nil
    }

    func removeDirectory(_ directory: TrackedDirectory) {
        if let path = directory.path {
            stopMonitoring(path)
        }

        let context = persistenceController.viewContext
        context.delete(directory)
        persistenceController.save()

        if selectedDirectory == directory {
            selectedDirectory = nil
        }
    }

    func startMonitoring(_ directory: TrackedDirectory) {
        guard let path = directory.path else { return }

        let monitor = FileSystemMonitor { [weak self] changedPaths in
            guard let self = self else { return }

            Task {
                for changedPath in changedPaths {
                    // Only process immediate children
                    let parentPath = (changedPath as NSString).deletingLastPathComponent
                    if parentPath == path {
                        try? await self.scanner.updateItem(at: changedPath, in: directory)
                    }
                }
            }
        }

        monitor.startMonitoring(paths: [path])
        monitors[path] = monitor
    }

    func stopMonitoring(_ path: String) {
        monitors[path]?.stopMonitoring()
        monitors.removeValue(forKey: path)
    }

    func startAllMonitors(directories: [TrackedDirectory]) {
        for directory in directories where directory.isActive {
            startMonitoring(directory)
        }
    }

    func stopAllMonitors() {
        for (_, monitor) in monitors {
            monitor.stopMonitoring()
        }
        monitors.removeAll()
    }
}
