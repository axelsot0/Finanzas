//
//  FinanzasApp.swift
//  Finanzas
//
//  Punto de entrada de la app. Configura SwiftData con todos los modelos
//  y aplica el tema oscuro globalmente.
//

import SwiftUI
import SwiftData

@main
struct FinanzasApp: App {

    // Contenedor SwiftData con todas las entidades del dominio.
    let container: ModelContainer = {
        let schema = Schema([
            Account.self,
            Category.self,
            Goal.self,
            GoalRule.self,
            Transaction.self,
            GoalAllocation.self
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("No se pudo iniciar ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(.dark)
                .tint(Theme.accent)
        }
        .modelContainer(container)
    }
}
