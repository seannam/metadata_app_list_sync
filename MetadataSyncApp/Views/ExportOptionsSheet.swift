import SwiftUI

struct ExportOptions {
    var includeFolders = true
    var includeFiles = true
    var showEmojis = false
    var showBullets = false
    var showHeader = false
}

struct ExportOptionsSheet: View {
    let directory: TrackedDirectory
    let items: [FileItem]
    @Environment(\.dismiss) private var dismiss

    @State private var exportFormat: ExportFormat = .markdown
    @State private var options = ExportOptions()
    @State private var exportedURL: URL?
    @State private var showSuccess = false

    enum ExportFormat: String, CaseIterable {
        case markdown = "Plain Text"
        case csv = "CSV"

        var description: String {
            switch self {
            case .markdown: return "Simple list of names"
            case .csv: return "Comma-separated with type column"
            }
        }
    }

    private var filteredItems: [FileItem] {
        items.filter { item in
            if item.isDirectory && !options.includeFolders { return false }
            if !item.isDirectory && !options.includeFiles { return false }
            return true
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Export")
                .font(.title2)
                .fontWeight(.bold)

            GroupBox("Format") {
                Picker("Format", selection: $exportFormat) {
                    ForEach(ExportFormat.allCases, id: \.self) { format in
                        Text(format.rawValue).tag(format)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            }

            GroupBox("Filter") {
                VStack(alignment: .leading, spacing: 8) {
                    Toggle("Include folders", isOn: $options.includeFolders)
                    Toggle("Include files", isOn: $options.includeFiles)
                }
                .padding(.vertical, 4)
            }

            if exportFormat == .markdown {
                GroupBox("Formatting") {
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle("Show header", isOn: $options.showHeader)
                        Toggle("Show bullets (-)", isOn: $options.showBullets)
                        Toggle("Show icons", isOn: $options.showEmojis)
                    }
                    .padding(.vertical, 4)
                }
            }

            Text("\(filteredItems.count) items will be exported")
                .font(.caption)
                .foregroundColor(.secondary)

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
        let dirName = directory.name ?? "export"

        switch exportFormat {
        case .csv:
            let exporter = CSVExporter()
            if let url = exporter.saveToFile(items: filteredItems, directoryName: dirName) {
                exportedURL = url
                showSuccess = true
            }
        case .markdown:
            let exporter = MarkdownExporter()
            if let url = exporter.saveToFile(items: filteredItems, directoryName: dirName, options: options) {
                exportedURL = url
                showSuccess = true
            }
        }
    }
}
