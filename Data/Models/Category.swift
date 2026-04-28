//
//  Category.swift
//  Finanzas
//
//  Categoría con la que se clasifica una transacción.
//  Color, icono y presupuesto opcional para detección de fugas.
//

import Foundation
import SwiftData

@Model
final class Category {
    @Attribute(.unique) var id: UUID
    var name: String
    var kindRaw: String
    var colorHex: String
    var icon: String
    var monthlyBudget: Double?
    var isSystem: Bool
    var isActive: Bool
    var sortOrder: Int

    @Relationship(deleteRule: .nullify, inverse: \Transaction.category)
    var transactions: [Transaction] = []

    init(
        id: UUID = UUID(),
        name: String,
        kind: CategoryKind = .expense,
        colorHex: String = "#6CF1BD",
        icon: String = "circle.fill",
        monthlyBudget: Double? = nil,
        isSystem: Bool = false,
        isActive: Bool = true,
        sortOrder: Int = 0
    ) {
        self.id = id
        self.name = name
        self.kindRaw = kind.rawValue
        self.colorHex = colorHex
        self.icon = icon
        self.monthlyBudget = monthlyBudget
        self.isSystem = isSystem
        self.isActive = isActive
        self.sortOrder = sortOrder
    }

    var kind: CategoryKind {
        get { CategoryKind(rawValue: kindRaw) ?? .expense }
        set { kindRaw = newValue.rawValue }
    }
}
