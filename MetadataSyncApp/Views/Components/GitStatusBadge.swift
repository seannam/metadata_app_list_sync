import SwiftUI

struct GitStatusBadge: View {
    let hasChanges: Bool

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: hasChanges ? "exclamationmark.circle.fill" : "checkmark.circle.fill")
                .font(.system(size: 12))

            Text(hasChanges ? "dirty" : "clean")
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(hasChanges ? Color.orange.opacity(0.2) : Color.green.opacity(0.2))
        .foregroundColor(hasChanges ? .orange : .green)
        .cornerRadius(6)
    }
}

#Preview {
    VStack(spacing: 16) {
        GitStatusBadge(hasChanges: false)
        GitStatusBadge(hasChanges: true)
    }
    .padding()
}
