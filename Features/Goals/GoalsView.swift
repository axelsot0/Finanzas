//
//  GoalsView.swift
//  Finanzas
//
//  Lista de metas. Tap en una tarjeta abre el detalle con histórico.
//

import SwiftUI
import SwiftData

struct GoalsView: View {
    @Query(sort: [SortDescriptor(\Goal.priority), SortDescriptor(\Goal.name)]) private var goals: [Goal]
    @State private var showNewGoal = false

    private var totalSaved: Double { goals.reduce(0) { $0 + $1.savedAmount } }
    private var totalTarget: Double { goals.reduce(0) { $0 + $1.targetAmount } }
    private var overallProgress: Double { totalTarget > 0 ? totalSaved / totalTarget : 0 }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    // Hero summary
                    VStack(alignment: .leading, spacing: 12) {
                        Text("AHORRADO TOTAL")
                            .font(Theme.Font.caption)
                            .foregroundStyle(Theme.textTertiary)
                            .tracking(0.6)
                        Text(Money.format(totalSaved))
                            .font(.system(size: 38, weight: .bold, design: .rounded))
                            .foregroundStyle(Theme.textPrimary)
                        Text("de \(Money.format(totalTarget)) en \(goals.count) metas")
                            .font(Theme.Font.body)
                            .foregroundStyle(Theme.textSecondary)
                        ThinProgressBar(progress: overallProgress, color: Theme.accent, height: 6)
                            .padding(.top, 4)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .cardStyle()

                    if goals.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "target")
                                .font(.system(size: 32))
                                .foregroundStyle(Theme.textTertiary)
                            Text("Aún no tienes metas")
                                .font(Theme.Font.headline)
                                .foregroundStyle(Theme.textSecondary)
                            Text("Crea tu primera meta para empezar a distribuir tu ahorro")
                                .font(Theme.Font.body)
                                .foregroundStyle(Theme.textTertiary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 32)
                        .cardStyle()
                    } else {
                        ForEach(goals) { goal in
                            NavigationLink { GoalDetailView(goal: goal) } label: {
                                GoalCard(goal: goal)
                            }.buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, Theme.screenPadding)
                .padding(.bottom, 80)
            }
            .scrollIndicators(.hidden)
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("Metas")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showNewGoal = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Theme.background)
                            .frame(width: 32, height: 32)
                            .background(Theme.accent, in: Circle())
                    }
                }
            }
            .sheet(isPresented: $showNewGoal) {
                NewGoalView()
            }
        }
    }
}
