//
//  NewGoalView.swift
//  Finanzas
//
//  Formulario para crear una nueva meta financiera.
//

import SwiftUI
import SwiftData

struct NewGoalView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @State private var name = ""
    @State private var goalType: GoalType = .purchase
    @State private var targetText = ""
    @State private var startText = ""
    @State private var contributionPeriod: ContributionPeriod = .biweekly
    @State private var plannedText = ""
    @State private var targetDate: Date = Calendar.current.date(byAdding: .month, value: 6, to: .now)!
    @State private var hasTargetDate = false
    @State private var priority: Int = 1
    @State private var colorHex = "#6CF1BD"
    @State private var notes = ""

    private let palette = ["#6CF1BD", "#7CC1FF", "#C5A6FF", "#FFB14E", "#FF8E5C", "#FF6B9D", "#FFD55C", "#9CE37D"]

    private var canSave: Bool {
        !name.isEmpty && (Double(targetText) ?? 0) > 0
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Nombre + tipo
                    VStack(spacing: 0) {
                        field("Nombre") {
                            TextField("Ej. Carro, MacBook Pro", text: $name)
                                .textInputAutocapitalization(.words)
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
                    }
                    .padding(.horizontal, Theme.cardPadding)
                    .background(Theme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                            .stroke(Theme.border, lineWidth: 0.5)
                    )

                    // Montos
                    VStack(spacing: 0) {
                        field("Objetivo") {
                            TextField("0", text: $targetText)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                        }
                        divider
                        field("Inicio") {
                            TextField("0", text: $startText)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                        }
                        divider
                        field("Aporte") {
                            TextField("0", text: $plannedText)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
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

                    // Fecha objetivo
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

                    // Color
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
                .padding(Theme.screenPadding)
                .padding(.bottom, 40)
            }
            .scrollIndicators(.hidden)
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("Nueva meta")
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

    private var divider: some View {
        Rectangle().fill(Theme.border).frame(height: 0.5)
    }

    private func save() {
        let g = Goal(
            name: name,
            goalType: goalType,
            targetAmount: Double(targetText) ?? 0,
            startAmount: Double(startText) ?? 0,
            startDate: .now,
            targetDate: hasTargetDate ? targetDate : nil,
            contributionPeriod: contributionPeriod,
            plannedAmountPerPeriod: Double(plannedText) ?? 0,
            priority: priority,
            status: .active,
            colorHex: colorHex,
            notes: notes
        )
        context.insert(g)
        try? context.save()
        dismiss()
    }
}
