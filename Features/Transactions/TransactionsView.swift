//
//  TransactionsView.swift
//  Finanzas
//
//  Lista de movimientos con filtros básicos por tipo. Botón flotante para crear nuevo.
//

import SwiftUI
import SwiftData

struct TransactionsView: View {
    @Query(sort: \Transaction.occurredAt, order: .reverse) private var transactions: [Transaction]
    @State private var filterKind: TransactionKind? = nil
    @State private var showNewTransaction = false

    private var filtered: [Transaction] {
        guard let f = filterKind else { return transactions }
        return transactions.filter { $0.kind == f }
    }

    private var grouped: [(String, [Transaction])] {
        let groups = Dictionary(grouping: filtered) { tx -> String in
            let f = DateFormatter()
            f.dateFormat = "d 'de' MMMM"
            f.locale = Locale(identifier: "es_DO")
            return f.string(from: tx.occurredAt).capitalized
        }
        return groups.sorted { lhs, rhs in
            let l = lhs.value.first?.occurredAt ?? .distantPast
            let r = rhs.value.first?.occurredAt ?? .distantPast
            return l > r
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                filterBar
                    .padding(.horizontal, Theme.screenPadding)
                    .padding(.vertical, 12)

                if filtered.isEmpty {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "tray")
                            .font(.system(size: 40))
                            .foregroundStyle(Theme.textTertiary)
                        Text("Sin movimientos aún")
                            .font(Theme.Font.headline)
                            .foregroundStyle(Theme.textSecondary)
                        Text("Toca + para registrar tu primer gasto o ingreso")
                            .font(Theme.Font.body)
                            .foregroundStyle(Theme.textTertiary)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            ForEach(grouped, id: \.0) { date, txs in
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(date.uppercased())
                                        .font(Theme.Font.caption)
                                        .foregroundStyle(Theme.textTertiary)
                                        .tracking(0.6)
                                        .padding(.horizontal, Theme.cardPadding)
                                    VStack(spacing: 0) {
                                        ForEach(txs) { tx in
                                            TransactionRow(transaction: tx)
                                            if tx.id != txs.last?.id {
                                                Divider().background(Theme.border)
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
                            }
                        }
                        .padding(.horizontal, Theme.screenPadding)
                        .padding(.bottom, 100)
                    }
                    .scrollIndicators(.hidden)
                }
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("Movimientos")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showNewTransaction = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Theme.background)
                            .frame(width: 32, height: 32)
                            .background(Theme.accent, in: Circle())
                    }
                }
            }
            .sheet(isPresented: $showNewTransaction) {
                NewTransactionView()
            }
        }
    }

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

    private func pill(label: String, icon: String? = nil, isOn: Bool, action: @escaping () -> Void) -> some View {
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
}
