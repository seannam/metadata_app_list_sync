import Foundation
import AppKit
import UniformTypeIdentifiers

class MarkdownExporter {
    func export(items: [FileItem], directoryName: String, directoryPath: String, preserveOrder: Bool = false) -> String {
        var md = "# \(directoryName)\n\n"

        for item in items {
            let icon = item.isDirectory ? "📁" : "📄"
            let name = item.name ?? "Unknown"
            md += "- \(icon) \(name)\n"
        }

        return md
    }

    func saveToFile(items: [FileItem], directoryName: String, directoryPath: String, preserveOrder: Bool = false) -> URL? {
        let content = export(items: items, directoryName: directoryName, directoryPath: directoryPath, preserveOrder: preserveOrder)

        let desktopURL = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first!
        let timestamp = ISO8601DateFormatter().string(from: Date()).replacingOccurrences(of: ":", with: "-")
        let filename = "\(directoryName)-export-\(timestamp).md"
        let url = desktopURL.appendingPathComponent(filename)

        do {
            try content.write(to: url, atomically: true, encoding: .utf8)
            NSWorkspace.shared.activateFileViewerSelecting([url])
            return url
        } catch {
            print("Error saving Markdown: \(error)")
            return nil
        }
    }
}
