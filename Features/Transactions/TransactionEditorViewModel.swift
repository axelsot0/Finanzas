//
//  TransactionEditorViewModel.swift
//  Finanzas
//
//  ViewModel compartido para crear y editar transacciones.
//  Modo .create inicializa campos vacíos; .edit los puebla desde el modelo existente.
//

import Foundation
import SwiftData

@Observable
final class TransactionEditorViewModel {

    // MARK: - Mode

    enum Mode {
        case create(TransactionKind)
        case edit(Transaction)
    }

    // MARK: - Allocation Draft

    struct AllocationDraft: Identifiable {
        var id = UUID()
        var goal: Goal
        var amount: Double
        var movementType: GoalAllocationType = .deposit
        var existingId: UUID?
    }

    // MARK: - State

    let mode: Mode

    var amountText: String = ""
    var title: String = ""
    var merchant: String = ""
    var note: String = ""
    var paymentMethod: PaymentMethod = .debit
    var occurredAt: Date = .now
    var status: TransactionStatus = .posted
    var fromAccount: Account? = nil
    var toAccount: Account? = nil
    var category: Category? = nil
    var allocations: [AllocationDraft] = []

    // MARK: - Init

    init(mode: Mode) {
        self.mode = mode
        guard case .edit(let tx) = mode else { return }

        let v = tx.amount
        amountText = v.truncatingRemainder(dividingBy: 1) == 0 ? String(Int(v)) : String(v)
        title       = tx.title
        merchant    = tx.merchant
        note        = tx.note
        paymentMethod = tx.paymentMethod
        occurredAt  = tx.occurredAt
        status      = tx.status
        fromAccount = tx.fromAccount
        toAccount   = tx.toAccount
        category    = tx.category
        allocations = tx.allocations.compactMap { alloc in
            guard let goal = alloc.goal else { return nil }
            return AllocationDraft(goal: goal, amount: alloc.amount,
                                   movementType: alloc.movementType, existingId: alloc.id)
        }
    }

    // MARK: - Derived

    var kind: TransactionKind {
        switch mode {
        case .create(let k): return k
        case .edit(let tx):  return tx.kind
        }
    }

    var amountValue: Double {
        Double(amountText.replacingOccurrences(of: ",", with: ".")) ?? 0
    }

    var allocationsTotal: Double     { allocations.reduce(0) { $0 + $1.amount } }
    var allocationsRemaining: Double { max(0, amountValue - allocationsTotal) }

    var validationError: String? {
        if amountValue <= 0 { return "El monto debe ser mayor a cero." }
        if title.trimmingCharacters(in: .whitespaces).isEmpty { return "El título es obligatorio." }
        if kind.requiresFromAccount && fromAccount == nil { return "Selecciona una cuenta de origen." }
        if kind.requiresToAccount   && toAccount   == nil { return "Selecciona una cuenta de destino." }
        if kind == .transfer, let f = fromAccount, let t = toAccount, f.id == t.id {
            return "Origen y destino no pueden ser la misma cuenta."
        }
        if (kind == .income || kind == .expense) && category == nil {
            return "Selecciona una categoría."
        }
        if allocationsTotal > amountValue + 0.01 {
            return "La suma de aportes a metas excede el monto total."
        }
        return nil
    }

    var isValid: Bool { validationError == nil }

    // MARK: - Actions

    func save(context: ModelContext) {
        switch mode {
        case .create(let k):
            let tx = Transaction(
                kind: k,
                amount: amountValue,
                title: title,
                merchant: merchant,
                note: note,
                paymentMethod: paymentMethod,
                occurredAt: occurredAt,
                status: status,
                fromAccount: fromAccount,
                toAccount: toAccount,
                category: category
            )
            context.insert(tx)
            for draft in allocations {
                let alloc = GoalAllocation(goal: draft.goal, transaction: tx,
                                          movementType: draft.movementType, amount: draft.amount)
                context.insert(alloc)
            }

        case .edit(let tx):
            tx.amount        = amountValue
            tx.title         = title
            tx.merchant      = merchant
            tx.note          = note
            tx.paymentMethod = paymentMethod
            tx.occurredAt    = occurredAt
            tx.status        = status
            tx.fromAccount   = fromAccount
            tx.toAccount     = toAccount
            tx.category      = category

            let keepIds = Set(allocations.compactMap(\.existingId))
            for alloc in tx.allocations where !keepIds.contains(alloc.id) {
                context.delete(alloc)
            }
            for draft in allocations {
                if let existingId = draft.existingId,
                   let existing = tx.allocations.first(where: { $0.id == existingId }) {
                    existing.amount       = draft.amount
                    existing.movementType = draft.movementType
                } else if draft.existingId == nil {
                    let alloc = GoalAllocation(goal: draft.goal, transaction: tx,
                                              movementType: draft.movementType, amount: draft.amount)
                    context.insert(alloc)
                }
            }
        }
        try? context.save()
    }

    func delete(context: ModelContext) {
        guard case .edit(let tx) = mode else { return }
        context.delete(tx)
        try? context.save()
    }
}
