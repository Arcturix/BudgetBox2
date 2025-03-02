import SwiftUI
// Helper extension to avoid Color(hex:) conflicts
extension UIColor {
    convenience init(hexString: String) {
        let hex = hexString.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int = UInt64()
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(red: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: CGFloat(a) / 255)
    }
}

struct BudgetDetailView: View {
    @EnvironmentObject var viewModel: BudgetViewModel
    @State var budget: Budget
    
    // MARK: - Tab Selection State
    @State private var selectedTab = 0
    
    // MARK: - Sheet State Management
    @State private var currentEditExpense: Expense?
    @State private var isShowingSheet = false
    @State private var sheetMode: SheetMode = .add
    @State private var expenseToEdit: Expense?
    @State private var showTotalExpense = true
    @State private var isShowingEditBudgetView = false
    
    // MARK: - Force Refresh Mechanism
    @State private var refreshID = UUID()

    enum SheetMode {
        case add, edit
    }

    var sortedExpenses: [Expense] {
        budget.expenses.sorted(by: { $0.date < $1.date })
    }

    var isAddButtonDisabled: Bool {
        viewModel.budgetItemLimitEnabled && budget.expenses.count >= 10
    }

    var body: some View {
        ZStack {
            BudgetDetailBackground()
            
            VStack(alignment: .leading, spacing: 0) {
                // Common header for both tabs
                VStack(alignment: .leading, spacing: 10) {
                    BudgetDetailHeader(budget: budget)
                    
                    BudgetSummaryCards(
                        budget: budget,
                        showValuesEnabled: viewModel.showValuesEnabled,
                        showTotalExpense: showTotalExpense,
                        onToggleShowTotalExpense: {
                            withAnimation {
                                showTotalExpense.toggle()
                            }
                        }
                    )
                    
                    // THIS SHOWS / HIDES THE START MONTH AND START YEAR
                    //BudgetPeriodInfo(startMonth: budget.startMonth, startYear: budget.startYear)
                    
                    Spacer().frame(height: 20)
                }
                .padding(.bottom, 10)
                
                // Tab View for Expenses, Analysis, and Savings with disabled swiping
                if selectedTab == 0 {
                    expensesTabView
                } else if selectedTab == 1 {
                    AnalysisView(budget: budget)
                } else {
                    SavingsView(budget: budget)
                }
                
                // Custom Tab Bar
                customTabBar
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
                            viewModel.deleteBudget(id: budget.id)
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .foregroundColor(.white)
                    }
                }
            }
        }
        // MARK: - Sheet Presentations with Enhanced Dismissal Handlers
        .sheet(isPresented: $isShowingSheet, onDismiss: {
            DispatchQueue.main.async {
                updateBudgetFromViewModel()
                refreshID = UUID() // Force refresh
                sheetMode = .add
            }
        }) {
            if sheetMode == .add {
                AddExpenseView(budgetId: budget.id, startYear: budget.startYear)
                    .environmentObject(viewModel)
            }
        }
        .fullScreenCover(item: $currentEditExpense, onDismiss: {
            DispatchQueue.main.async {
                updateBudgetFromViewModel()
                refreshID = UUID() // Force refresh
            }
        }) { expense in
            EditExpenseView(budgetId: budget.id, expense: expense, startYear: budget.startYear)
                .environmentObject(viewModel)
        }
        .fullScreenCover(isPresented: $isShowingEditBudgetView, onDismiss: {
            DispatchQueue.main.async {
                updateBudgetFromViewModel()
                refreshID = UUID() // Force refresh
            }
        }) {
            EditBudgetView(budget: budget)
                .environmentObject(viewModel)
        }
        // MARK: - Lifecycle and Observer Management
        .onAppear {
            print("BudgetDetailView appeared for budget: \(budget.id)")
            updateBudgetFromViewModel()
            
            // Original notification observer
            NotificationCenter.default.addObserver(
                forName: NSNotification.Name("RefreshBudgetDetail"),
                object: nil,
                queue: .main
            ) { _ in
                print("RefreshBudgetDetail notification received")
                updateBudgetFromViewModel()
            }
            
            // New notification observers for enhanced compatibility
            NotificationCenter.default.addObserver(
                forName: NSNotification.Name("ExpenseAdded"),
                object: nil,
                queue: .main
            ) { notification in
                print("ExpenseAdded notification received")
                if let userInfo = notification.userInfo,
                   let notificationBudgetId = userInfo["budgetId"] as? UUID,
                   notificationBudgetId == budget.id {
                    DispatchQueue.main.async {
                        updateBudgetFromViewModel()
                        refreshID = UUID() // Force refresh
                    }
                }
            }
            
            NotificationCenter.default.addObserver(
                forName: NSNotification.Name("ExpenseEdited"),
                object: nil,
                queue: .main
            ) { notification in
                print("ExpenseEdited notification received")
                if let userInfo = notification.userInfo,
                   let notificationBudgetId = userInfo["budgetId"] as? UUID,
                   notificationBudgetId == budget.id {
                    DispatchQueue.main.async {
                        updateBudgetFromViewModel()
                        refreshID = UUID() // Force refresh
                    }
                }
            }
        }
        .onDisappear {
            print("BudgetDetailView disappeared for budget: \(budget.id)")
            if let updatedBudget = viewModel.budgets.first(where: { $0.id == budget.id }) {
                viewModel.updateBudget(updatedBudget)
            }
            NotificationCenter.default.removeObserver(self, name: NSNotification.Name("RefreshBudgetDetail"), object: nil)
            NotificationCenter.default.removeObserver(self, name: NSNotification.Name("ExpenseAdded"), object: nil)
            NotificationCenter.default.removeObserver(self, name: NSNotification.Name("ExpenseEdited"), object: nil)
        }
        .onChange(of: viewModel.budgets) { _, _ in
            print("ViewModel budgets changed")
            updateBudgetFromViewModel()
        }
    }
    
    // MARK: - Tab Views
    
    private var expensesTabView: some View {
        VStack {
            BudgetItemsList(
                expenses: sortedExpenses,
                isEmpty: budget.expenses.isEmpty,
                itemCount: budget.expenses.count,
                budgetItemLimitEnabled: viewModel.budgetItemLimitEnabled,
                showValuesEnabled: viewModel.showValuesEnabled,
                budgetCurrency: budget.currency,
                budgetColorHex: budget.colorHex,
                onDeleteExpense: { expenseId in
                    viewModel.deleteExpense(id: expenseId, from: budget.id)
                    updateBudgetFromViewModel()
                    refreshID = UUID() // Force refresh
                },
                onEditExpense: { expense in
                    currentEditExpense = expense
                },
                refreshID: refreshID
            )
            
            Spacer()
            
            AddBudgetItemButton(
                colorHex: budget.colorHex,
                isDisabled: isAddButtonDisabled,
                budgetItemLimitEnabled: viewModel.budgetItemLimitEnabled,
                itemCount: budget.expenses.count,
                onAddItem: {
                    expenseToEdit = nil
                    sheetMode = .add
                    isShowingSheet = true
                }
            )
            .padding(.bottom)
        }
    }
    
    private var customTabBar: some View {
        HStack {
            Spacer()
            
            // Budget Tab
            TabButton(
                title: "Budget",
                icon: "list.bullet",
                isSelected: selectedTab == 0,
                colorHex: budget.colorHex,
                action: { selectedTab = 0 }
            )
            
            Spacer()
            
            // Analysis Tab
            TabButton(
                title: "Analysis",
                icon: "chart.pie.fill",
                isSelected: selectedTab == 1,
                colorHex: budget.colorHex,
                action: { selectedTab = 1 }
            )
            
            Spacer()
            
            // Savings Tab
            TabButton(
                title: "Savings",
                icon: "chart.line.uptrend.xyaxis",
                isSelected: selectedTab == 2,
                colorHex: budget.colorHex,
                action: { selectedTab = 2 }
            )
            
            Spacer()
        }
        .padding(.vertical, 8)
        .background(Color(.secondarySystemBackground))
    }
    
    // MARK: - Custom Tab Button
    private struct TabButton: View {
        let title: String
        let icon: String
        let isSelected: Bool
        let colorHex: String
        let action: () -> Void
        
        var body: some View {
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
                .foregroundColor(isSelected ? Color(UIColor(hexString: colorHex)) : .gray)
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .background(
                    isSelected ?
                        Color(UIColor(hexString: colorHex)).opacity(0.2) :
                        Color.clear
                )
                .cornerRadius(8)
            }
        }
    }

    // MARK: - Helper Methods
    func updateBudgetFromViewModel() {
        print("Updating budget from ViewModel for budget ID: \(budget.id)")
        if let updatedBudget = viewModel.budgets.first(where: { $0.id == budget.id }) {
            print("Found updated budget in ViewModel with \(updatedBudget.expenses.count) expenses")
            budget = updatedBudget
            refreshID = UUID() // Force refresh when budget is updated
        } else {
            print("WARNING: Budget not found in ViewModel!")
        }
    }

    func refreshBudget() {
        print("Manual refresh triggered")
        updateBudgetFromViewModel()
        refreshID = UUID() // Force refresh
    }
}

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
            BudgetDetailView(budget: sampleBudget)
                .environmentObject(viewModel)
        }
        .preferredColorScheme(.dark)
    }
}
