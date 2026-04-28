//
//  GoalDetailView.swift
//  Finanzas
//
//  Vista de detalle al tocar una meta: encabezado, gráfico de evolución,
//  histórico de aportes, totales y acciones rápidas.
//

import SwiftUI
import SwiftData
import Charts

struct GoalDetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Bindable var goal: Goal
    @State private var showQuickAdd = false
    @State private var quickAmountText: String = ""
    @State private var showEditor = false
    @State private var showDeleteConfirm = false

    private var sortedAllocations: [GoalAllocation] {
        goal.allocations.sorted { ($0.transaction?.occurredAt ?? .distantPast) > ($1.transaction?.occurredAt ?? .distantPast) }
    }

    private var chartData: [(date: Date, total: Double)] {
        // Acumula los aportes en orden cronológico para mostrar evolución.
        let sorted = goal.allocations.sorted {
            ($0.transaction?.occurredAt ?? .distantPast) < ($1.transaction?.occurredAt ?? .distantPast)
        }
        var running = goal.startAmount
        var points: [(Date, Double)] = [(goal.startDate, running)]
        for a in sorted {
            running += a.signedAmount
            points.append((a.transaction?.occurredAt ?? .now, running))
        }
        return points.map { (date: $0.0, total: $0.1) }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                // Encabezado
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        ZStack {
                            Circle().fill(goal.color.opacity(0.18))
                            Image(systemName: goal.goalType.icon)
                                .foregroundStyle(goal.color)
                                .font(.system(size: 22, weight: .semibold))
                        }
                        .frame(width: 56, height: 56)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(goal.name)
                                .font(Theme.Font.title)
                                .foregroundStyle(Theme.textPrimary)
                            Text("\(goal.goalType.label) · \(goal.contributionPeriod.label)")
                                .font(Theme.Font.caption)
                                .foregroundStyle(Theme.textTertiary)
                        }
                        Spacer()
                    }

                    Text(Money.format(goal.savedAmount))
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.textPrimary)
                    Text("de \(Money.format(goal.targetAmount))")
                        .font(Theme.Font.body)
                        .foregroundStyle(Theme.textSecondary)

                    ThinProgressBar(progress: goal.progress, color: goal.health.color, height: 6)

                    HStack(spacing: 10) {
                        statChip(label: "Faltante", value: Money.format(goal.remainingAmount))
                        statChip(label: "Avance",   value: "\(Int(goal.progress * 100))%")
                        statChip(label: "Salud",    value: healthLabel(goal.health), color: goal.health.color)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .cardStyle()

                // Gráfico de evolución
                if !goal.allocations.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("EVOLUCIÓN")
                            .font(Theme.Font.caption)
                            .foregroundStyle(Theme.textTertiary)
                            .tracking(0.6)
                        Chart {
                            ForEach(chartData, id: \.date) { point in
                                LineMark(x: .value("Fecha", point.date),
                                         y: .value("Total", point.total))
                                    .foregroundStyle(goal.color)
                                    .interpolationMethod(.monotone)
                                AreaMark(x: .value("Fecha", point.date),
                                         y: .value("Total", point.total))
                                    .foregroundStyle(
                                        LinearGradient(colors: [goal.color.opacity(0.35), .clear],
                                                       startPoint: .top, endPoint: .bottom)
                                    )
                                    .interpolationMethod(.monotone)
                            }
                        }
                        .frame(height: 140)
                        .chartXAxis { AxisMarks(values: .automatic(desiredCount: 3)) }
                        .chartYAxis { AxisMarks(values: .automatic(desiredCount: 3)) }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .cardStyle()
                }

                // Acciones rápidas
                HStack(spacing: 10) {
                    actionButton(label: "Aportar", icon: "plus.circle.fill", primary: true) {
                        showQuickAdd = true
                    }
                    actionButton(label: goal.status == .active ? "Pausar" : "Reactivar",
                                 icon: goal.status == .active ? "pause.fill" : "play.fill") {
                        goal.status = goal.status == .active ? .paused : .active
                        try? context.save()
                    }
                    actionButton(label: "Completar", icon: "checkmark.seal.fill") {
                        goal.status = .completed
                        try? context.save()
                    }
                }

                // Histórico
                VStack(alignment: .leading, spacing: 8) {
                    Text("HISTÓRICO DE APORTES")
                        .font(Theme.Font.caption)
                        .foregroundStyle(Theme.textTertiary)
                        .tracking(0.6)

                    if sortedAllocations.isEmpty {
                        Text("Aún no hay aportes registrados")
                            .font(Theme.Font.body)
                            .foregroundStyle(Theme.textTertiary)
                            .padding(.vertical, 20)
                            .frame(maxWidth: .infinity)
                    } else {
                        VStack(spacing: 0) {
                            ForEach(sortedAllocations) { alloc in
                                allocationRow(alloc)
                                if alloc.id != sortedAllocations.last?.id {
                                    Divider().background(Theme.border)
                                }
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(Theme.cardPadding)
                .background(Theme.surface)
                .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                        .stroke(Theme.border, lineWidth: 0.5)
                )
            }
            .padding(.horizontal, Theme.screenPadding)
            .padding(.bottom, 80)
        }
        .scrollIndicators(.hidden)
        .background(Theme.background.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button { showEditor = true } label: {
                        Label("Editar", systemImage: "pencil")
                    }
                    Button(role: .destructive) {
                        showDeleteConfirm = true
                    } label: {
                        Label("Eliminar", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                }
            }
        }
        .sheet(isPresented: $showQuickAdd) {
            quickAddSheet
        }
        .sheet(isPresented: $showEditor) {
            GoalEditorView(mode: .edit(goal))
        }
        .confirmationDialog("¿Eliminar meta?",
                            isPresented: $showDeleteConfirm,
                            titleVisibility: .visible) {
            Button("Eliminar", role: .destructive) {
                context.delete(goal)
                try? context.save()
                dismiss()
            }
        } message: {
            Text("Se borrarán los aportes asociados. No se puede deshacer.")
        }
    }

    // MARK: - Aporte rápido

    private var quickAddSheet: some View {
        NavigationStack {
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("APORTAR A \(goal.name.uppercased())")
                        .font(Theme.Font.caption)
                        .foregroundStyle(Theme.textTertiary)
                        .tracking(0.6)
                    HStack(alignment: .firstTextBaseline) {
                        Text("RD$")
                            .font(Theme.Font.title)
                            .foregroundStyle(Theme.textTertiary)
                        TextField("0", text: $quickAmountText)
                            .keyboardType(.decimalPad)
                            .font(.system(size: 44, weight: .bold, design: .rounded))
                            .foregroundStyle(Theme.textPrimary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .cardStyle()
                Spacer()
            }
            .padding(Theme.screenPadding)
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("Nuevo aporte")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancelar") {
                        quickAmountText = ""
                        showQuickAdd = false
                    }
                    .foregroundStyle(Theme.textSecondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Guardar") { saveQuickAdd() }
                        .fontWeight(.semibold)
                        .foregroundStyle((Double(quickAmountText) ?? 0) > 0 ? Theme.accent : Theme.textTertiary)
                        .disabled((Double(quickAmountText) ?? 0) <= 0)
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func saveQuickAdd() {
        let amount = Double(quickAmountText) ?? 0
        guard amount > 0 else { return }
        let tx = Transaction(kind: .savings, amount: amount, title: "Aporte \(goal.name)")
        context.insert(tx)
        let alloc = GoalAllocation(goal: goal, transaction: tx, movementType: .deposit, amount: amount)
        context.insert(alloc)
        try? context.save()
        quickAmountText = ""
        showQuickAdd = false
    }

    // MARK: - Sub-componentes

    private func statChip(label: String, value: String, color: Color = Theme.textPrimary) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label.uppercased())
                .font(Theme.Font.caption)
                .foregroundStyle(Theme.textTertiary)
                .tracking(0.5)
            Text(value)
                .font(Theme.Font.body.weight(.semibold))
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12).padding(.vertical, 8)
        .background(Theme.surfaceElevated, in: RoundedRectangle(cornerRadius: Theme.cornerRadiusSmall, style: .continuous))
    }

    private func actionButton(label: String, icon: String, primary: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                Text(label)
                    .font(Theme.Font.caption.weight(.semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .foregroundStyle(primary ? Theme.background : Theme.textPrimary)
            .background(primary ? Theme.accent : Theme.surface,
                        in: RoundedRectangle(cornerRadius: Theme.cornerRadiusSmall, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cornerRadiusSmall, style: .continuous)
                    .stroke(Theme.border, lineWidth: primary ? 0 : 0.5)
            )
        }
        .buttonStyle(.plain)
    }

    private func allocationRow(_ alloc: GoalAllocation) -> some View {
        HStack {
            Image(systemName: alloc.movementType == .deposit ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                .foregroundStyle(alloc.movementType == .deposit ? Theme.positive : Theme.danger)
            VStack(alignment: .leading, spacing: 2) {
                Text(alloc.transaction?.title.isEmpty == false ? alloc.transaction!.title : "Aporte")
                    .font(Theme.Font.body.weight(.medium))
                    .foregroundStyle(Theme.textPrimary)
                Text(alloc.transaction?.occurredAt ?? .now, format: .dateTime.day().month(.abbreviated).year())
                    .font(Theme.Font.caption)
                    .foregroundStyle(Theme.textTertiary)
            }
            Spacer()
            Text("\(alloc.movementType == .deposit ? "+" : "−")\(Money.format(alloc.amount))")
                .font(Theme.Font.body.weight(.semibold))
                .foregroundStyle(alloc.movementType == .deposit ? Theme.positive : Theme.danger)
                .monospacedDigit()
        }
        .padding(.vertical, 10)
    }

    private func healthLabel(_ h: HealthStatus) -> String {
        switch h {
        case .good:    return "Al día"
        case .warning: return "Lento"
        case .danger:  return "Atrasado"
        case .neutral: return "—"
        }
    }
}
