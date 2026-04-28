//
//  Goal.swift
//  Finanzas
//
//  Meta de ahorro o reserva. El monto actual se deriva de GoalAllocation.
//

import Foundation
import SwiftData

@Model
final class Goal {
    @Attribute(.unique) var id: UUID
    var name: String
    var goalTypeRaw: String
    var targetAmount: Double
    var startAmount: Double
    var startDate: Date
    var targetDate: Date?
    var contributionPeriodRaw: String
    var plannedAmountPerPeriod: Double
    var priority: Int
    var statusRaw: String
    var colorHex: String
    var notes: String

    @Relationship(deleteRule: .cascade, inverse: \GoalRule.goal)
    var rules: [GoalRule] = []

    @Relationship(deleteRule: .cascade, inverse: \GoalAllocation.goal)
    var allocations: [GoalAllocation] = []

    init(
        id: UUID = UUID(),
        name: String,
        goalType: GoalType = .generic,
        targetAmount: Double,
        startAmount: Double = 0,
        startDate: Date = .now,
        targetDate: Date? = nil,
        contributionPeriod: ContributionPeriod = .biweekly,
        plannedAmountPerPeriod: Double = 0,
        priority: Int = 1,
        status: GoalStatus = .active,
        colorHex: String = "#6CF1BD",
        notes: String = ""
    ) {
        self.id = id
        self.name = name
        self.goalTypeRaw = goalType.rawValue
        self.targetAmount = targetAmount
        self.startAmount = startAmount
        self.startDate = startDate
        self.targetDate = targetDate
        self.contributionPeriodRaw = contributionPeriod.rawValue
        self.plannedAmountPerPeriod = plannedAmountPerPeriod
        self.priority = priority
        self.statusRaw = status.rawValue
        self.colorHex = colorHex
        self.notes = notes
    }

    var goalType: GoalType {
        get { GoalType(rawValue: goalTypeRaw) ?? .generic }
        set { goalTypeRaw = newValue.rawValue }
    }
    var contributionPeriod: ContributionPeriod {
        get { ContributionPeriod(rawValue: contributionPeriodRaw) ?? .biweekly }
        set { contributionPeriodRaw = newValue.rawValue }
    }
    var status: GoalStatus {
        get { GoalStatus(rawValue: statusRaw) ?? .active }
        set { statusRaw = newValue.rawValue }
    }
}
