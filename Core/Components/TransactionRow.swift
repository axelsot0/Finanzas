//
//  TransactionRow.swift
//  Finanzas
//
//  Fila de transacción para listas e históricos.
//

import SwiftUI

struct TransactionRow: View {
    let transaction: Transaction

    private var amountColor: Color {
        switch transaction.kind {
        case .income:                         return Theme.positive
        case .expense, .cardPayment, .savings: return Theme.danger.opacity(0.85)
        case .transfer:                        return Theme.textSecondary
        }
    }

    private var amountPrefix: String {
        switch transaction.kind {
        case .income:                          return "+"
        case .expense, .cardPayment, .savings: return "−"
        case .transfer:                        return ""
        }
    }

    private var kindColor: Color {
        switch transaction.kind {
        case .income:      return Theme.positive
        case .expense:     return Theme.danger
        case .transfer:    return Theme.info
        case .cardPayment: return Theme.warning
        case .savings:     return Theme.accent
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(kindColor.opacity(0.18))
                Image(systemName: transaction.category?.icon ?? transaction.kind.icon)
                    .foregroundStyle(kindColor)
                    .font(.system(size: 14, weight: .semibold))
            }
            .frame(width: 36, height: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text(displayTitle)
                    .font(Theme.Font.body.weight(.medium))
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(1)
                Text(subtitleText)
                    .font(Theme.Font.caption)
                    .foregroundStyle(Theme.textTertiary)
                    .lineLimit(1)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(amountPrefix)\(Money.format(transaction.amount))")
                    .font(Theme.Font.body.weight(.semibold))
                    .foregroundStyle(amountColor)
                    .monospacedDigit()
                Text(transaction.occurredAt, format: .dateTime.day().month(.abbreviated))
                    .font(Theme.Font.caption)
                    .foregroundStyle(Theme.textTertiary)
            }
        }
        .padding(.vertical, 8)
    }

    private var displayTitle: String {
        if !transaction.title.isEmpty { return transaction.title }
        if !transaction.merchant.isEmpty { return transaction.merchant }
        return transaction.category?.name ?? transaction.kind.label
    }

    private var subtitleText: String {
        var parts: [String] = []
        if let cat = transaction.category { parts.append(cat.name) }
        if let acc = transaction.fromAccount ?? transaction.toAccount { parts.append(acc.name) }
        return parts.joined(separator: " · ")
    }
}
