//
//  GoalEditorView.swift
//  Finanzas
//
//  Editor unificado para crear o editar metas. Espejo de TransactionEditorView.
//  No reemplaza a NewGoalView; ese sigue funcionando para crear desde otros lugares.
//

import SwiftUI
import SwiftData

struct GoalEditorView: View {
    @Environment(\.dismiss)      private var dismiss
    @Environment(\.modelContext) private var context

    enum Mode {
        case create
        case edit(Goal)
    }

    let mode: Mode

    @State private var name: String
    @State private var goalType: GoalType
    @State private var targetText: String
    @State private var startText: String
    @State private var contributionPeriod: ContributionPeriod
    @State private var plannedText: String
    @State private var targetDate: Date
    @State private var hasTargetDate: Bool
    @State private var priority: Int
    @State private var colorHex: String
    @State private var notes: String
    @State private var status: GoalStatus

    @State private var showDeleteConfirm = false

    private let palette = ["#6CF1BD", "#7CC1FF", "#C5A6FF", "#FFB14E",
                           "#FF8E5C", "#FF6B9D", "#FFD55C", "#9CE37D"]

    init(mode: Mode) {
        self.mode = mode
        switch mode {
        case .create:
            _name               = State(initialValue: "")
            _goalType           = State(initialValue: .purchase)
            _targetText         = State(initialValue: "")
            _startText          = State(initialValue: "")
            _contributionPeriod = State(initialValue: .biweekly)
            _plannedText        = State(initialValue: "")
            _targetDate         = State(initialValue: Calendar.current.date(byAdding: .month, value: 6, to: .now)!)
            _hasTargetDate      = State(initialValue: false)
            _priority           = State(initialValue: 1)
            _colorHex           = State(initialValue: "#6CF1BD")
            _notes              = State(initialValue: "")
            _status             = State(initialValue: .active)
        case .edit(let g):
            _name               = State(initialValue: g.name)
            _goalType           = State(initialValue: g.goalType)
            _targetText         = State(initialValue: numString(g.targetAmount))
            _startText          = State(initialValue: numString(g.startAmount))
            _contributionPeriod = State(initialValue: g.contributionPeriod)
            _plannedText        = State(initialValue: numString(g.plannedAmountPerPeriod))
            _targetDate         = State(initialValue: g.targetDate ?? Calendar.current.date(byAdding: .month, value: 6, to: .now)!)
            _hasTargetDate      = State(initialValue: g.targetDate != nil)
            _priority           = State(initialValue: g.priority)
            _colorHex           = State(initialValue: g.colorHex)
            _notes              = State(initialValue: g.notes)
            _status             = State(initialValue: g.status)
        }
    }

