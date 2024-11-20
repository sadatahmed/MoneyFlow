import SwiftUI

struct TransactionRow: View {
    @ObservedObject var transaction: Transaction
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 12) {
            // Category Icon
            ZStack {
                Circle()
                    .fill(getCategoryColor())
                    .frame(width: 40, height: 40)
                
                Image(systemName: getCategoryIcon())
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
            }
            
            // Transaction Details
            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.category ?? "Uncategorized")
                    .font(.system(.body, design: .rounded))
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                
                if let note = transaction.note, !note.isEmpty {
                    Text(note)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            // Amount and Date
            VStack(alignment: .trailing, spacing: 4) {
                Text("$\(transaction.amount, specifier: "%.2f")")
                    .font(.system(.body, design: .rounded))
                    .bold()
                    .foregroundStyle(getAmountColor())
                
                if let date = transaction.date {
                    Text(date, style: .date)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
    
    private func getAmountColor() -> Color {
        if transaction.type == "transfer" {
            return colorScheme == .dark ? .blue : .blue
        }
        return transaction.amount >= 0 ? .green : .red
    }
    
    private func getCategoryColor() -> Color {
        switch transaction.category {
        case "Food": return .orange
        case "Transport": return .blue
        case "Entertainment": return .purple
        case "Shopping": return .green
        case "Bills": return .red
        case "Transfer": return .blue
        default: return .gray
        }
    }
    
    private func getCategoryIcon() -> String {
        switch transaction.category {
        case "Food": return "fork.knife"
        case "Transport": return "car.fill"
        case "Entertainment": return "tv.fill"
        case "Shopping": return "cart.fill"
        case "Bills": return "doc.text.fill"
        case "Transfer": return "arrow.left.arrow.right"
        default: return "questionmark"
        }
    }
} 
