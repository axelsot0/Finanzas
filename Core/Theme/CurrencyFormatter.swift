//
//  CurrencyFormatter.swift
//  Finanzas
//
//  Helpers para formatear montos de forma consistente.
//

import Foundation

enum Money {
    static let formatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = "DOP"          // Peso dominicano (ajustable en Settings)
        f.maximumFractionDigits = 0
        f.locale = Locale(identifier: "es_DO")
        return f
    }()

    static func format(_ value: Double) -> String {
        formatter.string(from: NSNumber(value: value)) ?? "—"
    }
}
