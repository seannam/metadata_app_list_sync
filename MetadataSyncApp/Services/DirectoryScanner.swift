import Foundation
import CoreData

class DirectoryScanner {
    private let persistenceController: PersistenceController
    private let gitService: GitStatusService
    private let batchSize = 50

    init(persistenceController: PersistenceController = .shared) {
        self.persistenceController = persistenceController
        self.gitService = GitStatusService()
    }

    struct ScanProgress {
        let current: Int
        let total: Int
        let currentPath: String
    }

    func scanDirectory(
        _ directory: TrackedDirectory,
        progressHandler: ((ScanProgress) -> Void)? = nil
    ) async throws {
        let backgroundContext = persistenceController.newBackgroundContext()
        let directoryID = directory.objectID

        try await backgroundContext.perform {
            guard let dir = try? backgroundContext.existingObject(with: directoryID) as? TrackedDirectory,
                  let path = dir.path else {
                return
            }

            let fileManager = FileManager.default
            let directoryURL = URL(fileURLWithPath: path)

            // Get immediate children only (don't recurse)
            let urls: [URL]
            do {
                urls = try fileManager.contentsOfDirectory(
                    at: directoryURL,
                    includingPropertiesForKeys: [
                        .nameKey, .isDirectoryKey, .fileSizeKey,
                        .creationDateKey, .contentModificationDateKey, .contentAccessDateKey
                    ],
                    options: [.skipsHiddenFiles]
                )
            } catch {
                return
            }

            // Get existing items for this directory
            let fetchRequest: NSFetchRequest<FileItem> = FileItem.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "directory == %@", dir)
            let existingItems = try backgroundContext.fetch(fetchRequest)
            var existingItemsByPath = Dictionary(uniqueKeysWithValues: existingItems.compactMap { item -> (String, FileItem)? in
                guard let path = item.path else { return nil }
                return (path, item)
            })

            // Get max displayOrder for assigning to new items
            var maxDisplayOrder = existingItems.map { $0.displayOrder }.max() ?? -1

            let total = urls.count
            var processedPaths = Set<String>()

            for (index, url) in urls.enumerated() {
                let itemPath = url.path
                processedPaths.insert(itemPath)

                let resourceValues = try? url.resourceValues(forKeys: [
                    .nameKey, .isDirectoryKey, .fileSizeKey,
                    .creationDateKey, .contentModificationDateKey, .contentAccessDateKey
                ])

                let fileItem: FileItem
                if let existing = existingItemsByPath[itemPath] {
                    fileItem = existing
                    existingItemsByPath.removeValue(forKey: itemPath)
                } else {
                    fileItem = FileItem(context: backgroundContext)
                    fileItem.id = UUID()
                    fileItem.path = itemPath
                    fileItem.directory = dir
                    maxDisplayOrder += 1
                    fileItem.displayOrder = maxDisplayOrder
                }

                fileItem.name = resourceValues?.name ?? url.lastPathComponent
                fileItem.isDirectory = resourceValues?.isDirectory ?? false
                fileItem.fileSize = Int64(resourceValues?.fileSize ?? 0)
                fileItem.createdAt = resourceValues?.creationDate
                fileItem.modifiedAt = resourceValues?.contentModificationDate
                fileItem.accessedAt = resourceValues?.contentAccessDate

                // Check git status for directories
                if fileItem.isDirectory {
                    let gitStatus = self.gitService.checkGitStatus(at: url)
                    fileItem.isGitRepo = gitStatus.isGitRepo
                    fileItem.hasUncommittedChanges = gitStatus.hasUncommittedChanges
                }

                if index % self.batchSize == 0 {
                    try backgroundContext.save()
                    DispatchQueue.main.async {
                        progressHandler?(ScanProgress(current: index, total: total, currentPath: itemPath))
                    }
                }
            }

            // Delete items that no longer exist
            for (_, item) in existingItemsByPath {
                backgroundContext.delete(item)
            }

            dir.lastScannedAt = Date()
            try backgroundContext.save()

            DispatchQueue.main.async {
                progressHandler?(ScanProgress(current: total, total: total, currentPath: "Complete"))
            }
        }
    }

    func updateItem(at path: String, in directory: TrackedDirectory) async throws {
        let backgroundContext = persistenceController.newBackgroundContext()
        let directoryID = directory.objectID

        try await backgroundContext.perform {
            guard let dir = try? backgroundContext.existingObject(with: directoryID) as? TrackedDirectory else {
                return
            }

            let url = URL(fileURLWithPath: path)
            let fileManager = FileManager.default

            let fetchRequest: NSFetchRequest<FileItem> = FileItem.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "path == %@ AND directory == %@", path, dir)
            let existingItems = try backgroundContext.fetch(fetchRequest)

            if fileManager.fileExists(atPath: path) {
                let resourceValues = try? url.resourceValues(forKeys: [
                    .nameKey, .isDirectoryKey, .fileSizeKey,
                    .creationDateKey, .contentModificationDateKey, .contentAccessDateKey
                ])

                let fileItem: FileItem
                if let existing = existingItems.first {
                    fileItem = existing
                } else {
                    // Fetch max displayOrder for the directory
                    let orderFetch: NSFetchRequest<FileItem> = FileItem.fetchRequest()
                    orderFetch.predicate = NSPredicate(format: "directory == %@", dir)
                    let allItems = try backgroundContext.fetch(orderFetch)
                    let maxOrder = allItems.map { $0.displayOrder }.max() ?? -1

                    fileItem = FileItem(context: backgroundContext)
                    fileItem.id = UUID()
                    fileItem.path = path
                    fileItem.directory = dir
                    fileItem.displayOrder = maxOrder + 1
                }

                fileItem.name = resourceValues?.name ?? url.lastPathComponent
                fileItem.isDirectory = resourceValues?.isDirectory ?? false
                fileItem.fileSize = Int64(resourceValues?.fileSize ?? 0)
                fileItem.createdAt = resourceValues?.creationDate
                fileItem.modifiedAt = resourceValues?.contentModificationDate
                fileItem.accessedAt = resourceValues?.contentAccessDate

                if fileItem.isDirectory {
                    let gitStatus = self.gitService.checkGitStatus(at: url)
                    fileItem.isGitRepo = gitStatus.isGitRepo
                    fileItem.hasUncommittedChanges = gitStatus.hasUncommittedChanges
                }
            } else {
                // File was deleted
                for item in existingItems {
                    backgroundContext.delete(item)
                }
            }

            try backgroundContext.save()
        }
    }
}
