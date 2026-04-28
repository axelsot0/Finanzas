//
//  CategoryEditorView.swift
//  Finanzas
//
//  Editor unificado para crear y editar categorías.
//

import SwiftUI
import SwiftData

struct CategoryEditorView: View {
    @Environment(\.dismiss)      private var dismiss
    @Environment(\.modelContext) private var context

    enum Mode {
        case create
        case edit(Category)
    }

    let mode: Mode

    @State private var name: String
    @State private var kind: CategoryKind
    @State private var colorHex: String
    @State private var icon: String
    @State private var budgetText: String
    @State private var isActive: Bool

    @State private var showDeleteConfirm = false

    private let palette = ["#6CF1BD", "#7CC1FF", "#C5A6FF", "#FFB14E",
                           "#FF8E5C", "#FF6B9D", "#FFD55C", "#9CE37D",
                           "#FF6B6F", "#1DB954", "#000000", "#FFFFFF"]

    private let icons = [
        "dollarsign.circle.fill", "sparkles", "bag.fill", "fuelpump.fill",
        "bolt.fill", "music.note", "car.fill", "pawprint.fill",
        "graduationcap.fill", "cart.fill", "wineglass.fill", "house.fill",
        "tram.fill", "airplane", "heart.fill", "gift.fill",
        "cup.and.saucer.fill", "fork.knife", "tshirt.fill", "phone.fill",
        "wifi", "tv.fill", "stethoscope", "creditcard.fill",
        "leaf.fill", "shield.fill", "banknote.fill", "circle.fill"
    ]

    init(mode: Mode) {
        self.mode = mode
        switch mode {
        case .create:
            _name       = State(initialValue: "")
            _kind       = State(initialValue: .expense)
            _colorHex   = State(initialValue: "#6CF1BD")
            _icon       = State(initialValue: "circle.fill")
            _budgetText = State(initialValue: "")
            _isActive   = State(initialValue: true)
        case .edit(let c):
            _name       = State(initialValue: c.name)
            _kind       = State(initialValue: c.kind)
            _colorHex   = State(initialValue: c.colorHex)
            _icon       = State(initialValue: c.icon)
            _budgetText = State(initialValue: c.monthlyBudget.map { numString($0) } ?? "")
            _isActive   = State(initialValue: c.isActive)
        }
    }

    private var isEdit: Bool {
        if case .edit = mode { return true }
        return false
    }

    private var editingSystem: Bool {
        if case .edit(let c) = mode { return c.isSystem }
        return false
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    previewCard
                    detailsCard
                    iconCard
                    colorCard
                    if kind == .expense {
                        budgetCard
                    }
                    activeCard
                    if isEdit && !editingSystem { deleteButton }
                }
                .padding(Theme.screenPadding)
                .padding(.bottom, 40)
            }
            .scrollIndicators(.hidden)
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle(isEdit ? "Editar categoría" : "Nueva categoría")
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
            .confirmationDialog("¿Eliminar categoría?",
                                isPresented: $showDeleteConfirm,
                                titleVisibility: .visible) {
                Button("Eliminar", role: .destructive) { deleteCat() }
            } message: {
                Text("Las transacciones asociadas se quedarán sin categoría. No se puede deshacer.")
            }
        }
    }

    // MARK: - Cards

    private var previewCard: some View {
        let c = Color(hex: colorHex) ?? Theme.accent
        return HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(c.opacity(0.18))
                Image(systemName: icon)
                    .foregroundStyle(c)
                    .font(.system(size: 20, weight: .semibold))
            }
            .frame(width: 48, height: 48)
            VStack(alignment: .leading, spacing: 2) {
                Text(name.isEmpty ? "Nombre" : name)
                    .font(Theme.Font.headline)
                    .foregroundStyle(name.isEmpty ? Theme.textTertiary : Theme.textPrimary)
                Text(kind.label)
                    .font(Theme.Font.caption)
                    .foregroundStyle(Theme.textTertiary)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private var detailsCard: some View {
        VStack(spacing: 0) {
            field("Nombre") {
                TextField("Ej. Mercado", text: $name)
                    .textInputAutocapitalization(.sentences)
                    .multilineTextAlignment(.trailing)
                    .foregroundStyle(Theme.textPrimary)
            }
            divider
            field("Tipo") {
                Menu {
                    ForEach(CategoryKind.allCases) { k in
                        Button(k.label) { kind = k }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(kind.label)
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

    private var iconCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("ÍCONO")
                .font(Theme.Font.caption)
                .foregroundStyle(Theme.textTertiary)
                .tracking(0.6)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 7), spacing: 8) {
                ForEach(icons, id: \.self) { sym in
                    Button { icon = sym } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(icon == sym ? (Color(hex: colorHex) ?? Theme.accent).opacity(0.25) : Theme.surfaceElevated)
                            Image(systemName: sym)
                                .foregroundStyle(icon == sym ? (Color(hex: colorHex) ?? Theme.accent) : Theme.textSecondary)
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .frame(height: 40)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private var colorCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("COLOR")
                .font(Theme.Font.caption)
                .foregroundStyle(Theme.textTertiary)
                .tracking(0.6)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 6), spacing: 10) {
                ForEach(palette, id: \.self) { hex in
                    Button { colorHex = hex } label: {
                        ZStack {
                            Circle()
                                .fill(Color(hex: hex) ?? .gray)
                                .frame(width: 36, height: 36)
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

    private var budgetCard: some View {
        VStack(spacing: 0) {
            field("Presupuesto") {
                TextField("Opcional", text: $budgetText)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .foregroundStyle(Theme.textPrimary)
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

    private var activeCard: some View {
        VStack(spacing: 0) {
            field("Activa") {
                Toggle("", isOn: $isActive)
                    .labelsHidden()
                    .tint(Theme.accent)
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

    private var deleteButton: some View {
        Button(role: .destructive) {
            showDeleteConfirm = true
        } label: {
            Text("Eliminar categoría")
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
        let budget: Double? = {
            let v = Double(budgetText) ?? 0
            return v > 0 ? v : nil
        }()

        switch mode {
        case .create:
            let c = Category(
                name: name,
                kind: kind,
                colorHex: colorHex,
                icon: icon,
                monthlyBudget: budget,
                isSystem: false,
                isActive: isActive,
                sortOrder: 0
            )
            context.insert(c)

        case .edit(let c):
            c.name          = name
            c.kind          = kind
            c.colorHex      = colorHex
            c.icon          = icon
            c.monthlyBudget = budget
            c.isActive      = isActive
        }
        try? context.save()
        dismiss()
    }

    private func deleteCat() {
        guard case .edit(let c) = mode else { return }
        context.delete(c)
        try? context.save()
        dismiss()
    }
}

private func numString(_ v: Double) -> String {
    v.truncatingRemainder(dividingBy: 1) == 0 ? String(Int(v)) : String(v)
}
