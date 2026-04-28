//
//  Calculations.swift
//  Finanzas
//
//  Lógica de cálculo derivada — vive aquí en lugar de duplicarse en vistas.
//  Sigue las reglas de negocio del plan (sección 5).
//

import Foundation
import SwiftUI

// MARK: - Account

extension Account {
    /// Balance calculado: openingBalance + entradas - salidas.
    /// Para tarjetas de crédito, balance negativo = deuda.
    var calculatedBalance: Double {
        let inflows  = incomingTransactions.reduce(0) { $0 + $1.amount }
        let outflows = outgoingTransactions.reduce(0) { $0 + $1.amount }
        return openingBalance + inflows - outflows
    }

    var health: HealthStatus {
        switch type {
        case .credit:
            // En tarjeta el "balance" representa deuda; baja deuda = sano.
            let debt = abs(min(0, calculatedBalance))
            if debt == 0 { return .good }
            if debt < 30_000 { return .warning }
            return .danger
        default:
            if calculatedBalance < 5_000 { return .danger }
            if calculatedBalance < 20_000 { return .warning }
            return .neutral
        }
    }
}

// MARK: - Goal

extension Goal {
    /// Ahorrado actual = startAmount + sum(deposits) - sum(withdrawals).
    var savedAmount: Double {
        startAmount + allocations.reduce(0) { $0 + $1.signedAmount }
    }

    var remainingAmount: Double { max(0, targetAmount - savedAmount) }

    var progress: Double {
        guard targetAmount > 0 else { return 0 }
        return min(1, savedAmount / targetAmount)
    }

    /// Salud según ritmo: compara aportado real vs el plan de período.
    var health: HealthStatus {
        guard status == .active else { return .neutral }
        let expected = expectedAmountByNow()
        if savedAmount >= expected { return .good }
        let ratio = expected > 0 ? savedAmount / expected : 1
        if ratio >= 0.7 { return .warning }
        return .danger
    }

    /// Cuánto deberías llevar ahorrado al día de hoy según el plan.
    func expectedAmountByNow(reference: Date = .now) -> Double {
        let elapsed = max(0, reference.timeIntervalSince(startDate))
        let periodSeconds: Double
        switch contributionPeriod {
        case .weekly:   periodSeconds = 7 * 86_400
        case .biweekly: periodSeconds = 14 * 86_400
        case .monthly:  periodSeconds = 30 * 86_400
        case .oneTime:  periodSeconds = 1
        }
        let periods = floor(elapsed / periodSeconds)
        return startAmount + periods * plannedAmountPerPeriod
    }

    var color: Color { Color(hex: colorHex) ?? Theme.accent }
}

// MARK: - Category

extension Category {
    /// Total gastado en el rango (positivo).
    func totalSpent(in range: ClosedRange<Date>) -> Double {
        transactions
            .filter { range.contains($0.occurredAt) && $0.kind == .expense }
            .reduce(0) { $0 + $1.amount }
    }

    func health(in range: ClosedRange<Date>) -> HealthStatus {
        guard let budget = monthlyBudget, budget > 0 else { return .neutral }
        let pct = totalSpent(in: range) / budget
        if pct < 0.8 { return .good }
        if pct < 1.0 { return .warning }
        return .danger
    }

    var color: Color { Color(hex: colorHex) ?? Theme.accent }
}

// MARK: - Helpers de fecha

enum DateRanges {
    static func currentMonth(reference: Date = .now) -> ClosedRange<Date> {
        let cal = Calendar.current
        let start = cal.date(from: cal.dateComponents([.year, .month], from: reference))!
        let end = cal.date(byAdding: .month, value: 1, to: start)!.addingTimeInterval(-1)
        return start...end
    }

    static func currentBiweek(reference: Date = .now) -> ClosedRange<Date> {
        let cal = Calendar.current
        let day = cal.component(.day, from: reference)
        var comps = cal.dateComponents([.year, .month], from: reference)
        let monthStart = cal.date(from: comps)!
        if day <= 15 {
            comps.day = 15
            comps.hour = 23; comps.minute = 59; comps.second = 59
            let end = cal.date(from: comps)!
            return monthStart...end
        } else {
            comps.day = 16
            comps.hour = 0; comps.minute = 0; comps.second = 0
            let start = cal.date(from: comps)!
            let end = cal.date(byAdding: .month, value: 1, to: monthStart)!.addingTimeInterval(-1)
            return start...end
        }
    }
}

// MARK: - Color desde hex

extension Color {
    init?(hex: String) {
        var s = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.hasPrefix("#") { s.removeFirst() }
        guard s.count == 6, let val = UInt32(s, radix: 16) else { return nil }
        let r = Double((val >> 16) & 0xFF) / 255
        let g = Double((val >> 8) & 0xFF) / 255
        let b = Double(val & 0xFF) / 255
        self = Color(red: r, green: g, blue: b)
    }
}
