import SwiftUI

struct BudgetDetailView: View {
    @EnvironmentObject var viewModel: BudgetViewModel
    let budgetId: UUID
    
    // MARK: - State
    @State private var selectedTab = 0
    @State private var isShowingAddExpenseSheet = false
    @State private var isShowingEditBudgetView = false
    @State private var expenseToEdit: Expense?
    @State private var showTotalExpense = false // This shows the alternative view first
    @State private var refreshID = UUID() // Used for forcing view updates
    
    // MARK: - Computed Properties
    private var budget: Budget? {
        viewModel.budgets.first(where: { $0.id == budgetId })
    }
    
    private var sortedExpenses: [Expense] {
        budget?.expenses.sorted(by: { $0.date < $1.date }) ?? []
    }
    
    private var isAddButtonDisabled: Bool {
        guard let budget = budget else { return true }
        return viewModel.budgetItemLimitEnabled && budget.expenses.count >= 10
    }
    
    // MARK: - Body
    var body: some View {
        ZStack {
            // Background
            BudgetDetailBackground()
            
            if let budget = budget {
                VStack(alignment: .leading, spacing: 0) {
                    // Header
                    BudgetDetailHeader(budget: budget)
                    
                    // Budget Summary Cards
                    BudgetSummaryCards(
                        budget: budget,
                        showValuesEnabled: viewModel.showValuesEnabled,
                        showTotalExpense: showTotalExpense,
                        onToggleShowTotalExpense: { showTotalExpense.toggle() }
                    )
                    
                    Spacer().frame(height: 20)
                    
                    // Tab Content - Using conditional rendering instead of TabView to avoid swipe conflicts
                    if selectedTab == 0 {
                        expensesTabContent(budget: budget)
                    } else if selectedTab == 1 {
                        AnalysisView(budget: budget)
                    } else {
                        SavingsView(budget: budget)
                    }
                    
                    // Custom Tab Bar
                    customTabBar(budget: budget)
                }
                .onReceive(viewModel.stateUpdatePublisher) { updatedBudgetId in
                    if updatedBudgetId == budgetId {
                        // Force refresh when this budget is updated
                        refreshID = UUID()
                    }
                }
            } else {
                // Fallback view if budget not found
                VStack {
                    Text("Budget not found")
                        .font(.title)
                        .foregroundColor(.white)
                    
                    NavigationLink(destination: HomeView()) {
                        Text("Go to Home")
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding(.top)
                }
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                budgetMenuButton
            }
        }
        .sheet(isPresented: $isShowingAddExpenseSheet) {
            if let budget = budget {
                AddExpenseView(budgetId: budget.id, startYear: budget.startYear)
                    .environmentObject(viewModel)
            }
        }
        .fullScreenCover(item: $expenseToEdit) { expense in
            if let budget = budget {
                EditExpenseView(budgetId: budget.id, expense: expense, startYear: budget.startYear)
                    .environmentObject(viewModel)
            }
        }
        .fullScreenCover(isPresented: $isShowingEditBudgetView) {
            if let budget = budget {
                EditBudgetView(budget: budget)
                    .environmentObject(viewModel)
            }
        }
        .id(refreshID) // Force view to refresh when refreshID changes
    }
    
    // MARK: - UI Components
    
    private var budgetMenuButton: some View {
        Menu {
            Button("Edit Budget") {
                isShowingEditBudgetView = true
            }
            
            Button("Delete Budget", role: .destructive) {
                if let budget = budget {
                    viewModel.deleteBudget(id: budget.id)
                }
            }
        } label: {
            Image(systemName: "ellipsis")
                .foregroundColor(.white)
        }
    }
    
    @ViewBuilder
    private func expensesTabContent(budget: Budget) -> some View {
        VStack {
            // Budget Items List
            BudgetItemsList(
                expenses: sortedExpenses,
                isEmpty: sortedExpenses.isEmpty,
                itemCount: budget.expenses.count,
                budgetItemLimitEnabled: viewModel.budgetItemLimitEnabled,
                showValuesEnabled: viewModel.showValuesEnabled,
                budgetCurrency: budget.currency,
                budgetColorHex: budget.colorHex,
                onDeleteExpense: { expenseId in
                    viewModel.deleteExpense(id: expenseId, from: budget.id)
                },
                onEditExpense: { expense in
                    expenseToEdit = expense
                },
                refreshID: refreshID
            )
            
            Spacer()
            
            // Add Budget Item Button
            AddBudgetItemButton(
                colorHex: budget.colorHex,
                isDisabled: isAddButtonDisabled,
                budgetItemLimitEnabled: viewModel.budgetItemLimitEnabled,
                itemCount: budget.expenses.count,
                onAddItem: { isShowingAddExpenseSheet = true }
            )
        }
    }
    
    private func customTabBar(budget: Budget) -> some View {
        HStack {
            Spacer()
            
            // Budget Tab
            tabButton(title: "Budget", icon: "list.bullet", isSelected: selectedTab == 0, colorHex: budget.colorHex) {
                selectedTab = 0
            }
            
            Spacer()
            
            // Analysis Tab
            tabButton(title: "Analysis", icon: "chart.pie.fill", isSelected: selectedTab == 1, colorHex: budget.colorHex) {
                selectedTab = 1
            }
            
            Spacer()
            
            // Savings Tab
            tabButton(title: "Savings", icon: "chart.line.uptrend.xyaxis", isSelected: selectedTab == 2, colorHex: budget.colorHex) {
                selectedTab = 2
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
        .background(Color(.secondarySystemBackground))
    }
    
    private func tabButton(title: String, icon: String, isSelected: Bool, colorHex: String, action: @escaping () -> Void) -> some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.3)) {
                action()
            }
        }) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                Text(title)
                    .font(.caption)
            }
            .foregroundColor(isSelected ? Color(hex: colorHex) : .gray)
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .background(
                isSelected ?
                    Color(hex: colorHex).opacity(0.2) :
                    Color.clear
            )
            .cornerRadius(8)
        }
    }
}

