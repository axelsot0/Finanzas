//
//  TransactionEditorView.swift
//  Finanzas
//
//  Formulario unificado para crear y editar transacciones de cualquier tipo.
//  Recibe un Mode desde el exterior; el kind queda fijo en ambos casos.
//

import SwiftUI
import SwiftData

struct TransactionEditorView: View {
    @Environment(\.dismiss)      private var dismiss
    @Environment(\.modelContext) private var context

    @Query(sort: \Account.name)       private var accounts:   [Account]
    @Query(sort: \Category.sortOrder) private var categories: [Category]
    @Query(sort: \Goal.priority)      private var goals:      [Goal]

    @State private var vm: TransactionEditorViewModel
    @State private var showDeleteConfirm  = false
    @State private var showValidationAlert = false

    init(mode: TransactionEditorViewModel.Mode) {
        _vm = State(initialValue: TransactionEditorViewModel(mode: mode))
    }

    private var isEditMode: Bool {
        if case .edit = vm.mode { return true }
        return false
    }

    private var showGoalAllocations: Bool {
        vm.kind == .savings ||
        (vm.kind == .transfer && vm.toAccount?.type == .savings)
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    kindBadge
                    amountCard
                    mainCard
                    if showGoalAllocations { goalAllocationsCard }
                    detailsCard
                    if isEditMode { deleteButton }
                }
                .padding(Theme.screenPadding)
                .padding(.bottom, 40)
            }
            .scrollIndicators(.hidden)
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle(isEditMode ? "Editar movimiento" : "Nuevo movimiento")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancelar") { dismiss() }
                        .foregroundStyle(Theme.textSecondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Guardar") { attemptSave() }
                        .fontWeight(.semibold)
                        .foregroundStyle(vm.isValid ? Theme.accent : Theme.textTertiary)
                        .disabled(!vm.isValid)
                }
            }
            .confirmationDialog("¿Eliminar movimiento?",
                                isPresented: $showDeleteConfirm,
                                titleVisibility: .visible) {
                Button("Eliminar", role: .destructive) {
                    vm.delete(context: context)
                    dismiss()
                }
            } message: {
                Text("Esta acción no se puede deshacer.")
            }
            .alert("Datos incompletos", isPresented: $showValidationAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(vm.validationError ?? "")
            }
        }
    }

    // MARK: - Kind Badge

    private var kindBadge: some View {
        HStack(spacing: 6) {
            Image(systemName: vm.kind.icon)
                .font(.system(size: 12, weight: .semibold))
            Text(vm.kind.label)
                .font(Theme.Font.caption.weight(.semibold))
        }
        .padding(.horizontal, 12).padding(.vertical, 7)
        .foregroundStyle(.black)
        .background(kindAccentColor, in: Capsule())
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var kindAccentColor: Color {
        switch vm.kind {
        case .income:      return Theme.positive
        case .expense:     return Theme.danger
        case .transfer:    return Theme.info
        case .cardPayment: return Theme.warning
        case .savings:     return Theme.accent
        }
    }

    // MARK: - Amount Card

    private var amountCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("MONTO")
                .font(Theme.Font.caption)
                .foregroundStyle(Theme.textTertiary)
                .tracking(0.6)
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("RD$")
                    .font(Theme.Font.title)
                    .foregroundStyle(Theme.textTertiary)
                TextField("0", text: $vm.amountText)
                    .keyboardType(.decimalPad)
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    // MARK: - Main Card (título + cuentas + categoría)

    private var mainCard: some View {
        VStack(spacing: 0) {
            row("Título") {
                TextField("Ej. Pago de luz", text: $vm.title)
                    .textInputAutocapitalization(.sentences)
                    .multilineTextAlignment(.trailing)
                    .foregroundStyle(Theme.textPrimary)
            }

            if vm.kind.requiresFromAccount {
                divider
                row("Origen") {
                    accountMenu(selection: $vm.fromAccount, options: fromAccountOptions)
                }
            }

            if vm.kind.requiresToAccount {
                divider
                row("Destino") {
                    accountMenu(selection: $vm.toAccount, options: toAccountOptions)
                }
            }

            if vm.kind == .income || vm.kind == .expense {
                divider
                row("Categoría") {
                    categoryMenu
                }
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

    private var fromAccountOptions: [Account] {
        let active = accounts.filter { $0.isActive }
        return vm.kind == .cardPayment ? active.filter { $0.type != .credit } : active
    }

    private var toAccountOptions: [Account] {
        let active = accounts.filter { $0.isActive }
        return vm.kind == .cardPayment ? active.filter { $0.type == .credit } : active
    }

    @ViewBuilder
    private func accountMenu(selection: Binding<Account?>, options: [Account]) -> some View {
        Menu {
            Button("—") { selection.wrappedValue = nil }
            ForEach(options) { acc in
                Button(acc.name) { selection.wrappedValue = acc }
            }
        } label: {
            pickerLabel(selection.wrappedValue?.name)
        }
    }

    private var categoryMenu: some View {
        let kindFilter: CategoryKind = vm.kind == .income ? .income : .expense
        let filtered = categories.filter { $0.kind == kindFilter && $0.isActive }
        return Menu {
            Button("—") { vm.category = nil }
            ForEach(filtered) { cat in
                Button(cat.name) { vm.category = cat }
            }
        } label: {
            pickerLabel(vm.category?.name)
        }
    }

    // MARK: - Goal Allocations Card

    private var goalAllocationsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("DISTRIBUIR EN METAS")
                    .font(Theme.Font.caption)
                    .foregroundStyle(Theme.textTertiary)
                    .tracking(0.6)
                Spacer()
                let rem = vm.allocationsRemaining
                Text("Restante: \(Money.format(rem))")
                    .font(Theme.Font.caption)
                    .foregroundStyle(rem < -0.01 ? Theme.danger : Theme.textTertiary)
            }

            ForEach($vm.allocations) { $draft in
                allocationRow(draft: $draft)
            }

            addGoalMenu
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    @ViewBuilder
    private func allocationRow(draft: Binding<TransactionEditorViewModel.AllocationDraft>) -> some View {
        VStack(spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: draft.wrappedValue.goal.goalType.icon)
                    .foregroundStyle(draft.wrappedValue.goal.color)
                    .frame(width: 20)
                Text(draft.wrappedValue.goal.name)
                    .font(Theme.Font.body.weight(.medium))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                TextField("0", value: draft.amount, format: .number)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 90)
                    .font(Theme.Font.body.weight(.semibold))
                    .foregroundStyle(Theme.textPrimary)
                Button {
                    let id = draft.wrappedValue.id
                    vm.allocations.removeAll { $0.id == id }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .foregroundStyle(Theme.danger)
                        .font(.system(size: 18))
                }
            }
            Picker("", selection: draft.movementType) {
                Text("Aporte").tag(GoalAllocationType.deposit)
                Text("Retiro").tag(GoalAllocationType.withdrawal)
            }
            .pickerStyle(.segmented)
        }
        .padding(12)
        .background(Theme.surfaceElevated,
                    in: RoundedRectangle(cornerRadius: Theme.cornerRadiusSmall, style: .continuous))
    }

    private var addGoalMenu: some View {
        let usedIds  = Set(vm.allocations.map { $0.goal.id })
        let unused   = goals.filter { $0.status == .active && !usedIds.contains($0.id) }
        return Group {
            if !unused.isEmpty {
                Menu {
                    ForEach(unused) { goal in
                        Button(goal.name) {
                            vm.allocations.append(
                                TransactionEditorViewModel.AllocationDraft(
                                    goal: goal,
                                    amount: max(0, vm.allocationsRemaining),
                                    movementType: .deposit
                                )
                            )
                        }
                    }
                } label: {
                    Label("Agregar meta", systemImage: "plus.circle")
                        .font(Theme.Font.body.weight(.medium))
                        .foregroundStyle(Theme.accent)
                }
            }
        }
    }

    // MARK: - Details Card

    private var detailsCard: some View {
        VStack(spacing: 0) {
            row("Fecha") {
                DatePicker("", selection: $vm.occurredAt, displayedComponents: .date)
                    .labelsHidden()
                    .tint(Theme.accent)
            }
            divider
            row("Comerciante") {
                TextField("Opcional", text: $vm.merchant)
                    .multilineTextAlignment(.trailing)
                    .foregroundStyle(Theme.textPrimary)
            }
            divider
            row("Nota") {
                TextField("Opcional", text: $vm.note)
                    .multilineTextAlignment(.trailing)
                    .foregroundStyle(Theme.textPrimary)
            }
            divider
            row("Método") {
                Menu {
                    ForEach(PaymentMethod.allCases) { method in
                        Button(method.label) { vm.paymentMethod = method }
                    }
                } label: {
                    pickerLabel(vm.paymentMethod.label)
                }
            }
            divider
            row("Estado") {
                Menu {
                    Button("Publicado") { vm.status = .posted  }
                    Button("Pendiente") { vm.status = .pending }
                    Button("Anulado")   { vm.status = .void    }
                } label: {
                    pickerLabel(statusLabel)
                }
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

    private var statusLabel: String {
        switch vm.status {
        case .posted:  return "Publicado"
        case .pending: return "Pendiente"
        case .void:    return "Anulado"
        }
    }

    // MARK: - Delete Button

    private var deleteButton: some View {
        Button(role: .destructive) {
            showDeleteConfirm = true
        } label: {
            Text("Eliminar movimiento")
                .font(Theme.Font.body.weight(.semibold))
                .foregroundStyle(Theme.danger)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Theme.danger.opacity(0.12),
                            in: RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
        }
    }

    // MARK: - Shared Helpers

    private var divider: some View {
        Rectangle().fill(Theme.border).frame(height: 0.5)
    }

    @ViewBuilder
    private func row<Content: View>(_ label: String,
                                    @ViewBuilder content: () -> Content) -> some View {
        HStack {
            Text(label)
                .font(Theme.Font.body)
                .foregroundStyle(Theme.textSecondary)
                .frame(width: 110, alignment: .leading)
            content()
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.vertical, 12)
    }

    private func pickerLabel(_ text: String?) -> some View {
        HStack(spacing: 4) {
            Text(text ?? "Seleccionar")
                .foregroundStyle(text == nil ? Theme.textTertiary : Theme.textPrimary)
            Image(systemName: "chevron.up.chevron.down")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Theme.textTertiary)
        }
    }

    private func attemptSave() {
        guard vm.isValid else { showValidationAlert = true; return }
        vm.save(context: context)
        dismiss()
    }
}
