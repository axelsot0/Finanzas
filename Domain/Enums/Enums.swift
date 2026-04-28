//
//  Enums.swift
//  Finanzas
//
//  Enums del dominio. Todos son Codable+CaseIterable para serializarse en
//  SwiftData y poder iterarse en Pickers.
//

import Foundation
import SwiftUI

// MARK: - Cuentas

enum AccountType: String, Codable, CaseIterable, Identifiable {
    case checking      // Cuenta corriente
    case savings       // Ahorro de alto rendimiento
    case payroll       // Nómina
    case credit        // Tarjeta de crédito
    case cash          // Efectivo

    var id: String { rawValue }

    var label: String {
        switch self {
        case .checking: return "Corriente"
        case .savings:  return "Ahorro"
        case .payroll:  return "Nómina"
        case .credit:   return "Tarjeta"
        case .cash:     return "Efectivo"
        }
    }

    var icon: String {
        switch self {
        case .checking: return "building.columns"
        case .savings:  return "leaf.fill"
        case .payroll:  return "dollarsign.circle.fill"
        case .credit:   return "creditcard.fill"
        case .cash:     return "banknote.fill"
        }
    }
}

// MARK: - Categorías

enum CategoryKind: String, Codable, CaseIterable, Identifiable {
    case income, expense, transfer
    var id: String { rawValue }
    var label: String {
        switch self {
        case .income:   return "Ingreso"
        case .expense:  return "Gasto"
        case .transfer: return "Transferencia"
        }
    }
}

// MARK: - Transacciones

enum TransactionKind: String, Codable, CaseIterable, Identifiable {
    case income          // Ingreso (quincena, incentivo, intereses)
    case expense         // Gasto regular
    case transfer        // Mover entre cuentas propias
    case cardPayment     // Pago a tarjeta de crédito
    case savings         // Aporte a meta de ahorro

    var id: String { rawValue }
    var label: String {
        switch self {
        case .income:      return "Ingreso"
        case .expense:     return "Gasto"
        case .transfer:    return "Transferencia"
        case .cardPayment: return "Pago tarjeta"
        case .savings:     return "Ahorro"
        }
    }
    var icon: String {
        switch self {
        case .income:      return "arrow.down.circle.fill"
        case .expense:     return "arrow.up.circle.fill"
        case .transfer:    return "arrow.left.arrow.right.circle.fill"
        case .cardPayment: return "creditcard.fill"
        case .savings:     return "target"
        }
    }
    /// Signo aplicado al monto desde la perspectiva del flujo neto del usuario.
    var sign: Double {
        switch self {
        case .income:                              return  1
        case .expense, .cardPayment, .savings:     return -1
        case .transfer:                            return  0
        }
    }

    var requiresFromAccount: Bool {
        switch self {
        case .income:                              return false
        case .expense, .transfer, .cardPayment, .savings: return true
        }
    }

    var requiresToAccount: Bool {
        switch self {
        case .expense:                             return false
        case .income, .transfer, .cardPayment, .savings: return true
        }
    }
}

enum TransactionStatus: String, Codable, CaseIterable {
    case pending, posted, void
}

enum PaymentMethod: String, Codable, CaseIterable, Identifiable {
    case debit, credit, cash, transfer, other
    var id: String { rawValue }
    var label: String {
        switch self {
        case .debit:    return "Débito"
        case .credit:   return "Crédito"
        case .cash:     return "Efectivo"
        case .transfer: return "Transferencia"
        case .other:    return "Otro"
        }
    }
}

// MARK: - Metas

enum GoalType: String, Codable, CaseIterable, Identifiable {
    case purchase     // Carro, MacBook
    case education    // INTEC
    case emergency    // Colchón
    case travel
    case generic
    var id: String { rawValue }
    var label: String {
        switch self {
        case .purchase:  return "Compra"
        case .education: return "Educación"
        case .emergency: return "Colchón"
        case .travel:    return "Viaje"
        case .generic:   return "General"
        }
    }
    var icon: String {
        switch self {
        case .purchase:  return "car.fill"
        case .education: return "graduationcap.fill"
        case .emergency: return "shield.fill"
        case .travel:    return "airplane"
        case .generic:   return "target"
        }
    }
}

enum GoalStatus: String, Codable, CaseIterable {
    case active, paused, completed, cancelled
    var label: String {
        switch self {
        case .active:    return "Activa"
        case .paused:    return "Pausada"
        case .completed: return "Completada"
        case .cancelled: return "Cancelada"
        }
    }
}

enum ContributionPeriod: String, Codable, CaseIterable, Identifiable {
    case biweekly, monthly, weekly, oneTime
    var id: String { rawValue }
    var label: String {
        switch self {
        case .biweekly: return "Quincenal"
        case .monthly:  return "Mensual"
        case .weekly:   return "Semanal"
        case .oneTime:  return "Único"
        }
    }
}

enum GoalTriggerType: String, Codable, CaseIterable {
    case payroll, incentive, manual, monthly
}

enum GoalAllocationType: String, Codable, CaseIterable {
    case deposit, withdrawal
}

// MARK: - Salud (semáforo)

enum HealthStatus {
    case good, warning, danger, neutral
    var color: Color {
        switch self {
        case .good:    return Theme.positive
        case .warning: return Theme.warning
        case .danger:  return Theme.danger
        case .neutral: return Theme.info
        }
    }
}
