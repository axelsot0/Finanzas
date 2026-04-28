//
//  CategoriesView.swift
//  Finanzas
//
//  Lista de categorías agrupada por tipo (Ingreso / Gasto / Transferencia).
//  Soporta crear, editar y borrar. Las categorías de sistema no se pueden borrar.
//

import SwiftUI
import SwiftData

struct CategoriesView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: [SortDescriptor(\Category.sortOrder), SortDescriptor(\Category.name)])
    private var categories: [Category]

    @State private var showNew     = false
    @State private var editing:   Category? = nil
    @State private var toDelete:  Category? = nil

    private var grouped: [(CategoryKind, [Category])] {
        let dict = Dictionary(grouping: categories) { $0.kind }
        return CategoryKind.allCases.compactMap { k in
            guard let arr = dict[k], !arr.isEmpty else { return nil }
            return (k, arr)
        }
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Group {
                if categories.isEmpty {
                    ContentUnavailableView(
                        "Sin categorías",
                        systemImage: "tag",
                        description: Text("Toca + para crear tu primera categoría")
                    )
                    .foregroundStyle(Theme.textSecondary)
                } else {
                    list
                }
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("Categorías")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showNew = true } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Theme.background)
                            .frame(width: 32, height: 32)
                            .background(Theme.accent, in: Circle())
                    }
                }
            }
            .sheet(isPresented: $showNew) {
                CategoryEditorView(mode: .create)
            }
            .sheet(item: $editing) { c in
                CategoryEditorView(mode: .edit(c))
            }
            .confirmationDialog(
                "¿Eliminar categoría?",
                isPresented: Binding(get: { toDelete != nil },
                                     set: { if !$0 { toDelete = nil } }),
                titleVisibility: .visible
            ) {
                Button("Eliminar", role: .destructive) {
                    if let c = toDelete {
                        context.delete(c)
                        try? context.save()
                    }
                    toDelete = nil
                }
                Button("Cancelar", role: .cancel) { toDelete = nil }
            } message: {
                Text("Las transacciones asociadas se quedarán sin categoría.")
            }
        }
    }

    // MARK: - List

    private var list: some View {
        List {
            ForEach(grouped, id: \.0) { kind, cats in
                Section {
                    ForEach(cats) { cat in
                        Button { editing = cat } label: {
                            CategoryRow(category: cat)
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(Theme.surface)
                        .listRowSeparatorTint(Theme.border)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            if !cat.isSystem {
                                Button(role: .destructive) {
                                    toDelete = cat
                                } label: {
                                    Label("Eliminar", systemImage: "trash")
                                }
                            }
                            Button { editing = cat } label: {
                                Label("Editar", systemImage: "pencil")
                            }
                            .tint(.blue)
                        }
                    }
                } header: {
                    Text(kind.label.uppercased())
                        .font(Theme.Font.caption)
                        .foregroundStyle(Theme.textTertiary)
                        .tracking(0.6)
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
    }
}

// MARK: - Row

private struct CategoryRow: View {
    let category: Category

    private var color: Color { Color(hex: category.colorHex) ?? Theme.accent }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(color.opacity(0.18))
                Image(systemName: category.icon)
                    .foregroundStyle(color)
                    .font(.system(size: 14, weight: .semibold))
            }
            .frame(width: 36, height: 36)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(category.name)
                        .font(Theme.Font.body.weight(.medium))
                        .foregroundStyle(Theme.textPrimary)
                    if category.isSystem {
                        Text("SISTEMA")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(Theme.textTertiary)
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Theme.surfaceElevated, in: Capsule())
                    }
                    if !category.isActive {
                        Text("INACTIVA")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(Theme.warning)
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Theme.warning.opacity(0.15), in: Capsule())
                    }
                }
                if let budget = category.monthlyBudget, budget > 0 {
                    Text("Presupuesto: \(Money.format(budget))/mes")
                        .font(Theme.Font.caption)
                        .foregroundStyle(Theme.textTertiary)
                }
            }
            Spacer()
            Text("\(category.transactions.count)")
                .font(Theme.Font.caption.weight(.semibold))
                .foregroundStyle(Theme.textTertiary)
                .monospacedDigit()
        }
        .padding(.vertical, 4)
    }
}
