//
//  Metrics.swift
//  Finanzas
//
//  Métricas agregadas usadas por el Dashboard. Se separan en un namespace
//  para no inflar Calculations.swift y poder testearse de forma aislada.
//

import Foundation

enum Metrics {

    // MARK: - Saldo líquido

    /// Dinero "disponible" hoy: nómina + corriente + efectivo. Excluye ahorro y crédito.
    /// Las salidas hacia ahorro o pagos a tarjeta ya restan vía outgoingTransactions.
    static func liquidBalance(_ accounts: [Account]) -> Double {
        accounts
            .filter { $0.isActive && [.payroll, .checking, .cash].contains($0.type) }
            .reduce(0) { $0 + $1.calculatedBalance }
    }

    /// Saldo de las cuentas de ahorro = entradas − salidas + opening.
    static func savingsBalance(_ accounts: [Account]) -> Double {
        accounts
            .filter { $0.isActive && $0.type == .savings }
            .reduce(0) { $0 + $1.calculatedBalance }
    }

    // MARK: - Tarjeta

    /// Uso de tarjeta en el rango: gastos cargados a crédito (NO los pagos).
    static func cardUsage(_ txs: [Transaction], in range: ClosedRange<Date>) -> Double {
        txs.filter {
            range.contains($0.occurredAt) &&
            $0.kind == .expense &&
            $0.paymentMethod == .credit
        }.reduce(0) { $0 + $1.amount }
    }

    /// Pagos a la tarjeta en el rango (sin importar la cuenta de origen).
    static func cardPayments(_ txs: [Transaction], in range: ClosedRange<Date>) -> Double {
        txs.filter {
            range.contains($0.occurredAt) && $0.kind == .cardPayment
        }.reduce(0) { $0 + $1.amount }
    }

    // MARK: - Gasto real (cash-out de cuentas líquidas o de ahorro)

    /// El gasto real es la salida efectiva de dinero — no incluye usos de tarjeta
    /// (eso solo crea deuda). Sí incluye:
    ///   - Gastos pagados con débito/efectivo/transferencia
    ///   - Pagos a la tarjeta (ahí sí sale el dinero)
    ///   - Retiros de la cuenta de ahorro (transferencias salientes)
    static func realExpenses(_ txs: [Transaction], in range: ClosedRange<Date>) -> Double {
        txs.filter { tx in
            guard range.contains(tx.occurredAt) else { return false }
            switch tx.kind {
            case .expense:
                return tx.paymentMethod != .credit
            case .cardPayment:
                return true
            case .transfer:
                return tx.fromAccount?.type == .savings
            default:
                return false
            }
        }.reduce(0) { $0 + $1.amount }
    }

    // MARK: - Ingresos

    static func income(_ txs: [Transaction], in range: ClosedRange<Date>) -> Double {
        txs.filter {
            range.contains($0.occurredAt) && $0.kind == .income
        }.reduce(0) { $0 + $1.amount }
    }

    // MARK: - Salud financiera global

    /// Ratio gasto / ingreso de la quincena. Si no hay ingreso, usa el saldo líquido como base.
    static func healthRatio(_ txs: [Transaction], accounts: [Account],
                            in range: ClosedRange<Date>) -> Double {
        let inc = income(txs, in: range)
        let exp = realExpenses(txs, in: range)
        if inc > 0 { return exp / inc }
        let liquid = liquidBalance(accounts)
        return liquid > 0 ? exp / liquid : 0
    }

    static func health(ratio: Double) -> HealthStatus {
        if ratio < 0.7  { return .good }
        if ratio < 0.95 { return .warning }
        return .danger
    }
}
