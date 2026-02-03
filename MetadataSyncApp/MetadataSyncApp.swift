import SwiftUI

@main
struct MetadataSyncApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            MainView()
                .environment(\.managedObjectContext, persistenceController.viewContext)
        }
        .windowStyle(.automatic)
        .defaultSize(width: 1200, height: 800)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Add Directory...") {
                    NotificationCenter.default.post(name: .addDirectory, object: nil)
                }
                .keyboardShortcut("o", modifiers: [.command])
            }
        }
    }
}

extension Notification.Name {
    static let addDirectory = Notification.Name("addDirectory")
}
