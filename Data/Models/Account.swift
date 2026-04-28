//
//  Account.swift
//  Finanzas
//
//  Representa una cuenta financiera (corriente, ahorro, tarjeta, etc.).
//  El balance NO se persiste — se calcula desde Transaction.
//

import Foundation
import SwiftData

@Model
final class Account {
    @Attribute(.unique) var id: UUID
    var name: String
    var typeRaw: String
    var institution: String
    var currency: String
    var openingBalance: Double
    var colorHex: String
    var icon: String
    var isActive: Bool
    var createdAt: Date
    var updatedAt: Date

    // Relación inversa: una cuenta tiene muchas transacciones.
    // Usamos .nullify para preservar el histórico si se desactiva la cuenta.
    @Relationship(deleteRule: .nullify, inverse: \Transaction.fromAccount)
    var outgoingTransactions: [Transaction] = []

    @Relationship(deleteRule: .nullify, inverse: \Transaction.toAccount)
    var incomingTransactions: [Transaction] = []

    init(
        id: UUID = UUID(),
        name: String,
        type: AccountType,
        institution: String = "",
        currency: String = "DOP",
        openingBalance: Double = 0,
        colorHex: String = "#6CF1BD",
        icon: String? = nil,
        isActive: Bool = true
    ) {
        self.id = id
        self.name = name
        self.typeRaw = type.rawValue
        self.institution = institution
        self.currency = currency
        self.openingBalance = openingBalance
        self.colorHex = colorHex
        self.icon = icon ?? type.icon
        self.isActive = isActive
        self.createdAt = .now
        self.updatedAt = .now
    }

    var type: AccountType {
        get { AccountType(rawValue: typeRaw) ?? .checking }
        set { typeRaw = newValue.rawValue }
    }
}
