//
//  Theme.swift
//  Finanzas
//
//  Sistema de tema dark mode minimalista. Centraliza colores, tipografía,
//  espaciados y radios para que la UI sea consistente en todos los módulos.
//

import SwiftUI

enum Theme {

    // MARK: - Backgrounds

    /// Fondo principal de la app (negro casi puro con un toque cálido).
    static let background = Color(red: 0.04, green: 0.04, blue: 0.06)

    /// Fondo de tarjetas — un escalón sobre el fondo principal.
    static let surface = Color(red: 0.09, green: 0.09, blue: 0.12)

    /// Fondo elevado para sheets y detalles.
    static let surfaceElevated = Color(red: 0.13, green: 0.13, blue: 0.16)

    /// Borde sutil para tarjetas.
    static let border = Color.white.opacity(0.06)

    // MARK: - Texto

    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.6)
    static let textTertiary = Color.white.opacity(0.35)

    // MARK: - Acentos

    /// Acento principal — verde menta sobrio.
    static let accent = Color(red: 0.42, green: 0.95, blue: 0.74)

    static let positive = Color(red: 0.35, green: 0.85, blue: 0.55)   // ingresos / al día
    static let warning  = Color(red: 1.00, green: 0.78, blue: 0.36)   // amarillo
    static let danger   = Color(red: 1.00, green: 0.42, blue: 0.45)   // rojo
    static let info     = Color(red: 0.45, green: 0.70, blue: 1.00)   // azul cuentas sanas

    // MARK: - Tipografía

    enum Font {
        static let display    = SwiftUI.Font.system(size: 34, weight: .bold, design: .rounded)
        static let title      = SwiftUI.Font.system(size: 22, weight: .semibold, design: .rounded)
        static let headline   = SwiftUI.Font.system(size: 17, weight: .semibold, design: .rounded)
        static let body       = SwiftUI.Font.system(size: 15, weight: .regular, design: .rounded)
        static let caption    = SwiftUI.Font.system(size: 12, weight: .medium, design: .rounded)
        static let mono       = SwiftUI.Font.system(size: 22, weight: .semibold, design: .monospaced)
    }

    // MARK: - Layout

    static let cornerRadius: CGFloat = 18
    static let cornerRadiusSmall: CGFloat = 10
    static let cardPadding: CGFloat = 16
    static let screenPadding: CGFloat = 20
}

// Modificador para aplicar look de tarjeta consistente.
struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(Theme.cardPadding)
            .background(Theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                    .stroke(Theme.border, lineWidth: 0.5)
            )
    }
}

extension View {
    func cardStyle() -> some View { modifier(CardStyle()) }
}
