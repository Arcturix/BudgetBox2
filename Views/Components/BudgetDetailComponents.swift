import SwiftUI

// MARK: - Background
struct BudgetDetailBackground: View {
    var body: some View {
        Color(hex: "383C51")
            .ignoresSafeArea()
    }
}

// MARK: - Header Component
struct BudgetDetailHeader: View {
    let budget: Budget
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Budget Plan")
                .foregroundColor(.gray)
                .padding(.horizontal)

            HStack {
                Text(budget.name)
                    .font(.largeTitle)
                    .bold()
                    .foregroundColor(.white)
                    .padding(.horizontal)

                Spacer()

                Circle()
                    .fill(Color(hex: budget.colorHex))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: budget.iconName)
                            .font(.title2)
                            .foregroundColor(.white)
                    )
                    .padding(.horizontal)
            }
        }
    }
}

// MARK: - Budget Period Information
struct BudgetPeriodInfo: View {
    let startMonth: Int
    let startYear: Int
    
    var body: some View {
        HStack {
            Text("Start Month: \(DateFormatter().monthSymbols[startMonth - 1])")
                .foregroundColor(.white)
                .padding(.horizontal)
            Text("Start Year: \(startYear)")
                .foregroundColor(.white)
                .padding(.horizontal)
        }
    }
}

// MARK: - Budget Summary Cards
struct BudgetSummaryCards: View {
    let budget: Budget
    let showValuesEnabled: Bool
    let showTotalExpense: Bool
    let onToggleShowTotalExpense: () -> Void
    
    var body: some View {
        HStack(spacing: 20) {
            // Total Budget Card
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Image(systemName: "arrow.down")
                        .foregroundColor(.white)
                        .opacity(0.7)

                    Text("Total Budget")
                        .foregroundColor(.white)
                        .opacity(0.7)
                        .font(.caption)
                }

                if showValuesEnabled {
                    Text(budget.amount.formatted(.currency(code: budget.currency.rawValue)))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                } else {
                    Text("****")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
            }
            .padding()
            .frame(width: 180, height: 100, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                ZStack {
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(hex: budget.colorHex),
                            Color(hex: budget.colorHex).opacity(0.7)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )

                    Image(systemName: "eurosign")
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(.white.opacity(0.1))
                        .frame(width: 100, height: 100)
                        .position(x: UIScreen.main.bounds.width * 0.36, y: 50)
                }
            )
            .cornerRadius(16)
            .shadow(color: Color(hex: budget.colorHex).opacity(0.4), radius: 10, x: 0, y: 4)

            // Expenses/Remaining Card
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Image(systemName: "arrow.up")
                        .foregroundColor(.white)
                        .opacity(0.7)

                    Text(showTotalExpense ? "Total Expense" : "Remaining Budget")
                        .foregroundColor(.white)
                        .opacity(0.7)
                        .font(.caption)
                }

                if showValuesEnabled {
                    Button(action: onToggleShowTotalExpense) {
                        VStack(alignment: .leading, spacing: 0) {
                            if showTotalExpense {
                                Text((budget.amount - budget.remainingAmount).formatted(.currency(code: budget.currency.rawValue)))
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            } else {
                                Text(budget.remainingAmount.formatted(.currency(code: budget.currency.rawValue)))
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)

                                Text("\(Int((budget.remainingAmount / budget.amount) * 100))% Remaining")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        }
                    }
                } else {
                    Text("****")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
            }
            .padding()
            .frame(width: 180, height: 100, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                ZStack {
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(hex: budget.colorHex).opacity(0.7),
                            Color(hex: budget.colorHex).opacity(0.4)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )

                    Image(systemName: "creditcard")
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(.white.opacity(0.05))
                        .frame(width: 100, height: 100)
                        .position(x: UIScreen.main.bounds.width * 0.36, y: 50)
                }
            )
            .cornerRadius(16)
            .shadow(color: Color(hex: budget.colorHex).opacity(0.4), radius: 10, x: 0, y: 4)
        }
        .padding(.horizontal)
    }
}

// MARK: - Budget Items List
struct BudgetItemsList: View {
    let expenses: [Expense]
    let isEmpty: Bool
    let itemCount: Int
    let budgetItemLimitEnabled: Bool
    let showValuesEnabled: Bool
    let budgetCurrency: Currency
    let budgetColorHex: String // Add budget color hex
    let onDeleteExpense: (UUID) -> Void
    let onEditExpense: (Expense) -> Void
    let refreshID: UUID

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Budget Items")
                    .foregroundColor(.white)
                    .font(.headline)

                Spacer()

                if budgetItemLimitEnabled {
                    Text("\(itemCount)/10")
                        .foregroundColor(itemCount >= 10 ? .orange : .gray)
                } else {
                    Text("\(itemCount) items")
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal)

            if isEmpty {
                Text("No expenses yet")
                    .foregroundColor(.gray)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .center)
            } else {
                List {
                    ForEach(expenses) { expense in
                        ExpenseRow(
                            expense: expense,
                            showValues: showValuesEnabled,
                            budgetCurrency: budgetCurrency,
                            budgetColorHex: budgetColorHex // Pass budget color hex
                        )
                        .listRowBackground(Color.gray.opacity(0.1))
                        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                onDeleteExpense(expense.id)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        .swipeActions(edge: .leading, allowsFullSwipe: false) {
                            Button {
                                onEditExpense(expense)
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            .tint(.blue)
                        }
                    }
                    .listRowSeparator(.hidden)
                }
                .listStyle(PlainListStyle())
                .background(Color(hex: "383C51"))
                .scrollContentBackground(.hidden)
                .id(refreshID) // Use refresh ID to force view updates
            }
        }
    }
}

// MARK: - Add Budget Item Button
struct AddBudgetItemButton: View {
    let colorHex: String
    let isDisabled: Bool
    let budgetItemLimitEnabled: Bool
    let itemCount: Int
    let onAddItem: () -> Void
    
    var body: some View {
        VStack {
            Button(action: onAddItem) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)

                    Text("Add Budget Item")
                        .font(.title3)
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            isDisabled ? Color.gray : Color(hex: colorHex),
                            isDisabled ? Color.gray.opacity(0.7) : Color(hex: colorHex).opacity(0.7)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundColor(.white)
                .cornerRadius(30)
                .padding(.horizontal)
                .padding(.bottom)
            }
            .disabled(isDisabled)
            .opacity(isDisabled ? 0.6 : 1.0)

            if budgetItemLimitEnabled && itemCount >= 10 {
                Text("Maximum of 10 items reached. Disable limit in Profile.")
                    .font(.caption)
                    .foregroundColor(.orange)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.bottom)
            }
        }
    }
}

// MARK: - Expense Row Component (Already existing)
// Note: This assumes you have an ExpenseRow component already defined elsewhere
// If not, you should add it to this file:
/*
struct ExpenseRow: View {
    let expense: Expense
    let showValues: Bool
    let budgetCurrency: Currency
    
    var body: some View {
        // Your expense row implementation
    }
}
*/
