//
//  ThinProgressBar.swift
//  Finanzas
//
//  Barra fina de progreso/estado con color dinámico.
//  El componente visual base de la app — se usa en metas, categorías y cuentas.
//

import SwiftUI

struct ThinProgressBar: View {
    let progress: Double          // 0...1
    let color: Color
    var height: CGFloat = 4

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.08))
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [color.opacity(0.8), color],
                            startPoint: .leading, endPoint: .trailing
                        )
                    )
                    .frame(width: max(0, min(1, progress)) * geo.size.width)
                    .animation(.easeOut(duration: 0.4), value: progress)
            }
        }
        .frame(height: height)
    }
}

#Preview {
    VStack(spacing: 16) {
        ThinProgressBar(progress: 0.25, color: .red)
        ThinProgressBar(progress: 0.6, color: .yellow)
        ThinProgressBar(progress: 0.9, color: .green)
    }
    .padding()
    .background(Theme.background)
}
