import Foundation
import SwiftUI
import Combine

class BudgetViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var budgets: [Budget] = []
    @Published var showValuesEnabled: Bool = true
    @Published var userAvatar: Data?
    @Published var budgetItemLimitEnabled: Bool = true
    @Published var selectedInsights: [InsightType] = [.netWorth, .savingsRate, .essentialExpenses]
    @Published var studentLoanBalance: Double = 0.0
    @Published var studentLoanInterestRate: Double = 0.0
    @Published var studentLoanCurrency: Currency = .usd
    
    // MARK: - Private Properties
    private let saveKey = "saved_budgets"
    private let userDefaultsManager = UserDefaultsManager()
    
    // Maximum number of insights that can be selected
    let maxInsights: Int = 6
    
    // For reactive state updates
    public var _stateUpdatePublisher: PassthroughSubject<UUID, Never>?
    
    // MARK: - Initialization
    init() {
        loadData()
        loadSelectedInsights()
    }
    
    // MARK: - Data Management
    func loadData() {
        budgets = userDefaultsManager.load(key: saveKey) ?? []
        showValuesEnabled = userDefaultsManager.load(key: "show_values") ?? true
        userAvatar = userDefaultsManager.load(key: "user_avatar")
        budgetItemLimitEnabled = userDefaultsManager.load(key: "budget_item_limit_enabled") ?? true
        studentLoanBalance = userDefaultsManager.load(key: "student_loan_balance") ?? 0.0
        studentLoanInterestRate = userDefaultsManager.load(key: "student_loan_interest_rate") ?? 0.0
        
        // Load student loan currency with fallback to USD
        if let currencyString: String = userDefaultsManager.load(key: "student_loan_currency"),
           let currency = Currency(rawValue: currencyString) {
            studentLoanCurrency = currency
        }
    }
    
    func saveData() {
        userDefaultsManager.save(budgets, key: saveKey)
        userDefaultsManager.save(showValuesEnabled, key: "show_values")
        userDefaultsManager.save(budgetItemLimitEnabled, key: "budget_item_limit_enabled")
        userDefaultsManager.save(studentLoanBalance, key: "student_loan_balance")
        userDefaultsManager.save(studentLoanInterestRate, key: "student_loan_interest_rate")
        userDefaultsManager.save(studentLoanCurrency.rawValue, key: "student_loan_currency")
        
        if let avatar = userAvatar {
            userDefaultsManager.save(avatar, key: "user_avatar")
        }
        saveSelectedInsights()
    }
    
    // MARK: - Notifications Management
    func scheduleNotifications() {
        // Schedule notifications for all expenses with reminders
        for budget in budgets {
            for expense in budget.expenses {
                if expense.reminder != nil {
                    NotificationService.shared.scheduleNotification(for: expense, budgetName: budget.name)
                }
            }
        }
    }
    
    // MARK: - Student Loan Methods
    func findExistingStudentLoanPayment() -> (budgetId: UUID, expense: Expense)? {
        for budget in budgets {
            if let expense = budget.expenses.first(where: { $0.isStudentLoanPayment }) {
                return (budget.id, expense)
            }
        }
        return nil
    }
    
    func getStudentLoanMonthlyPayment() -> Double? {
        guard let existingPayment = findExistingStudentLoanPayment() else { return nil }
        let expense = existingPayment.expense
        
        return expense.currency == studentLoanCurrency ?
               expense.amount :
               expense.convertedAmount(to: studentLoanCurrency)
    }
    
    func calculateStudentLoanPayoffDate() -> Date? {
        guard let monthlyPayment = getStudentLoanMonthlyPayment(),
              monthlyPayment > 0,
              studentLoanBalance > 0 else { return nil }
        
        // Convert annual interest rate to monthly
        let monthlyInterestRate = studentLoanInterestRate / 100 / 12
        
        // If no interest or very low payment, use simple division
        if monthlyInterestRate <= 0 || monthlyPayment <= (studentLoanBalance * monthlyInterestRate) {
            let months = ceil(studentLoanBalance / monthlyPayment)
            return Calendar.current.date(byAdding: .month, value: Int(months), to: Date())
        }
        
        // Calculate number of months to pay off using loan amortization formula
        let numerator = -log(1 - (monthlyInterestRate * studentLoanBalance / monthlyPayment))
        let denominator = log(1 + monthlyInterestRate)
        let numberOfMonths = ceil(numerator / denominator)
        
        return Calendar.current.date(byAdding: .month, value: Int(numberOfMonths), to: Date())
    }
    
    // MARK: - Insights Management
    func loadSelectedInsights() {
        if let savedInsights: [InsightType] = userDefaultsManager.load(key: "selected_insights") {
            selectedInsights = savedInsights
        } else {
            // Default insights if none are saved
            selectedInsights = [.netWorth, .savingsRate, .essentialExpenses]
        }
    }
    
    func saveSelectedInsights() {
        userDefaultsManager.save(selectedInsights, key: "selected_insights")
    }
    
    func toggleInsight(_ insight: InsightType) {
        if selectedInsights.contains(insight) {
            // Remove insight if already selected
            selectedInsights.removeAll(where: { $0 == insight })
        } else if selectedInsights.count < maxInsights {
            // Add insight if under max limit
            selectedInsights.append(insight)
        }
        saveSelectedInsights()
    }
    
    func isInsightSelected(_ insight: InsightType) -> Bool {
        return selectedInsights.contains(insight)
    }
    
    // MARK: - Budget Operations
    func addBudget(_ budget: Budget) {
        budgets.append(budget)
        saveData()
    }
    
    func updateBudget(_ budget: Budget) {
        if let index = budgets.firstIndex(where: { $0.id == budget.id }) {
            budgets[index] = budget
            saveData()
            triggerStateUpdate(for: budget.id)
        }
    }
    
    func deleteBudget(at indexSet: IndexSet) {
        budgets.remove(atOffsets: indexSet)
        saveData()
    }
    
    func deleteBudget(id: UUID) {
        if let index = budgets.firstIndex(where: { $0.id == id }) {
            // Cancel notifications for all expenses in this budget
            for expense in budgets[index].expenses {
                NotificationService.shared.cancelNotification(for: expense.id)
            }
            
            budgets.remove(at: index)
            saveData()
        }
    }
    
    func duplicateBudget(id: UUID) {
        if let budgetToDuplicate = budgets.first(where: { $0.id == id }) {
            var newBudget = budgetToDuplicate
            newBudget.id = UUID() // Generate a new UUID
            newBudget.name = "\(budgetToDuplicate.name) (Copy)"
            
            // Create new expenses with new IDs to avoid notification conflicts
            newBudget.expenses = budgetToDuplicate.expenses.map { expense in
                var newExpense = expense
                newExpense.id = UUID()
                return newExpense
            }
            
            // Add the duplicated budget
            budgets.append(newBudget)
            saveData()
            
            // Schedule notifications for the duplicated expenses
            for expense in newBudget.expenses {
                if expense.reminder != nil {
                    NotificationService.shared.scheduleNotification(for: expense, budgetName: newBudget.name)
                }
            }
        }
    }
    
    // MARK: - Expense Operations
    func addExpense(_ expense: Expense, to budgetId: UUID) {
        handleStudentLoanFlag(for: expense, budgetId: budgetId)
        
        if let index = budgets.firstIndex(where: { $0.id == budgetId }) {
            // Check if limit is reached and enabled
            if budgetItemLimitEnabled && budgets[index].expenses.count >= 10 {
                return
            }
            
            // Add expense to the budget
            budgets[index].expenses.append(expense)
            saveData()
            triggerStateUpdate(for: budgetId)
            
            // Schedule notification if needed
            if expense.reminder != nil {
                NotificationService.shared.scheduleNotification(for: expense, budgetName: budgets[index].name)
            }
        }
    }
    
    func updateExpense(_ expense: Expense, in budgetId: UUID) {
        handleStudentLoanFlag(for: expense, budgetId: budgetId)
        
        if let budgetIndex = budgets.firstIndex(where: { $0.id == budgetId }),
           let expenseIndex = budgets[budgetIndex].expenses.firstIndex(where: { $0.id == expense.id }) {
            // Update expense in the budget
            budgets[budgetIndex].expenses[expenseIndex] = expense
            saveData()
            triggerStateUpdate(for: budgetId)
            
            // Update notification if needed
            if expense.reminder != nil {
                NotificationService.shared.scheduleNotification(for: expense, budgetName: budgets[budgetIndex].name)
            } else {
                NotificationService.shared.cancelNotification(for: expense.id)
            }
        }
    }
    
    func deleteExpense(id: UUID, from budgetId: UUID) {
        // Cancel any notifications for this expense
        NotificationService.shared.cancelNotification(for: id)
        
        if let budgetIndex = budgets.firstIndex(where: { $0.id == budgetId }) {
            // Remove expense from the budget
            budgets[budgetIndex].expenses.removeAll(where: { $0.id == id })
            saveData()
            triggerStateUpdate(for: budgetId)
        }
    }
    
    // MARK: - Helper Methods
    private func handleStudentLoanFlag(for expense: Expense, budgetId: UUID) {
        // If this is a student loan payment, check if one already exists
        if expense.isStudentLoanPayment {
            if let existing = findExistingStudentLoanPayment() {
                // If existing in same budget, update it instead of adding a new one
                if existing.budgetId == budgetId && existing.expense.id != expense.id {
                    if let budgetIndex = budgets.firstIndex(where: { $0.id == existing.budgetId }),
                       let expenseIndex = budgets[budgetIndex].expenses.firstIndex(where: { $0.id == existing.expense.id }) {
                        var updatedExpense = budgets[budgetIndex].expenses[expenseIndex]
                        updatedExpense.isStudentLoanPayment = false
                        budgets[budgetIndex].expenses[expenseIndex] = updatedExpense
                    }
                }
            }
        }
    }
    
    // MARK: - User Preferences
    func toggleShowValues() {
        showValuesEnabled.toggle()
        saveData()
    }
    
    func setUserAvatar(_ imageData: Data?) {
        userAvatar = imageData
        saveData()
    }
    
    func toggleBudgetItemLimit() {
        budgetItemLimitEnabled.toggle()
        saveData()
    }
}
