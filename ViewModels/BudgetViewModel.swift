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
        if let currencyString: String = userDefaultsManager.load(key: "student_loan_currency") {
            if let currency = Currency(rawValue: currencyString) {
                studentLoanCurrency = currency
            }
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
    
    // MARK: - Student Loan Methods
    
    // Check if there's already a student loan payment in a budget
    func findExistingStudentLoanPayment() -> (budgetId: UUID, expense: Expense)? {
        for budget in budgets {
            if let expense = budget.expenses.first(where: { $0.isStudentLoanPayment }) {
                return (budget.id, expense)
            }
        }
        return nil
    }
    
    // Get the monthly student loan payment amount
    func getStudentLoanMonthlyPayment() -> Double? {
        guard let existingPayment = findExistingStudentLoanPayment() else { return nil }
        let expense = existingPayment.expense
        
        // Convert to the student loan currency if needed
        if expense.currency == studentLoanCurrency {
            return expense.amount
        } else {
            return expense.convertedAmount(to: studentLoanCurrency)
        }
    }
    
    // Calculate the projected payoff date for the student loan
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
        // n = -log(1 - rP/A) / log(1 + r)
        // where:
        // n = number of months
        // r = monthly interest rate as a decimal
        // P = principal (loan balance)
        // A = monthly payment
        
        let numerator = -log(1 - (monthlyInterestRate * studentLoanBalance / monthlyPayment))
        let denominator = log(1 + monthlyInterestRate)
        let numberOfMonths = ceil(numerator / denominator)
        
        return Calendar.current.date(byAdding: .month, value: Int(numberOfMonths), to: Date())
    }
    
    // MARK: - Insights Management
    
    // Load selected insights from UserDefaults
    func loadSelectedInsights() {
        if let savedInsights: [InsightType] = userDefaultsManager.load(key: "selected_insights") {
            selectedInsights = savedInsights
        } else {
            // Default insights if none are saved
            selectedInsights = [.netWorth, .savingsRate, .essentialExpenses]
        }
    }
    
    // Save selected insights to UserDefaults
    func saveSelectedInsights() {
        userDefaultsManager.save(selectedInsights, key: "selected_insights")
    }
    
    // Toggle an insight selection
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
    
    // Check if an insight is selected
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
            budgets.remove(at: index)
            saveData()
        }
    }
    
    func duplicateBudget(id: UUID) {
        if let budgetToDuplicate = budgets.first(where: { $0.id == id }) {
            var newBudget = budgetToDuplicate
            newBudget.id = UUID() // Generate a new UUID
            newBudget.name = "\(budgetToDuplicate.name) (Copy)"
            
            // Add the duplicated budget
            budgets.append(newBudget)
            saveData()
        }
    }
    
    // MARK: - Expense Operations
    func addExpense(_ expense: Expense, to budgetId: UUID) {
        // If this is a student loan payment, check if one already exists
        if expense.isStudentLoanPayment {
            if let existing = findExistingStudentLoanPayment() {
                // If existing in same budget, update it instead of adding a new one
                if existing.budgetId == budgetId {
                    updateExpense(expense, in: budgetId)
                    return
                }
                
                // If existing in a different budget, remove the flag from the old one
                // and add the new one with the flag
                if let budgetIndex = budgets.firstIndex(where: { $0.id == existing.budgetId }),
                   let expenseIndex = budgets[budgetIndex].expenses.firstIndex(where: { $0.id == existing.expense.id }) {
                    var updatedExpense = budgets[budgetIndex].expenses[expenseIndex]
                    updatedExpense.isStudentLoanPayment = false
                    budgets[budgetIndex].expenses[expenseIndex] = updatedExpense
                }
            }
        }
        
        if let index = budgets.firstIndex(where: { $0.id == budgetId }) {
            // Check if limit is reached and enabled
            if budgetItemLimitEnabled && budgets[index].expenses.count >= 10 {
                // Don't add the expense if limit is reached
                return
            }
            
            // Add expense to the budget
            budgets[index].expenses.append(expense)
            
            // Save data to UserDefaults
            saveData()
            
            // Trigger reactive state update
            triggerStateUpdate(for: budgetId)
        }
    }
    
    func updateExpense(_ expense: Expense, in budgetId: UUID) {
        // If this is a student loan payment, check if one already exists
        if expense.isStudentLoanPayment {
            if let existing = findExistingStudentLoanPayment(), existing.expense.id != expense.id {
                // If existing in a different budget, remove the flag from the old one
                if let budgetIndex = budgets.firstIndex(where: { $0.id == existing.budgetId }),
                   let expenseIndex = budgets[budgetIndex].expenses.firstIndex(where: { $0.id == existing.expense.id }) {
                    var updatedExpense = budgets[budgetIndex].expenses[expenseIndex]
                    updatedExpense.isStudentLoanPayment = false
                    budgets[budgetIndex].expenses[expenseIndex] = updatedExpense
                }
            }
        }
        
        if let budgetIndex = budgets.firstIndex(where: { $0.id == budgetId }),
           let expenseIndex = budgets[budgetIndex].expenses.firstIndex(where: { $0.id == expense.id }) {
            // Update expense in the budget
            budgets[budgetIndex].expenses[expenseIndex] = expense
            
            // Save data to UserDefaults
            saveData()
            
            // Trigger reactive state update
            triggerStateUpdate(for: budgetId)
        }
    }
    
    func deleteExpense(id: UUID, from budgetId: UUID) {
        if let budgetIndex = budgets.firstIndex(where: { $0.id == budgetId }) {
            // Remove expense from the budget
            budgets[budgetIndex].expenses.removeAll(where: { $0.id == id })
            
            // Save data to UserDefaults
            saveData()
            
            // Trigger reactive state update
            triggerStateUpdate(for: budgetId)
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
