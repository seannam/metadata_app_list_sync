import Foundation
import AppKit
import UniformTypeIdentifiers

class CSVExporter {
    func export(items: [FileItem], directoryName: String) -> String {
        var csv = "Name,Type\n"

        for item in items {
            let name = escapeCSV(item.name ?? "")
            let type = item.isDirectory ? "Directory" : "File"
            csv += "\(name),\(type)\n"
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

        let desktopURL = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first!
        let timestamp = ISO8601DateFormatter().string(from: Date()).replacingOccurrences(of: ":", with: "-")
        let filename = "\(directoryName)-export-\(timestamp).csv"
        let url = desktopURL.appendingPathComponent(filename)

        do {
            try content.write(to: url, atomically: true, encoding: .utf8)
            NSWorkspace.shared.activateFileViewerSelecting([url])
            return url
        } catch {
            print("Error saving CSV: \(error)")
            return nil
        }
    }
}
