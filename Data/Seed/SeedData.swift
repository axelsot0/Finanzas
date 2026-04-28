//
//  SeedData.swift
//  Finanzas
//
//  Datos semilla para arrancar la app con cuentas, categorías y metas
//  alineadas con tu plan (carro, MacBook Pro, INTEC, colchón).
//

import Foundation
import SwiftData

enum SeedData {

    static func populate(context: ModelContext) {
        // MARK: Cuentas
        let nomina   = Account(name: "Nómina",      type: .payroll,  institution: "Banco",  openingBalance: 0,      colorHex: "#6CF1BD")
        let ahorro   = Account(name: "Ahorro HYS",  type: .savings,  institution: "Banco",  openingBalance: 35_000, colorHex: "#7CC1FF")
        let corriente = Account(name: "Corriente",  type: .checking, institution: "Banco",  openingBalance: 8_000,  colorHex: "#C5A6FF")
        let tarjeta  = Account(name: "Tarjeta",     type: .credit,   institution: "Banco",  openingBalance: 0,      colorHex: "#FF6B6F")

        [nomina, ahorro, corriente, tarjeta].forEach { context.insert($0) }

        // MARK: Categorías de gasto
        let cats: [Category] = [
            Category(name: "Quincena",  kind: .income,   colorHex: "#6CF1BD", icon: "dollarsign.circle.fill"),
            Category(name: "Incentivo", kind: .income,   colorHex: "#7CFFD4", icon: "sparkles"),
            Category(name: "Delivery",  kind: .expense,  colorHex: "#FF8E5C", icon: "bag.fill",       monthlyBudget: 6_000),
            Category(name: "Gasolina",  kind: .expense,  colorHex: "#FFB14E", icon: "fuelpump.fill",  monthlyBudget: 5_000),
            Category(name: "Luz",       kind: .expense,  colorHex: "#FFD55C", icon: "bolt.fill",      monthlyBudget: 3_000),
            Category(name: "Spotify",   kind: .expense,  colorHex: "#1DB954", icon: "music.note",     monthlyBudget: 250),
            Category(name: "Uber One",  kind: .expense,  colorHex: "#000000", icon: "car.fill",       monthlyBudget: 500),
            Category(name: "Perros",    kind: .expense,  colorHex: "#C5A6FF", icon: "pawprint.fill",  monthlyBudget: 3_500),
            Category(name: "Educación", kind: .expense,  colorHex: "#7CC1FF", icon: "graduationcap.fill"),
            Category(name: "Mercado",   kind: .expense,  colorHex: "#9CE37D", icon: "cart.fill",      monthlyBudget: 8_000),
            Category(name: "Salidas",   kind: .expense,  colorHex: "#FF6B9D", icon: "wineglass.fill", monthlyBudget: 4_000)
        ]
        cats.enumerated().forEach { idx, cat in
            cat.sortOrder = idx
            context.insert(cat)
        }

        // MARK: Metas
        let metas: [Goal] = [
            Goal(name: "Carro",       goalType: .purchase,  targetAmount: 600_000, startAmount: 25_000,
                 plannedAmountPerPeriod: 8_000, priority: 1, colorHex: "#6CF1BD"),
            Goal(name: "MacBook Pro", goalType: .purchase,  targetAmount: 165_000, startAmount: 5_000,
                 plannedAmountPerPeriod: 5_000, priority: 2, colorHex: "#C5A6FF"),
            Goal(name: "INTEC",       goalType: .education, targetAmount: 90_000,  startAmount: 0,
                 plannedAmountPerPeriod: 6_000, priority: 1, colorHex: "#7CC1FF"),
            Goal(name: "Colchón",     goalType: .emergency, targetAmount: 150_000, startAmount: 5_000,
                 plannedAmountPerPeriod: 4_000, priority: 1, colorHex: "#FFB14E")
        ]
        metas.forEach { context.insert($0) }

        // Algunas transacciones de ejemplo para que el dashboard no esté vacío.
        let cal = Calendar.current
        let today = Date()
        let cQuincena = cats[0]; let cDelivery = cats[2]; let cLuz = cats[4]
        let cSpotify  = cats[5]; let cMercado  = cats[9]

        let demo: [Transaction] = [
            Transaction(kind: .income,  amount: 45_000, title: "Quincena Abril",
                        occurredAt: cal.date(byAdding: .day, value: -2, to: today)!,
                        toAccount: nomina, category: cQuincena),
            Transaction(kind: .expense, amount: 850, title: "Pedido Pizza",
                        merchant: "Domino's",
                        occurredAt: cal.date(byAdding: .day, value: -1, to: today)!,
                        fromAccount: corriente, category: cDelivery),
            Transaction(kind: .expense, amount: 2_400, title: "Factura luz",
                        occurredAt: cal.date(byAdding: .day, value: -3, to: today)!,
                        fromAccount: corriente, category: cLuz),
            Transaction(kind: .expense, amount: 199, title: "Spotify",
                        occurredAt: cal.date(byAdding: .day, value: -5, to: today)!,
                        fromAccount: corriente, category: cSpotify),
            Transaction(kind: .expense, amount: 3_200, title: "Compra semana",
                        merchant: "Supermercado",
                        occurredAt: cal.date(byAdding: .day, value: -4, to: today)!,
                        fromAccount: corriente, category: cMercado),
            Transaction(kind: .savings, amount: 8_000, title: "Aporte Carro",
                        occurredAt: cal.date(byAdding: .day, value: -2, to: today)!,
                        fromAccount: nomina, toAccount: ahorro)
        ]
        demo.forEach { context.insert($0) }

        // Asignación del aporte de ahorro a la meta Carro
        let aporteCarro = GoalAllocation(goal: metas[0], transaction: demo.last!,
                                         movementType: .deposit, amount: 8_000,
                                         note: "Aporte automático")
        context.insert(aporteCarro)

        try? context.save()
    }
}
