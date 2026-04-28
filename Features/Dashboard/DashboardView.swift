//
//  DashboardView.swift
//  Finanzas
//
//  Pantalla principal: saldo, ahorro, metas, gasto del mes y movimientos recientes.
//

import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Account.createdAt) private var accounts: [Account]
    @Query(sort: \Goal.priority) private var goals: [Goal]
    @Query(sort: \Transaction.occurredAt, order: .reverse) private var transactions: [Transaction]

    @State private var showNewTransaction = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    headerGreeting
                        .padding(.bottom, 4)

                    // Cards principales
                    HStack(spacing: 12) {
                        SummaryCard(
                            title: "Saldo total",
                            amount: Money.format(totalBalance),
                            subtitle: "\(accounts.filter { $0.type != .credit }.count) cuentas",
                            icon: "building.columns.fill"
                        )
                        SummaryCard(
                            title: "Ahorro total",
                            amount: Money.format(totalSavings),
                            subtitle: "Distribuido en \(goals.count) metas",
                            icon: "leaf.fill"
                        )
                    }

                    SummaryCard(
                        title: "Gasto del mes",
                        amount: Money.format(monthSpent),
                        subtitle: "Quincena: \(Money.format(biweekSpent))",
                        trend: "\(transactions.filter { $0.kind == .expense }.count) movimientos",
                        trendIsPositive: false,
                        progress: monthBudgetProgress,
                        progressColor: monthHealth.color,
                        icon: "chart.line.downtrend.xyaxis"
                    )

                    sectionHeader("Tus metas", system: "target") {
                        NavigationLink("Ver todas") { GoalsView() }
                            .font(Theme.Font.caption)
                            .foregroundStyle(Theme.accent)
                    }

                    if goals.isEmpty {
                        emptyState(icon: "target", text: "Crea tu primera meta financiera")
                    } else {
                        VStack(spacing: 12) {
                            ForEach(goals.prefix(3)) { goal in
                                NavigationLink { GoalDetailView(goal: goal) } label: {
                                    GoalCard(goal: goal)
                                }.buttonStyle(.plain)
                            }
                        }
                    }

                    sectionHeader("Movimientos recientes", system: "clock.arrow.circlepath") {
                        NavigationLink("Ver todos") { TransactionsView() }
                            .font(Theme.Font.caption)
                            .foregroundStyle(Theme.accent)
                    }

                    if transactions.isEmpty {
                        emptyState(icon: "tray", text: "Aún no has registrado movimientos")
                    } else {
                        VStack(spacing: 0) {
                            ForEach(transactions.prefix(5)) { tx in
                                TransactionRow(transaction: tx)
                                if tx.id != transactions.prefix(5).last?.id {
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
                .padding(.horizontal, Theme.screenPadding)
                .padding(.bottom, 80)
            }
            .scrollIndicators(.hidden)
            .background(Theme.background.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
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

    // MARK: - Header

    private var headerGreeting: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(greeting)
                .font(Theme.Font.caption)
                .foregroundStyle(Theme.textTertiary)
                .tracking(0.5)
            Text("Tus finanzas")
                .font(Theme.Font.display)
                .foregroundStyle(Theme.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 8)
    }

    private var greeting: String {
        let h = Calendar.current.component(.hour, from: .now)
        switch h {
        case 5..<12:  return "BUENOS DÍAS"
        case 12..<19: return "BUENAS TARDES"
        default:      return "BUENAS NOCHES"
        }
    }

    // MARK: - Sections

    private func sectionHeader(_ title: String, system: String, @ViewBuilder trailing: () -> some View = { EmptyView() }) -> some View {
        HStack {
            Image(systemName: system)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Theme.textSecondary)
            Text(title)
                .font(Theme.Font.headline)
                .foregroundStyle(Theme.textPrimary)
            Spacer()
            trailing()
        }
        .padding(.top, 8)
    }

    private func emptyState(icon: String, text: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundStyle(Theme.textTertiary)
            Text(text)
                .font(Theme.Font.body)
                .foregroundStyle(Theme.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .cardStyle()
    }

    // MARK: - Cálculos derivados

    private var totalBalance: Double {
        accounts.filter { $0.type != .credit && $0.isActive }
            .reduce(0) { $0 + $1.calculatedBalance }
    }

    private var totalSavings: Double {
        goals.reduce(0) { $0 + $1.savedAmount }
    }

    private var monthSpent: Double {
        let range = DateRanges.currentMonth()
        return transactions
            .filter { range.contains($0.occurredAt) && $0.kind == .expense }
            .reduce(0) { $0 + $1.amount }
    }

    private var biweekSpent: Double {
        let range = DateRanges.currentBiweek()
        return transactions
            .filter { range.contains($0.occurredAt) && $0.kind == .expense }
            .reduce(0) { $0 + $1.amount }
    }

    private var monthBudgetProgress: Double {
        // Suma de presupuestos como referencia.
        let budgets: Double = (try? context.fetch(FetchDescriptor<Category>()))?
            .compactMap { $0.monthlyBudget }
            .reduce(0, +) ?? 0
        guard budgets > 0 else { return min(1, monthSpent / 30_000) }
        return min(1, monthSpent / budgets)
    }

    private var monthHealth: HealthStatus {
        if monthBudgetProgress < 0.8 { return .good }
        if monthBudgetProgress < 1.0 { return .warning }
        return .danger
    }
}
