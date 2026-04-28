//
//  DashboardView.swift
//  Finanzas
//
//  Pantalla principal: 4 tarjetas resumen + metas + movimientos recientes.
//  Fondo con degradado leve cuyo color depende de la salud financiera.
//

import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Account.createdAt) private var accounts: [Account]
    @Query(sort: \Goal.priority) private var goals: [Goal]
    @Query(sort: \Transaction.occurredAt, order: .reverse) private var transactions: [Transaction]

    @State private var newKind: TransactionKind? = nil

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    headerGreeting
                        .padding(.bottom, 4)

                    // Fila 1: Saldo total | Tarjeta
                    HStack(spacing: 12) {
                        SummaryCard(
                            title: "Saldo total",
                            amount: Money.format(liquidBalance),
                            subtitle: liquidAccountsLabel,
                            icon: "building.columns.fill"
                        )
                        SummaryCard(
                            title: "Tarjeta · quincena",
                            amount: Money.format(cardUsageBiweek),
                            subtitle: "Pagado mes: \(Money.format(cardPaymentsMonth))",
                            icon: "creditcard.fill"
                        )
                    }

                    // Fila 2: Ahorro (goals) | Gasto real
                    HStack(spacing: 12) {
                        SummaryCard(
                            title: "Ahorro",
                            amount: Money.format(savingsBalance),
                            subtitle: "\(goals.count) metas activas",
                            icon: "leaf.fill"
                        )
                        SummaryCard(
                            title: "Gasto · quincena",
                            amount: Money.format(realExpensesBiweek),
                            subtitle: "Mes: \(Money.format(realExpensesMonth))",
                            icon: "chart.line.downtrend.xyaxis"
                        )
                    }

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
                        NavigationLink("Ver todos") { TransactionsListView() }
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
            .background(healthGradient.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
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
            .sheet(item: $newKind) { kind in
                TransactionEditorView(mode: .create(kind))
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
            HStack(spacing: 6) {
                Circle().fill(globalHealth.color).frame(width: 8, height: 8)
                Text(healthLabel)
                    .font(Theme.Font.caption.weight(.medium))
                    .foregroundStyle(Theme.textSecondary)
            }
            .padding(.top, 2)
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

    private func sectionHeader(_ title: String, system: String,
                               @ViewBuilder trailing: () -> some View = { EmptyView() }) -> some View {
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

    // MARK: - Métricas (Fase 1)

    private var biweekRange: ClosedRange<Date> { DateRanges.currentBiweek() }
    private var monthRange:  ClosedRange<Date> { DateRanges.currentMonth() }

    private var liquidBalance:        Double { Metrics.liquidBalance(accounts) }
    private var savingsBalance:       Double { Metrics.savingsBalance(accounts) }
    private var cardUsageBiweek:      Double { Metrics.cardUsage(transactions, in: biweekRange) }
    private var cardPaymentsMonth:    Double { Metrics.cardPayments(transactions, in: monthRange) }
    private var realExpensesBiweek:   Double { Metrics.realExpenses(transactions, in: biweekRange) }
    private var realExpensesMonth:    Double { Metrics.realExpenses(transactions, in: monthRange) }

    private var liquidAccountsLabel: String {
        let n = accounts.filter { $0.isActive && [.payroll, .checking, .cash].contains($0.type) }.count
        return "\(n) cuentas líquidas"
    }

    // MARK: - Salud global (Fase 2)

    private var globalHealth: HealthStatus {
        let ratio = Metrics.healthRatio(transactions, accounts: accounts, in: biweekRange)
        return Metrics.health(ratio: ratio)
    }

    private var healthLabel: String {
        switch globalHealth {
        case .good:    return "Salud financiera buena"
        case .warning: return "Salud financiera con mejoras"
        case .danger:  return "Salud financiera deficiente"
        case .neutral: return "Sin datos suficientes"
        }
    }

    private var healthGradient: LinearGradient {
        LinearGradient(
            colors: [Theme.background, globalHealth.color.opacity(0.18)],
            startPoint: .top,
            endPoint:   .bottom
        )
    }
}
