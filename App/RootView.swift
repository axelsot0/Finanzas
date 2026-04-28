//
//  RootView.swift
//  Finanzas
//
//  TabView principal con los 3 módulos del MVP: Dashboard, Transacciones y Metas.
//  Se encarga de sembrar datos iniciales si la base está vacía.
//

import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) private var context
    @Query private var accounts: [Account]

    @State private var showNewTransaction = false

    var body: some View {
        TabView {
            DashboardView()
                .tabItem { Label("Inicio", systemImage: "square.grid.2x2.fill") }

            TransactionsListView()
                .tabItem { Label("Movimientos", systemImage: "list.bullet") }

            GoalsView()
                .tabItem { Label("Metas", systemImage: "target") }

            CategoriesView()
                .tabItem { Label("Categorías", systemImage: "tag.fill") }
        }
        .onAppear {
            if accounts.isEmpty {
                SeedData.populate(context: context)
            }
        }
    }
}
