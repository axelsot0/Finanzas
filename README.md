# Finanzas — App iOS Personal

App de finanzas personal en SwiftUI + SwiftData. Sigue el plan de desarrollo (`plan_desarrollo_app_finanzas_ios.pdf`) con un MVP enfocado en **Dashboard**, **Movimientos** y **Metas**, con estética **dark mode minimalista**.

## Cómo abrirlo en Xcode

1. Abre Xcode → File → New → Project → **App** (iOS, SwiftUI, Swift, Storage: SwiftData).
2. Nombre del proyecto: `Finanzas`.
3. Elimina los archivos default (`FinanzasApp.swift`, `ContentView.swift`, `Item.swift`).
4. Arrastra al proyecto la carpeta `Finanzas/` de este paquete (marcar *Create folder references* o *Create groups*, lo que prefieras).
5. Asegúrate que el target de iOS sea **17.0+** (SwiftData lo requiere).
6. Compila y corre. La primera vez se sembrará la base con cuentas, categorías y metas de ejemplo (Carro, MacBook Pro, INTEC, Colchón).

## Estructura

```
Finanzas/
├── App/
│   ├── FinanzasApp.swift          ← @main, configura ModelContainer
│   └── RootView.swift             ← TabView de los 3 módulos + seed inicial
├── Core/
│   ├── Theme/
│   │   ├── Theme.swift            ← Colores, tipografía, espaciados, .cardStyle()
│   │   └── CurrencyFormatter.swift
│   └── Components/
│       ├── ThinProgressBar.swift  ← Barra fina con color dinámico
│       ├── SummaryCard.swift      ← Card de resumen reutilizable
│       ├── GoalCard.swift         ← Tarjeta principal de meta
│       └── TransactionRow.swift   ← Fila de movimiento
├── Data/
│   ├── Models/                    ← @Model SwiftData
│   │   ├── Account.swift
│   │   ├── Category.swift
│   │   ├── Goal.swift
│   │   ├── GoalRule.swift
│   │   ├── Transaction.swift
│   │   └── GoalAllocation.swift
│   └── Seed/
│       └── SeedData.swift         ← Datos iniciales
├── Domain/
│   ├── Enums/
│   │   └── Enums.swift            ← AccountType, TransactionKind, GoalStatus, …
│   └── UseCases/
│       └── Calculations.swift     ← Balance derivado, salud, semáforos, fechas
└── Features/
    ├── Dashboard/
    │   └── DashboardView.swift
    ├── Transactions/
    │   ├── TransactionsView.swift
    │   └── NewTransactionView.swift
    └── Goals/
        ├── GoalsView.swift
        ├── NewGoalView.swift
        └── GoalDetailView.swift
```

## Reglas de negocio implementadas

- **Balance de cuenta** se calcula desde transacciones, no se persiste (sección 5.1 del plan).
- **Progreso de meta** = `startAmount + sum(deposits) - sum(withdrawals)` desde `GoalAllocation` (sección 5.2).
- **Salud de meta** compara ahorro real contra ritmo planeado por período (sección 5.3).
- **Semáforos** verde/amarillo/rojo en metas, categorías y cuentas (sección 5.4).

## Estética

- **Dark mode minimalista**: fondo casi negro (`#0A0A0F`), tarjetas un escalón arriba, bordes sutiles 0.5pt.
- **Acento verde menta** (`#6CF1BD`) — Apple/Linear vibe.
- **Tipografía** SF Rounded para texto y SF Mono para montos.
- **Tarjeta rectangular alargada** como unidad visual principal (sección 7.1).
- **Barras finas de progreso** con gradiente y color dinámico según salud.

## Próximos pasos

Las siguientes fases del roadmap (no incluidas en este MVP):

- Fase 5+: Categorías como módulo propio + Analytics con gráficos por categoría/mes.
- Fase 6: `RecurringTemplate` para Spotify, Uber One, Luz, etc.
- Fase 7: Pulido — estados vacíos, accesibilidad, validaciones.

## Notas técnicas

- Moneda fijada en **DOP** (Peso dominicano). Ajustable en `CurrencyFormatter.swift`.
- Los pickers de cuenta filtran por tipo cuando aplica (ej. en pago a tarjeta el destino sólo muestra cuentas tipo `.credit`).
- El selector de meta en "Nuevo movimiento" solo aparece cuando `kind == .savings`.
