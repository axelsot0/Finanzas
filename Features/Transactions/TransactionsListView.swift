//
//  TransactionsListView.swift
//  Finanzas
//
//  Lista principal de movimientos con soporte para crear, editar y borrar.
//  Swipe izquierdo expone acciones; tap o swipe-editar abre TransactionEditorView.
//

import SwiftUI
import SwiftData

struct TransactionsListView: View {
    @Environment(\.modelContext) private var context

    @Query(sort: \Transaction.occurredAt, order: .reverse) private var transactions: [Transaction]

    @State private var filterKind: TransactionKind? = nil
    @State private var editing:    Transaction?      = nil
    @State private var newKind:    TransactionKind?  = nil
    @State private var txToDelete: Transaction?      = nil

    // MARK: - Derived

    private var filtered: [Transaction] {
        guard let f = filterKind else { return transactions }
        return transactions.filter { $0.kind == f }
    }

    private var grouped: [(String, [Transaction])] {
        let fmt = DateFormatter()
        fmt.dateFormat = "d 'de' MMMM"
        fmt.locale = Locale(identifier: "es_DO")
        let groups = Dictionary(grouping: filtered) { fmt.string(from: $0.occurredAt).capitalized }
        return groups.sorted {
            ($0.value.first?.occurredAt ?? .distantPast) > ($1.value.first?.occurredAt ?? .distantPast)
        }
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                filterBar
                    .padding(.horizontal, Theme.screenPadding)
                    .padding(.vertical, 12)

                if filtered.isEmpty {
                    ContentUnavailableView(
                        "Sin movimientos",
                        systemImage: "tray",
                        description: Text("Toca + para registrar tu primer movimiento")
                    )
                    .foregroundStyle(Theme.textSecondary)
                } else {
                    transactionList
                }
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("Movimientos")
            .navigationBarTitleDisplayMode(.large)
            .toolbar { addMenu }
            .sheet(item: $editing) { tx in
                TransactionEditorView(mode: .edit(tx))
            }
            .sheet(item: $newKind) { kind in
                TransactionEditorView(mode: .create(kind))
            }
            .confirmationDialog(
                "¿Eliminar movimiento?",
                isPresented: Binding(get: { txToDelete != nil },
                                     set: { if !$0 { txToDelete = nil } }),
                titleVisibility: .visible
            ) {
                Button("Eliminar", role: .destructive) {
                    if let tx = txToDelete {
                        context.delete(tx)
                        try? context.save()
                    }
                    txToDelete = nil
                }
                Button("Cancelar", role: .cancel) { txToDelete = nil }
            } message: {
                Text("Esta acción no se puede deshacer.")
            }
        }
    }

    // MARK: - List

    private var transactionList: some View {
        List {
            ForEach(grouped, id: \.0) { date, txs in
                Section {
                    ForEach(txs) { tx in
                        Button { editing = tx } label: {
                            TransactionRow(transaction: tx)
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(Theme.surface)
                        .listRowSeparatorTint(Theme.border)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                txToDelete = tx
                            } label: {
                                Label("Eliminar", systemImage: "trash")
                            }
                            Button { editing = tx } label: {
                                Label("Editar", systemImage: "pencil")
                            }
                            .tint(.blue)
                        }
                    }
                } header: {
                    Text(date.uppercased())
                        .font(Theme.Font.caption)
                        .foregroundStyle(Theme.textTertiary)
                        .tracking(0.6)
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
    }

    // MARK: - Filter Bar

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                pill(label: "Todos", isOn: filterKind == nil) { filterKind = nil }
                ForEach(TransactionKind.allCases) { kind in
                    pill(label: kind.label, icon: kind.icon, isOn: filterKind == kind) {
                        filterKind = (filterKind == kind) ? nil : kind
                    }
                }
            }
        }
    }

    private func pill(label: String, icon: String? = nil, isOn: Bool,
                      action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let icon { Image(systemName: icon).font(.system(size: 11, weight: .semibold)) }
                Text(label).font(Theme.Font.caption.weight(.semibold))
            }
            .padding(.horizontal, 12).padding(.vertical, 8)
            .foregroundStyle(isOn ? Theme.background : Theme.textSecondary)
            .background(isOn ? Theme.accent : Theme.surface, in: Capsule())
            .overlay(Capsule().stroke(Theme.border, lineWidth: isOn ? 0 : 0.5))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Add Menu

    @ToolbarContentBuilder
    private var addMenu: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                ForEach(TransactionKind.allCases) { kind in
                    Button { newKind = kind } label: {
                        Label(kind.label, systemImage: kind.icon)
                    }
                }
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Theme.background)
                    .frame(width: 32, height: 32)
                    .background(Theme.accent, in: Circle())
            }
        }
    }
}
