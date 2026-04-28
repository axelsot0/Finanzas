#!/usr/bin/env bash
# push-to-github.sh
# Inicializa el repo y lo sube a GitHub. Antes de correrlo:
#   1. Crea un repo VACÍO en https://github.com/new (sin README, sin .gitignore).
#   2. Copia la URL del repo y pásala como argumento, por ejemplo:
#        ./push-to-github.sh https://github.com/axelmlsoto/finanzas-ios.git
#
# Requiere: git instalado y autenticación con GitHub configurada (gh auth login,
# token personal, o SSH key).

set -e

REPO_URL="${1:?Uso: ./push-to-github.sh <URL del repo>}"

cd "$(dirname "$0")"

git init -b main
git add .
git commit -m "feat: MVP inicial — Dashboard, transacciones y metas

Implementación inicial siguiendo el plan de desarrollo:
- SwiftUI + SwiftData (iOS 17+)
- Dark mode minimalista
- Modelos: Account, Category, Goal, GoalRule, Transaction, GoalAllocation
- Cálculos derivados (balances, progreso, salud)
- Datos semilla: Carro, MacBook Pro, INTEC, Colchón"

git remote add origin "$REPO_URL"
git push -u origin main

echo ""
echo "Listo. Tu repo está en: $REPO_URL"
