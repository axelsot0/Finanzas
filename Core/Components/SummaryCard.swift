//
//  SummaryCard.swift
//  Finanzas
//
//  Tarjeta resumen reutilizable: título, monto, tendencia y barra fina.
//

import SwiftUI

struct SummaryCard: View {
    let title: String
    let amount: String
    var subtitle: String? = nil
    var trend: String? = nil
    var trendIsPositive: Bool = true
    var progress: Double? = nil
    var progressColor: Color = Theme.accent
    var icon: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title.uppercased())
                    .font(Theme.Font.caption)
                    .foregroundStyle(Theme.textTertiary)
                    .tracking(0.6)
                Spacer()
                if let icon {
                    Image(systemName: icon)
                        .foregroundStyle(Theme.textSecondary)
                        .font(.system(size: 13))
                }
            }

            Text(amount)
                .font(Theme.Font.mono)
                .foregroundStyle(Theme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            if let subtitle {
                Text(subtitle)
                    .font(Theme.Font.body)
                    .foregroundStyle(Theme.textSecondary)
            }

            if let trend {
                HStack(spacing: 4) {
                    Image(systemName: trendIsPositive ? "arrow.up.right" : "arrow.down.right")
                    Text(trend)
                }
                .font(Theme.Font.caption)
                .foregroundStyle(trendIsPositive ? Theme.positive : Theme.danger)
            }

            if let progress {
                ThinProgressBar(progress: progress, color: progressColor)
                    .padding(.top, 2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }
}