#Preview {
    let sampleExpenses = [
        Expense(
            name: "Groceries",
            amount: 100.0,
            currency: .usd,
            category: .food,
            date: Date(),
            isEssential: true,
            notes: "Weekly grocery shopping"
        ),
        Expense(
            name: "Netflix",
            amount: 15.99,
            currency: .usd,
            category: .entertainment,
            date: Date().addingTimeInterval(-86400),
            isEssential: false,
            notes: "Monthly subscription"
        )
    ]
    
    let sampleBudget = Budget(
        name: "Monthly Budget",
        amount: 1000.0,
        currency: .usd,
        iconName: "dollarsign.circle",
        colorHex: "A169F7",
        isMonthly: true,
        expenses: sampleExpenses,
        startMonth: 1,
        startYear: 2023
    )
    
    let viewModel = BudgetViewModel()
    viewModel.addBudget(sampleBudget)
    
    return NavigationView {
        BudgetDetailView(budgetId: sampleBudget.id)
            .environmentObject(viewModel)
    }
    .preferredColorScheme(.dark)
}

#Preview {
    let sampleExpenses = [
        Expense(
            name: "Groceries",
            amount: 100.0,
            currency: .usd,
            category: .food,
            date: Date(),
            isEssential: true,
            notes: "Weekly grocery shopping"
        ),
        Expense(
            name: "Netflix",
            amount: 15.99,
            currency: .usd,
            category: .entertainment,
            date: Date().addingTimeInterval(-86400),
            isEssential: false,
            notes: "Monthly subscription"
        )
    ]
    
    let sampleBudget = Budget(
        name: "Monthly Budget",
        amount: 1000.0,
        currency: .usd,
        iconName: "dollarsign.circle",
        colorHex: "A169F7",
        isMonthly: true,
        expenses: sampleExpenses,
        startMonth: 1,
        startYear: 2023
    )
    
    let viewModel = BudgetViewModel()
    viewModel.addBudget(sampleBudget)
    
    return NavigationView {
        BudgetDetailView(budgetId: sampleBudget.id)
            .environmentObject(viewModel)
    }
    .preferredColorScheme(.dark)
}
