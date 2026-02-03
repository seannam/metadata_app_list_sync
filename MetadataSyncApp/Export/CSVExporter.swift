import Foundation
import AppKit
import UniformTypeIdentifiers

class CSVExporter {
    func export(items: [FileItem], directoryName: String) -> String {
        var csv = "Name,Path,Type,Size,Created,Modified,Priority,Notes,Git Repo,Has Changes\n"

        let dateFormatter = ISO8601DateFormatter()

        for item in items {
            let name = escapeCSV(item.name ?? "")
            let path = escapeCSV(item.path ?? "")
            let type = item.isDirectory ? "Directory" : "File"
            let size = item.isDirectory ? "" : formatSize(item.fileSize)
            let created = item.createdAt.map { dateFormatter.string(from: $0) } ?? ""
            let modified = item.modifiedAt.map { dateFormatter.string(from: $0) } ?? ""
            let priority = item.priority > 0 ? String(item.priority) : ""
            let notes = escapeCSV(item.notes ?? "")
            let gitRepo = item.isGitRepo ? "Yes" : "No"
            let hasChanges = item.isGitRepo ? (item.hasUncommittedChanges ? "Yes" : "No") : ""

            csv += "\(name),\(path),\(type),\(size),\(created),\(modified),\(priority),\(notes),\(gitRepo),\(hasChanges)\n"
        }

        return csv
    }

    private func escapeCSV(_ string: String) -> String {
        if string.contains(",") || string.contains("\"") || string.contains("\n") {
            return "\"\(string.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return string
    }

    private func formatSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }

    func saveToFile(items: [FileItem], directoryName: String) -> URL? {
        let content = export(items: items, directoryName: directoryName)

        let panel = NSSavePanel()
        panel.allowedContentTypes = [.commaSeparatedText]
        panel.nameFieldStringValue = "\(directoryName)-export.csv"
        panel.message = "Choose where to save the CSV export"

        guard panel.runModal() == .OK, let url = panel.url else {
            return nil
        }

        do {
            try content.write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            print("Error saving CSV: \(error)")
            return nil
        }
    }
}
