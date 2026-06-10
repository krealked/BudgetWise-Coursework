import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct TransactionRowView: View {
    let transaction: Transaction

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: transaction.category.iconName)
                .font(.system(size: 24))
                .foregroundStyle(Color.themeAccent)
                .frame(width: 28, alignment: .center)

            VStack(alignment: .leading, spacing: 4) {
                Text(displayTitle)
                    .font(.headline)
                    .lineLimit(1)
                    .foregroundStyle(Color.themeHeadingOnDark)
                Text(Self.dateFormatter.string(from: transaction.date))
                    .font(.caption)
                    .foregroundStyle(Color.themeCaptionOnDark)
            }

            Spacer()

            Text(
                transaction.amount,
                format: .currency(code: "RUB")
            )
            .fontWeight(.semibold)
            .foregroundStyle(Color.themeAccent)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(rowBackgroundColor)
        .cornerRadius(12)
        .padding(.vertical, 4)
    }

    private var rowBackgroundColor: Color {
        #if canImport(UIKit)
        Color(UIColor.secondarySystemBackground)
        #else
        Color.themeSurfaceElevated
        #endif
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
