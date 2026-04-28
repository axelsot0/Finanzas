//
//  GoalAllocation.swift
//  Finanzas
//
//  Une una transacción de ahorro con una meta. Una sola transacción puede
//  repartirse entre varias metas (carro, MacBook, INTEC, colchón).
//

import Foundation
import SwiftData

@Model
final class GoalAllocation {
    @Attribute(.unique) var id: UUID
    var movementTypeRaw: String
    var amount: Double
    var note: String

    var goal: Goal?
    var transaction: Transaction?

    init(
        id: UUID = UUID(),
        goal: Goal? = nil,
        transaction: Transaction? = nil,
        movementType: GoalAllocationType = .deposit,
        amount: Double,
        note: String = ""
    ) {
        self.id = id
        self.goal = goal
        self.transaction = transaction
        self.movementTypeRaw = movementType.rawValue
        self.amount = amount
        self.note = note
    }

    var movementType: GoalAllocationType {
        get { GoalAllocationType(rawValue: movementTypeRaw) ?? .deposit }
        set { movementTypeRaw = newValue.rawValue }
    }

    /// Aporte firmado (depósito positivo, retiro negativo).
    var signedAmount: Double {
        movementType == .deposit ? amount : -amount
    }
}
