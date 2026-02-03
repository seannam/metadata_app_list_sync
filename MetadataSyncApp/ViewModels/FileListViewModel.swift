import Foundation
import CoreData
import SwiftUI

enum SortOption: String, CaseIterable {
    case manual = "Manual"
    case name = "Name"
    case modifiedDate = "Modified"
    case createdDate = "Created"
    case size = "Size"
    case priority = "Priority"

    var sortDescriptor: NSSortDescriptor {
        switch self {
        case .manual:
            return NSSortDescriptor(keyPath: \FileItem.displayOrder, ascending: true)
        case .name:
            return NSSortDescriptor(keyPath: \FileItem.name, ascending: true)
        case .modifiedDate:
            return NSSortDescriptor(keyPath: \FileItem.modifiedAt, ascending: false)
        case .createdDate:
            return NSSortDescriptor(keyPath: \FileItem.createdAt, ascending: false)
        case .size:
            return NSSortDescriptor(keyPath: \FileItem.fileSize, ascending: false)
        case .priority:
            return NSSortDescriptor(keyPath: \FileItem.priority, ascending: false)
        }
    }
}

@MainActor
class FileListViewModel: ObservableObject {
    @Published var sortOption: SortOption = .name
    @Published var searchText: String = ""
    @Published var selectedItem: FileItem?
    @Published var showDirectoriesOnly: Bool = false
    @Published var showGitReposOnly: Bool = false

    private let persistenceController: PersistenceController

    init(persistenceController: PersistenceController = .shared) {
        self.persistenceController = persistenceController
    }

    func predicate(for directory: TrackedDirectory?) -> NSPredicate {
        var predicates: [NSPredicate] = []

        if let directory = directory {
            predicates.append(NSPredicate(format: "directory == %@", directory))
        }

        if !searchText.isEmpty {
            predicates.append(NSPredicate(format: "name CONTAINS[cd] %@", searchText))
        }

        if showDirectoriesOnly {
            predicates.append(NSPredicate(format: "isDirectory == YES"))
        }

        if showGitReposOnly {
            predicates.append(NSPredicate(format: "isGitRepo == YES"))
        }

        if predicates.isEmpty {
            return NSPredicate(value: true)
        }

        return NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
    }

    func updatePriority(_ item: FileItem, priority: Int16) {
        item.priority = priority
        persistenceController.save()
    }

    func updateNotes(_ item: FileItem, notes: String) {
        item.notes = notes.isEmpty ? nil : notes
        persistenceController.save()
    }

    func openInFinder(_ item: FileItem) {
        guard let path = item.path else { return }
        let url = URL(fileURLWithPath: path)
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }

    func openInTerminal(_ item: FileItem) {
        guard let path = item.path else { return }
        let url = item.isDirectory ? URL(fileURLWithPath: path) : URL(fileURLWithPath: path).deletingLastPathComponent()

        let script = """
        tell application "Terminal"
            do script "cd '\(url.path)'"
            activate
        end tell
        """

        if let appleScript = NSAppleScript(source: script) {
            var error: NSDictionary?
            appleScript.executeAndReturnError(&error)
        }
    }

    var isManualSortEnabled: Bool {
        sortOption == .manual
    }

    func moveItems(from source: IndexSet, to destination: Int, in items: inout [FileItem]) {
        guard sortOption == .manual else { return }

        items.move(fromOffsets: source, toOffset: destination)

        for (index, item) in items.enumerated() {
            item.displayOrder = Int32(index)
        }

        persistenceController.save()
    }
}
