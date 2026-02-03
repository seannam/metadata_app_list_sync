import Foundation
import AppKit
import UniformTypeIdentifiers

class MarkdownExporter {
    func export(items: [FileItem], directoryName: String, options: ExportOptions) -> String {
        var lines: [String] = []

        if options.showHeader {
            lines.append("# \(directoryName)")
            lines.append("")
        }

        for item in items {
            var line = ""

            if options.showBullets {
                line += "- "
            }

            if options.showEmojis {
                let icon = item.isDirectory ? "📁 " : "📄 "
                line += icon
            }

            line += item.name ?? "Unknown"
            lines.append(line)
        }

        return lines.joined(separator: "\n")
    }

    func saveToFile(items: [FileItem], directoryName: String, options: ExportOptions) -> URL? {
        let content = export(items: items, directoryName: directoryName, options: options)

        let desktopURL = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first!
        let timestamp = ISO8601DateFormatter().string(from: Date()).replacingOccurrences(of: ":", with: "-")
        let filename = "\(directoryName)-export-\(timestamp).txt"
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
