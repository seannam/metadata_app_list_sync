import SwiftUI

struct PriorityPicker: View {
    @Binding var priority: Int16

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0...5, id: \.self) { level in
                Button {
                    priority = Int16(level)
                } label: {
                    if level == 0 {
                        Image(systemName: priority == 0 ? "circle.fill" : "circle")
                            .foregroundColor(priority == 0 ? .gray : .secondary)
                    } else {
                        Image(systemName: level <= Int(priority) ? "star.fill" : "star")
                            .foregroundColor(level <= Int(priority) ? .orange : .secondary)
                    }
                }
                .buttonStyle(.plain)
                .font(.title2)
            }

            Spacer()

            Text(priorityLabel)
                .foregroundColor(.secondary)
                .font(.caption)
        }
    }

    private var priorityLabel: String {
        switch priority {
        case 0: return "No priority"
        case 1: return "Low"
        case 2: return "Low-Medium"
        case 3: return "Medium"
        case 4: return "High"
        case 5: return "Critical"
        default: return ""
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        ForEach(0...5, id: \.self) { priority in
            PriorityPicker(priority: .constant(Int16(priority)))
        }
    }
    .padding()
}
