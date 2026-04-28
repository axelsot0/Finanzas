//
//  GoalCard.swift
//  Finanzas
//
//  Tarjeta rectangular alargada para representar una meta.
//  Es la pieza visual central de la app.
//

import SwiftUI

struct GoalCard: View {
    let goal: Goal

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    Circle()
                        .fill(goal.color.opacity(0.15))
                    Image(systemName: goal.goalType.icon)
                        .foregroundStyle(goal.color)
                        .font(.system(size: 16, weight: .semibold))
                }
                .frame(width: 38, height: 38)

                VStack(alignment: .leading, spacing: 2) {
                    Text(goal.name)
                        .font(Theme.Font.headline)
                        .foregroundStyle(Theme.textPrimary)
                    Text(goal.goalType.label)
                        .font(Theme.Font.caption)
                        .foregroundStyle(Theme.textTertiary)
                }

                Spacer()

                Text("\(Int(goal.progress * 100))%")
                    .font(Theme.Font.caption)
                    .foregroundStyle(goal.health.color)
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(goal.health.color.opacity(0.12), in: Capsule())
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline) {
                    Text(Money.format(goal.savedAmount))
                        .font(Theme.Font.mono)
                        .foregroundStyle(Theme.textPrimary)
                    Text("/ \(Money.format(goal.targetAmount))")
                        .font(Theme.Font.body)
                        .foregroundStyle(Theme.textSecondary)
                }
                ThinProgressBar(progress: goal.progress, color: goal.health.color)
            }

            HStack {
                Label(goal.contributionPeriod.label, systemImage: "calendar")
                Spacer()
                Text("Faltan \(Money.format(goal.remainingAmount))")
            }
            .font(Theme.Font.caption)
            .foregroundStyle(Theme.textTertiary)
        }
        .cardStyle()
    }
}
