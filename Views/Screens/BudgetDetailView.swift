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
            ThemeManager.Colors.primary
                .ignoresSafeArea()
            
            if let budget = budget {
                VStack(alignment: .leading, spacing: 0) {
                    // Header
                    VStack(alignment: .leading) {
                        Text("Budget Plan")
                            .foregroundColor(ThemeManager.Colors.secondaryText)
                            .padding(.horizontal)

                        HStack {
                            Text(budget.name)
                                .font(.largeTitle)
                                .bold()
                                .foregroundColor(ThemeManager.Colors.primaryText)
                                .padding(.horizontal)

                            Spacer()

                            // Move the circle inside the HStack's bounds
                            Circle()
                                .fill(Color(hex: budget.colorHex))
                                .frame(width: 50, height: 50)
                                .overlay(
                                    Image(systemName: budget.iconName)
                                        .font(.title2)
                                        .foregroundColor(.white)
                                )
                                .padding(.trailing) // Add trailing padding to keep it from the edge
                        }
                        .padding(.bottom, 8) // Add bottom padding to create space between header and cards
                    }
                    
                    // Budget Summary Cards
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

                            if viewModel.showValuesEnabled {
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

                                // Use the appropriate currency icon based on budget currency
                                Image(systemName: currencyIconName(for: budget.currency))
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

                            if viewModel.showValuesEnabled {
                                Button(action: { showTotalExpense.toggle() }) {
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
                        .foregroundColor(ThemeManager.Colors.primaryText)
                    
                    NavigationLink(destination: HomeView()) {
                        Text("Go to Home")
                            .padding()
                            .background(ThemeManager.Colors.accent)
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
    
    // MARK: - Helper Functions
    
    // Function to get the appropriate currency icon name
    private func currencyIconName(for currency: Currency) -> String {
        switch currency {
        case .usd:
            return "dollarsign"
        case .eur:
            return "eurosign"
        case .gbp:
            return "sterlingsign"
        case .jpy:
            return "yensign"
        }
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
                .foregroundColor(ThemeManager.Colors.primaryText)
        }
    }
    
    @ViewBuilder
    private func expensesTabContent(budget: Budget) -> some View {
        VStack {
            // Budget Items List
            VStack(alignment: .leading) {
                HStack {
                    Text("Budget Items")
                        .foregroundColor(ThemeManager.Colors.primaryText)
                        .font(.headline)

                    Spacer()

                    if viewModel.budgetItemLimitEnabled {
                        Text("\(budget.expenses.count)/10")
                            .foregroundColor(budget.expenses.count >= 10 ? .orange : ThemeManager.Colors.secondaryText)
                    } else {
                        Text("\(budget.expenses.count) items")
                            .foregroundColor(ThemeManager.Colors.secondaryText)
                    }
                }
                .padding(.horizontal)
                .id(refreshID) // Force header to refresh when expenses change

                if sortedExpenses.isEmpty {
                    Text("No expenses yet")
                        .foregroundColor(ThemeManager.Colors.secondaryText)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .center)
                        .id("empty-\(refreshID)") // Force empty state to refresh
                } else {
                    List {
                        ForEach(sortedExpenses) { expense in
                            ExpenseRow(
                                expense: expense,
                                showValues: viewModel.showValuesEnabled,
                                budgetCurrency: budget.currency,
                                budgetColorHex: budget.colorHex
                            )
                            .listRowBackground(ThemeManager.Colors.tertiary)
                            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    withAnimation {
                                        viewModel.deleteExpense(id: expense.id, from: budget.id)
                                    }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                            .swipeActions(edge: .leading, allowsFullSwipe: false) {
                                Button {
                                    expenseToEdit = expense
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                }
                                .tint(.blue)
                            }
                            .id("expense-\(expense.id)-\(refreshID)") // Force each row to refresh when needed
                        }
                        .listRowSeparator(.hidden)
                    }
                    .listStyle(PlainListStyle())
                    .background(ThemeManager.Colors.primary)
                    .scrollContentBackground(.hidden)
                    .id("list-\(refreshID)") // Use refresh ID to force list view updates
                    .animation(.default, value: sortedExpenses.count) // Animate changes in the list count
                }
            }
            
            Spacer()
            
            // Add Budget Item Button
            VStack {
                Button(action: { isShowingAddExpenseSheet = true }) {
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
                                isAddButtonDisabled ? Color.gray : Color(hex: budget.colorHex),
                                isAddButtonDisabled ? Color.gray.opacity(0.7) : Color(hex: budget.colorHex).opacity(0.7)
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
                .disabled(isAddButtonDisabled)
                .opacity(isAddButtonDisabled ? 0.6 : 1.0)

                if viewModel.budgetItemLimitEnabled && budget.expenses.count >= 10 {
                    Text("Maximum of 10 items reached. Disable limit in Profile.")
                        .font(.caption)
                        .foregroundColor(.orange)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.bottom)
                }
            }
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
        .background(ThemeManager.Colors.secondary)
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
            .foregroundColor(isSelected ? Color(hex: colorHex) : ThemeManager.Colors.secondaryText)
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
}
