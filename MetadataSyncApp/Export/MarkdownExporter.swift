import Foundation
import AppKit
import UniformTypeIdentifiers

class MarkdownExporter {
    func export(items: [FileItem], directoryName: String, directoryPath: String, preserveOrder: Bool = false) -> String {
        var md = "# Tracked Files - \(directoryName)\n\n"
        md += "> Path: `\(directoryPath)`\n\n"
        md += "> Exported: \(Date().formatted(date: .long, time: .shortened))\n\n"

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none

        if preserveOrder {
            // Export items in the order they were passed (preserves manual sort)
            md += "## Items\n\n"
            for item in items {
                md += formatItem(item, dateFormatter: dateFormatter)
            }
        } else {
            // Group by priority
            let priorityGroups = Dictionary(grouping: items) { $0.priority }
            let sortedPriorities = priorityGroups.keys.sorted(by: >)

            for priority in sortedPriorities {
                guard let groupItems = priorityGroups[priority] else { continue }

                let priorityLabel = priorityLabel(for: priority)
                md += "## \(priorityLabel)\n\n"

                for item in groupItems.sorted(by: { ($0.name ?? "") < ($1.name ?? "") }) {
                    md += formatItem(item, dateFormatter: dateFormatter)
                }
            }
        }

        // Summary
        md += "---\n\n"
        md += "## Summary\n\n"
        md += "- Total items: \(items.count)\n"
        md += "- Directories: \(items.filter { $0.isDirectory }.count)\n"
        md += "- Files: \(items.filter { !$0.isDirectory }.count)\n"
        md += "- Git repositories: \(items.filter { $0.isGitRepo }.count)\n"

        let withChanges = items.filter { $0.isGitRepo && $0.hasUncommittedChanges }.count
        if withChanges > 0 {
            md += "- Repos with uncommitted changes: \(withChanges)\n"
        }

        return md
    }

    private func formatItem(_ item: FileItem, dateFormatter: DateFormatter) -> String {
        var md = ""
        let icon = item.isDirectory ? "📁" : "📄"
        let name = item.name ?? "Unknown"
        let path = item.path ?? ""

        md += "- **\(icon) \(name)**"

        if item.isGitRepo {
            let gitStatus = item.hasUncommittedChanges ? "dirty" : "clean"
            md += " `git: \(gitStatus)`"
        }

        md += "\n"
        md += "  - Path: `\(path)`\n"

        if let modified = item.modifiedAt {
            md += "  - Modified: \(dateFormatter.string(from: modified))\n"
        }

        if !item.isDirectory {
            md += "  - Size: \(formatSize(item.fileSize))\n"
        }

        if item.priority > 0 {
            md += "  - Priority: \(String(repeating: "★", count: Int(item.priority)))\n"
        }

        if let notes = item.notes, !notes.isEmpty {
            md += "  - Notes: \(notes)\n"
        }

        md += "\n"
        return md
    }

    private func priorityLabel(for priority: Int16) -> String {
        switch priority {
        case 5: return "Priority 5 - Critical"
        case 4: return "Priority 4 - High"
        case 3: return "Priority 3 - Medium"
        case 2: return "Priority 2 - Low-Medium"
        case 1: return "Priority 1 - Low"
        default: return "No Priority"
        }
    }

    private func formatSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }

    func saveToFile(items: [FileItem], directoryName: String, directoryPath: String, preserveOrder: Bool = false) -> URL? {
        let content = export(items: items, directoryName: directoryName, directoryPath: directoryPath, preserveOrder: preserveOrder)

        let panel = NSSavePanel()
        panel.allowedContentTypes = [.plainText]
        panel.nameFieldStringValue = "\(directoryName)-export.md"
        panel.message = "Choose where to save the Markdown export"

        guard panel.runModal() == .OK, let url = panel.url else {
            return nil
        }

        do {
            try content.write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            print("Error saving Markdown: \(error)")
            return nil
        }
    }
}