    private var isEdit: Bool {
        if case .edit = mode { return true }
        return false
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        (Double(targetText) ?? 0) > 0
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    nameTypeCard
                    amountsCard
                    targetDateCard
                    colorCard
                    if isEdit { deleteButton }
                }
                .padding(Theme.screenPadding)
                .padding(.bottom, 40)
            }
            .scrollIndicators(.hidden)
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle(isEdit ? "Editar meta" : "Nueva meta")
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
            .confirmationDialog("¿Eliminar meta?",
                                isPresented: $showDeleteConfirm,
                                titleVisibility: .visible) {
                Button("Eliminar", role: .destructive) { deleteGoal() }
            } message: {
                Text("Se borrarán todos los aportes asociados. Esta acción no se puede deshacer.")
            }
        }
    }

    // MARK: - Cards

    private var nameTypeCard: some View {
        VStack(spacing: 0) {
            field("Nombre") {
                TextField("Ej. Carro, MacBook Pro", text: $name)
                    .textInputAutocapitalization(.words)
                    .multilineTextAlignment(.trailing)
                    .foregroundStyle(Theme.textPrimary)
            }
            divider
            field("Tipo") {
                Menu {
                    ForEach(GoalType.allCases) { t in
                        Button { goalType = t } label: {
                            Label(t.label, systemImage: t.icon)
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: goalType.icon)
                        Text(goalType.label)
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Theme.textTertiary)
                    }
                    .foregroundStyle(Theme.textPrimary)
                }
            }
            if isEdit {
                divider
                field("Estado") {
                    Menu {
                        ForEach(GoalStatus.allCases, id: \.self) { s in
                            Button(s.label) { status = s }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(status.label)
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(Theme.textTertiary)
                        }
                        .foregroundStyle(Theme.textPrimary)
                    }
                }
            }
        }
        .padding(.horizontal, Theme.cardPadding)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                .stroke(Theme.border, lineWidth: 0.5)
        )
    }

    private var amountsCard: some View {
        VStack(spacing: 0) {
            field("Objetivo") {
                TextField("0", text: $targetText)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .foregroundStyle(Theme.textPrimary)
            }
            divider
            field("Inicio") {
                TextField("0", text: $startText)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .foregroundStyle(Theme.textPrimary)
            }
            divider
            field("Aporte") {
                TextField("0", text: $plannedText)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .foregroundStyle(Theme.textPrimary)
            }
            divider
            field("Periodo") {
                Menu {
                    ForEach(ContributionPeriod.allCases) { p in
                        Button(p.label) { contributionPeriod = p }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(contributionPeriod.label)
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Theme.textTertiary)
                    }
                    .foregroundStyle(Theme.textPrimary)
                }
            }
        }
        .padding(.horizontal, Theme.cardPadding)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                .stroke(Theme.border, lineWidth: 0.5)
        )
    }

    private var targetDateCard: some View {
        VStack(spacing: 0) {
            field("Fecha objetivo") {
                Toggle("", isOn: $hasTargetDate)
                    .labelsHidden()
                    .tint(Theme.accent)
            }
            if hasTargetDate {
                divider
                field("Cuándo") {
                    DatePicker("", selection: $targetDate, displayedComponents: .date)
                        .labelsHidden()
                        .tint(Theme.accent)
                }
            }
        }
        .padding(.horizontal, Theme.cardPadding)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                .stroke(Theme.border, lineWidth: 0.5)
        )
    }

    private var colorCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("COLOR")
                .font(Theme.Font.caption)
                .foregroundStyle(Theme.textTertiary)
                .tracking(0.6)
            HStack(spacing: 12) {
                ForEach(palette, id: \.self) { hex in
                    Button { colorHex = hex } label: {
                        ZStack {
                            Circle()
                                .fill(Color(hex: hex) ?? .gray)
                                .frame(width: 34, height: 34)
                            if colorHex == hex {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.black)
                                    .font(.system(size: 14, weight: .bold))
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private var deleteButton: some View {
        Button(role: .destructive) {
            showDeleteConfirm = true
        } label: {
            Text("Eliminar meta")
                .font(Theme.Font.body.weight(.semibold))
                .foregroundStyle(Theme.danger)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Theme.danger.opacity(0.12),
                            in: RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
        }
    }

    // MARK: - Helpers

    @ViewBuilder
    private func field<Content: View>(_ label: String,
                                      @ViewBuilder content: () -> Content) -> some View {
        HStack {
            Text(label)
                .font(Theme.Font.body)
                .foregroundStyle(Theme.textSecondary)
                .frame(width: 130, alignment: .leading)
            content()
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.vertical, 12)
    }

    private var divider: some View {
        Rectangle().fill(Theme.border).frame(height: 0.5)
    }

    // MARK: - Actions

    private func save() {
        let target  = Double(targetText)  ?? 0
        let startA  = Double(startText)   ?? 0
        let planned = Double(plannedText) ?? 0

        switch mode {
        case .create:
            let g = Goal(
                name: name,
                goalType: goalType,
                targetAmount: target,
                startAmount: startA,
                startDate: .now,
                targetDate: hasTargetDate ? targetDate : nil,
                contributionPeriod: contributionPeriod,
                plannedAmountPerPeriod: planned,
                priority: priority,
                status: status,
                colorHex: colorHex,
                notes: notes
            )
            context.insert(g)

        case .edit(let g):
            g.name                   = name
            g.goalType               = goalType
            g.targetAmount           = target
            g.startAmount            = startA
            g.targetDate             = hasTargetDate ? targetDate : nil
            g.contributionPeriod     = contributionPeriod
            g.plannedAmountPerPeriod = planned
            g.priority               = priority
            g.status                 = status
            g.colorHex               = colorHex
            g.notes                  = notes
        }
        try? context.save()
        dismiss()
    }

    private func deleteGoal() {
        guard case .edit(let g) = mode else { return }
        context.delete(g)
        try? context.save()
        dismiss()
    }
}

// MARK: - Helpers

private func numString(_ v: Double) -> String {
    v.truncatingRemainder(dividingBy: 1) == 0 ? String(Int(v)) : String(v)
}
