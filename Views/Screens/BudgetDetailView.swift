import SwiftUI

struct BudgetDetailView: View {
    @EnvironmentObject var viewModel: BudgetViewModel
    let budgetId: UUID
    
    // MARK: - State
    @State private var selectedTab = 0
    @State private var isShowingAddExpenseSheet = false
    @State private var isShowingEditBudgetView = false
    @State private var expenseToEdit: Expense?
    @State private var showTotalExpense = true
    @State private var refreshToggle = false // Add a refresh toggle to force updates
    
    // MARK: - Computed Properties
    
    private var budget: Budget? {
        viewModel.budgets.first(where: { $0.id == budgetId })
    }
    
    private var sortedExpenses: [Expense] {
        // Using refreshToggle as a dependency to force recalculation
        _ = refreshToggle
        return budget?.expenses.sorted(by: { $0.date < $1.date }) ?? []
    }
    
    private var isAddButtonDisabled: Bool {
        guard let budget = budget else { return true }
        return viewModel.budgetItemLimitEnabled && budget.expenses.count >= 10
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            Color(hex: "383C51")
                .ignoresSafeArea()
            
            if let budget = budget {
                VStack(alignment: .leading, spacing: 0) {
                    // Header
                    VStack(alignment: .leading, spacing: 10) {
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
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color(hex: budget.colorHex),
                                        Color(hex: budget.colorHex).opacity(0.7)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .cornerRadius(16)
                            
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
                                                
                                                Text("\(budget.percentRemaining)% Remaining")
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
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color(hex: budget.colorHex).opacity(0.7),
                                        Color(hex: budget.colorHex).opacity(0.4)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .cornerRadius(16)
                        }
                        .padding(.horizontal)
                        
                        Spacer().frame(height: 20)
                    }
                    .padding(.bottom, 10)
                    
                    // Tab Content - Using conditional rendering instead of TabView to avoid swipe conflicts
                    if selectedTab == 0 {
                        expensesTab(budget: budget)
                    } else if selectedTab == 1 {
                        AnalysisView(budget: budget)
                    } else {
                        SavingsView(budget: budget)
                    }
                    
                    // Custom Tab Bar
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
            } else {
                // Fallback view in case budget is not found
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
        }
        .sheet(isPresented: $isShowingAddExpenseSheet, onDismiss: {
            // Force refresh when returning from add expense
            refreshToggle.toggle()
        }) {
            if let budget = budget {
                AddExpenseView(budgetId: budget.id, startYear: budget.startYear)
                    .environmentObject(viewModel)
            }
        }
        .fullScreenCover(item: $expenseToEdit, onDismiss: {
            // Toggle refresh state and clear edit state to force UI refresh
            expenseToEdit = nil
            refreshToggle.toggle() // Force refresh when returning from edit
        }) { expense in
            if let budget = budget {
                EditExpenseView(budgetId: budget.id, expense: expense, startYear: budget.startYear)
                    .environmentObject(viewModel)
            }
        }
        .fullScreenCover(isPresented: $isShowingEditBudgetView, onDismiss: {
            // Force refresh when returning from edit budget
            refreshToggle.toggle()
        }) {
            if let budget = budget {
                EditBudgetView(budget: budget)
                    .environmentObject(viewModel)
            }
        }
    }
    
    // MARK: - Helper Views
    
    @ViewBuilder
    private func expensesTab(budget: Budget) -> some View {
        VStack {
            VStack(alignment: .leading) {
                HStack {
                    Text("Budget Items")
                        .foregroundColor(.white)
                        .font(.headline)
                    
                    Spacer()
                    
                    if viewModel.budgetItemLimitEnabled {
                        Text("\(budget.expenses.count)/10")
                            .foregroundColor(budget.expenses.count >= 10 ? .orange : .gray)
                    } else {
                        Text("\(budget.expenses.count) items")
                            .foregroundColor(.gray)
                    }
                    
                    // Debug refresh button (can remove later)
                    Button(action: { refreshToggle.toggle() }) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal)
                
                if sortedExpenses.isEmpty {
                    Text("No expenses yet")
                        .foregroundColor(.gray)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .center)
                } else {
                    // Using refreshToggle as a key to force list recreation
                    List {
                        ForEach(sortedExpenses) { expense in
                            ExpenseRow(
                                expense: expense,
                                showValues: viewModel.showValuesEnabled,
                                budgetCurrency: budget.currency,
                                budgetColorHex: budget.colorHex
                            )
                            .listRowBackground(Color.gray.opacity(0.1))
                            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    viewModel.deleteExpense(id: expense.id, from: budget.id)
                                    refreshToggle.toggle() // Force refresh after delete
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
                        }
                        .listRowSeparator(.hidden)
                    }
                    .listStyle(PlainListStyle())
                    .background(Color(hex: "383C51"))
                    .scrollContentBackground(.hidden)
                    .id(refreshToggle) // Force recreation of list when toggle changes
                }
            }
            
            Spacer()
            
            // Add Budget Item Button
            VStack {
                Button(action: {
                    isShowingAddExpenseSheet = true
                }) {
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

// MARK: - Preview Provider

struct BudgetDetailView_Previews: PreviewProvider {
    static var previews: some View {
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
}
