//
//  NewTransactionView.swift
//  Finanzas
//
//  Formulario rápido y compacto para registrar gasto, ingreso, transferencia,
//  pago a tarjeta o ahorro. Sigue el principio de mínima fricción del plan.
//

import SwiftUI
import SwiftData

struct NewTransactionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @Query(sort: \Account.name) private var accounts: [Account]
    @Query(sort: \Category.sortOrder) private var categories: [Category]
    @Query(sort: \Goal.priority) private var goals: [Goal]

    // Form state
    @State private var kind: TransactionKind = .expense
    @State private var amountText: String = ""
    @State private var title: String = ""
    @State private var merchant: String = ""
    @State private var note: String = ""
    @State private var occurredAt: Date = .now
    @State private var paymentMethod: PaymentMethod = .debit
    @State private var fromAccount: Account?
    @State private var toAccount: Account?
    @State private var category: Category?
    @State private var selectedGoal: Goal?

    private var amountValue: Double { Double(amountText.replacingOccurrences(of: ",", with: ".")) ?? 0 }

    private var availableCategories: [Category] {
        switch kind {
        case .income:    return categories.filter { $0.kind == .income }
        case .expense, .cardPayment: return categories.filter { $0.kind == .expense }
        case .transfer, .savings: return []
        }
    }

    private var canSave: Bool {
        guard amountValue > 0 else { return false }
        switch kind {
        case .income:      return toAccount != nil
        case .expense:     return fromAccount != nil
        case .cardPayment: return fromAccount != nil && toAccount != nil
        case .transfer:    return fromAccount != nil && toAccount != nil && fromAccount != toAccount
        case .savings:     return fromAccount != nil && toAccount != nil
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    kindSelector
                    amountField
                    formCard
                    if kind == .savings {
                        goalSelector
                    }
                    notesCard
                }
                .padding(Theme.screenPadding)
                .padding(.bottom, 40)
            }
            .scrollIndicators(.hidden)
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("Nuevo movimiento")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancelar") { dismiss() }
                        .foregroundStyle(Theme.textSecondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Guardar") { save() }
                        .fontWeight(.semibold)
                        .foregroundStyle(canSave ? Theme.accent : Theme.textTertiary)
                        .disabled(!canSave)
                }
            }
        }
    }

    // MARK: - Sections

    private var kindSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(TransactionKind.allCases) { k in
                    Button { withAnimation { kind = k; resetForKind() } } label: {
                        VStack(spacing: 6) {
                            Image(systemName: k.icon)
                                .font(.system(size: 18, weight: .semibold))
                            Text(k.label)
                                .font(Theme.Font.caption.weight(.semibold))
                        }
                        .frame(width: 80, height: 70)
                        .foregroundStyle(kind == k ? Theme.background : Theme.textSecondary)
                        .background(kind == k ? Theme.accent : Theme.surface,
                                    in: RoundedRectangle(cornerRadius: Theme.cornerRadiusSmall, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.cornerRadiusSmall, style: .continuous)
                                .stroke(Theme.border, lineWidth: kind == k ? 0 : 0.5)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var amountField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("MONTO")
                .font(Theme.Font.caption)
                .foregroundStyle(Theme.textTertiary)
                .tracking(0.6)
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("RD$")
                    .font(Theme.Font.title)
                    .foregroundStyle(Theme.textTertiary)
                TextField("0", text: $amountText)
                    .keyboardType(.decimalPad)
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private var formCard: some View {
        VStack(spacing: 0) {
            field("Título") {
                TextField("Ej. Pedido de pizza", text: $title)
                    .textInputAutocapitalization(.sentences)
            }
            divider

            switch kind {
            case .income:
                pickerField("Cuenta destino", selection: $toAccount, options: accounts) { $0.name }
                divider
                pickerField("Categoría", selection: $category, options: availableCategories) { $0.name }
            case .expense:
                pickerField("Cuenta origen", selection: $fromAccount, options: accounts) { $0.name }
                divider
                pickerField("Categoría", selection: $category, options: availableCategories) { $0.name }
                divider
                pickerField("Método", selection: $paymentMethod, options: PaymentMethod.allCases) { $0.label }
            case .transfer, .savings:
                pickerField("Origen", selection: $fromAccount, options: accounts) { $0.name }
                divider
                pickerField("Destino", selection: $toAccount, options: accounts) { $0.name }
            case .cardPayment:
                pickerField("Cuenta origen", selection: $fromAccount, options: accounts.filter { $0.type != .credit }) { $0.name }
                divider
                pickerField("Tarjeta", selection: $toAccount, options: accounts.filter { $0.type == .credit }) { $0.name }
            }

            divider

            field("Fecha") {
                DatePicker("", selection: $occurredAt, displayedComponents: .date)
                    .labelsHidden()
                    .tint(Theme.accent)
            }
        }
        .padding(.horizontal, Theme.cardPadding)
        .padding(.vertical, 4)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                .stroke(Theme.border, lineWidth: 0.5)
        )
    }

    private var goalSelector: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Asignar a meta")
                .font(Theme.Font.caption)
                .foregroundStyle(Theme.textTertiary)
                .tracking(0.6)
            ForEach(goals) { goal in
                Button { selectedGoal = (selectedGoal == goal) ? nil : goal } label: {
                    HStack(spacing: 12) {
                        Image(systemName: goal.goalType.icon)
                            .foregroundStyle(goal.color)
                            .frame(width: 28)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(goal.name)
                                .font(Theme.Font.body.weight(.medium))
                                .foregroundStyle(Theme.textPrimary)
                            Text("\(Int(goal.progress * 100))% — faltan \(Money.format(goal.remainingAmount))")
                                .font(Theme.Font.caption)
                                .foregroundStyle(Theme.textTertiary)
                        }
                        Spacer()
                        Image(systemName: selectedGoal == goal ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(selectedGoal == goal ? Theme.accent : Theme.textTertiary)
                    }
                    .padding(.vertical, 10)
                }
                .buttonStyle(.plain)
                if goal.id != goals.last?.id { divider }
            }
        }
        .padding(.horizontal, Theme.cardPadding)
        .padding(.vertical, 12)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                .stroke(Theme.border, lineWidth: 0.5)
        )
    }

    private var notesCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("NOTA")
                .font(Theme.Font.caption)
                .foregroundStyle(Theme.textTertiary)
                .tracking(0.6)
            TextField("Opcional", text: $note, axis: .vertical)
                .lineLimit(2...4)
                .foregroundStyle(Theme.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    // MARK: - Field helpers

    @ViewBuilder
    private func field<Content: View>(_ label: String, @ViewBuilder content: () -> Content) -> some View {
        HStack {
            Text(label)
                .font(Theme.Font.body)
                .foregroundStyle(Theme.textSecondary)
                .frame(width: 110, alignment: .leading)
            content()
                .frame(maxWidth: .infinity, alignment: .trailing)
                .multilineTextAlignment(.trailing)
                .foregroundStyle(Theme.textPrimary)
        }
        .padding(.vertical, 12)
    }

    private func pickerField<T: Hashable>(_ label: String, selection: Binding<T?>, options: [T], display: @escaping (T) -> String) -> some View {
        field(label) {
            Menu {
                ForEach(options, id: \.self) { opt in
                    Button(display(opt)) { selection.wrappedValue = opt }
                }
            } label: {
                HStack(spacing: 4) {
                    Text(selection.wrappedValue.map(display) ?? "Seleccionar")
                        .foregroundStyle(selection.wrappedValue == nil ? Theme.textTertiary : Theme.textPrimary)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Theme.textTertiary)
                }
            }
        }
    }

    private func pickerField<T: Hashable>(_ label: String, selection: Binding<T>, options: [T], display: @escaping (T) -> String) -> some View {
        field(label) {
            Menu {
                ForEach(options, id: \.self) { opt in
                    Button(display(opt)) { selection.wrappedValue = opt }
                }
            } label: {
                HStack(spacing: 4) {
                    Text(display(selection.wrappedValue))
                        .foregroundStyle(Theme.textPrimary)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Theme.textTertiary)
                }
            }
        }
    }

    private var divider: some View {
        Rectangle().fill(Theme.border).frame(height: 0.5)
    }

    private func resetForKind() {
        category = nil
        if kind != .savings { selectedGoal = nil }
    }

    // MARK: - Save

    private func save() {
        let tx = Transaction(
            kind: kind,
            amount: amountValue,
            title: title,
            merchant: merchant,
            note: note,
            paymentMethod: paymentMethod,
            occurredAt: occurredAt,
            postedAt: .now,
            status: .posted,
            fromAccount: fromAccount,
            toAccount: toAccount,
            category: category
        )
        context.insert(tx)

        // Si es ahorro y hay meta seleccionada, crear la asignación.
        if kind == .savings, let goal = selectedGoal {
            let alloc = GoalAllocation(goal: goal, transaction: tx,
                                       movementType: .deposit, amount: amountValue)
            context.insert(alloc)
        }

        try? context.save()
        dismiss()
    }
}
