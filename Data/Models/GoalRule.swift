//
//  GoalRule.swift
//  Finanzas
//
//  Regla que define cuánto aportar a una meta cuando ocurre un disparador
//  (ej. quincena, incentivo). Permite porcentaje o monto fijo.
//

import Foundation
import SwiftData

@Model
final class GoalRule {
    @Attribute(.unique) var id: UUID
    var triggerTypeRaw: String
    var fixedAmount: Double?
    var percentage: Double?
    var priorityOrder: Int
    var isActive: Bool

    var goal: Goal?

    init(
        id: UUID = UUID(),
        goal: Goal? = nil,
        triggerType: GoalTriggerType,
        fixedAmount: Double? = nil,
        percentage: Double? = nil,
        priorityOrder: Int = 0,
        isActive: Bool = true
    ) {
        self.id = id
        self.goal = goal
        self.triggerTypeRaw = triggerType.rawValue
        self.fixedAmount = fixedAmount
        self.percentage = percentage
        self.priorityOrder = priorityOrder
        self.isActive = isActive
    }

    var triggerType: GoalTriggerType {
        get { GoalTriggerType(rawValue: triggerTypeRaw) ?? .manual }
        set { triggerTypeRaw = newValue.rawValue }
    }
}
