import SwiftUI

struct TransactionRowView: View {
    let transaction: Transaction

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: transaction.category.icon)
                .font(.title3)
                .foregroundColor(.accentColor)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 4) {
                Text(displayTitle)
                    .font(.headline)
                    .lineLimit(1)
                Text(Self.dateFormatter.string(from: transaction.date))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text(
                transaction.amount,
                format: .currency(code: "RUB")
            )
            .fontWeight(.semibold)
            .foregroundColor(.primary)
        }
        .padding(.vertical, 4)
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM yyyy"
        return formatter
    }()

    private var displayTitle: String {
        let trimmed = transaction.note.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Без заметки" : trimmed
    }
}

#Preview {
    TransactionRowView(
        transaction: Transaction(
            amount: 1499.99,
            category: .food,
            date: Date(),
            note: "Продукты на неделю"
        )
    )
    .padding()
}
