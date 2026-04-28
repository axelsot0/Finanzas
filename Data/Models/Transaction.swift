//
//  Transaction.swift
//  Finanzas
//
//  Entidad central. Ingresos, gastos, transferencias, pagos a tarjeta y
//  movimientos de ahorro viven todos aquí, diferenciados por `kind`.
//

import Foundation
import SwiftData

@Model
final class Transaction {
    @Attribute(.unique) var id: UUID
    var kindRaw: String
    var amount: Double
    var title: String
    var merchant: String
    var note: String
    var paymentMethodRaw: String
    var occurredAt: Date
    var postedAt: Date?
    var statusRaw: String

    var fromAccount: Account?
    var toAccount: Account?
    var category: Category?

    @Relationship(deleteRule: .cascade, inverse: \GoalAllocation.transaction)
    var allocations: [GoalAllocation] = []

    init(
        id: UUID = UUID(),
        kind: TransactionKind,
        amount: Double,
        title: String = "",
        merchant: String = "",
        note: String = "",
        paymentMethod: PaymentMethod = .debit,
        occurredAt: Date = .now,
        postedAt: Date? = nil,
        status: TransactionStatus = .posted,
        fromAccount: Account? = nil,
        toAccount: Account? = nil,
        category: Category? = nil
    ) {
        self.id = id
        self.kindRaw = kind.rawValue
        self.amount = amount
        self.title = title
        self.merchant = merchant
        self.note = note
        self.paymentMethodRaw = paymentMethod.rawValue
        self.occurredAt = occurredAt
        self.postedAt = postedAt
        self.statusRaw = status.rawValue
        self.fromAccount = fromAccount
        self.toAccount = toAccount
        self.category = category
    }

    var kind: TransactionKind {
        get { TransactionKind(rawValue: kindRaw) ?? .expense }
        set { kindRaw = newValue.rawValue }
    }
    var paymentMethod: PaymentMethod {
        get { PaymentMethod(rawValue: paymentMethodRaw) ?? .debit }
        set { paymentMethodRaw = newValue.rawValue }
    }
    var status: TransactionStatus {
        get { TransactionStatus(rawValue: statusRaw) ?? .posted }
        set { statusRaw = newValue.rawValue }
    }

    /// Monto firmado para sumas en dashboard (positivo = entra dinero, negativo = sale).
    var signedAmount: Double { amount * kind.sign }
}
