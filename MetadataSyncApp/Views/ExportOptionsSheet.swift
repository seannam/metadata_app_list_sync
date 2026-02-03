import SwiftUI

struct ExportOptionsSheet: View {
    let directory: TrackedDirectory
    let items: [FileItem]
    @Environment(\.dismiss) private var dismiss

    @State private var exportFormat: ExportFormat = .csv
    @State private var includeAllItems = true
    @State private var exportedURL: URL?
    @State private var showSuccess = false

    enum ExportFormat: String, CaseIterable {
        case csv = "CSV"
        case markdown = "Markdown"

        var description: String {
            switch self {
            case .csv: return "Comma-separated values, great for importing into Notion databases or spreadsheets"
            case .markdown: return "Formatted text with headings and lists, great for Notion pages or documentation"
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Export Files")
                .font(.title2)
                .fontWeight(.bold)

            GroupBox("Format") {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(ExportFormat.allCases, id: \.self) { format in
                        HStack(alignment: .top) {
                            Image(systemName: exportFormat == format ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(exportFormat == format ? .accentColor : .secondary)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(format.rawValue)
                                    .fontWeight(.medium)
                                Text(format.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .onTapGesture {
                            exportFormat = format
                        }
                    }
                }
                .padding(.vertical, 4)
            }

            GroupBox("Options") {
                Toggle("Include all \(items.count) items", isOn: $includeAllItems)
                    .padding(.vertical, 4)
            }

            if showSuccess, let url = exportedURL {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Exported to \(url.lastPathComponent)")
                        .font(.caption)
                }
                .padding(8)
                .background(Color.green.opacity(0.1))
                .cornerRadius(8)
            }

            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button("Export") {
                    performExport()
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(width: 400)
    }

    private func performExport() {
        let itemsToExport = includeAllItems ? items : items.filter { $0.priority > 0 }
        let dirName = directory.name ?? "export"
        let dirPath = directory.path ?? ""

        switch exportFormat {
        case .csv:
            let exporter = CSVExporter()
            if let url = exporter.saveToFile(items: itemsToExport, directoryName: dirName) {
                exportedURL = url
                showSuccess = true
            }
        case .markdown:
            let exporter = MarkdownExporter()
            if let url = exporter.saveToFile(items: itemsToExport, directoryName: dirName, directoryPath: dirPath) {
                exportedURL = url
                showSuccess = true
            }
        }
    }
}
