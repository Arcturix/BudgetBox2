import SwiftUI

struct BudgetDetailView: View {
    @EnvironmentObject var viewModel: BudgetViewModel
    @State var budget: Budget

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
                
                BudgetPeriodInfo(startMonth: budget.startMonth, startYear: budget.startYear)
                
                Spacer().frame(height: 20)
                
                BudgetItemsList(
                    expenses: sortedExpenses,
                    isEmpty: budget.expenses.isEmpty,
                    itemCount: budget.expenses.count,
                    budgetItemLimitEnabled: viewModel.budgetItemLimitEnabled,
                    showValuesEnabled: viewModel.showValuesEnabled,
                    budgetCurrency: budget.currency,
                    budgetColorHex: budget.colorHex, // Pass budget color hex
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
