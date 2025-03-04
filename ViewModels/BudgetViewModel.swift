import Foundation
import SwiftUI
import Combine

class BudgetViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var budgets: [Budget] = []
    @Published var showValuesEnabled: Bool = true
    @Published var userAvatar: Data?
    @Published var budgetItemLimitEnabled: Bool = true
    @Published var selectedInsights: [InsightType] = [.savingsRate, .essentialExpenses]
    
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
    }
    
    func saveData() {
        userDefaultsManager.save(budgets, key: saveKey)
        userDefaultsManager.save(showValuesEnabled, key: "show_values")
        userDefaultsManager.save(budgetItemLimitEnabled, key: "budget_item_limit_enabled")
        if let avatar = userAvatar {
            userDefaultsManager.save(avatar, key: "user_avatar")
        }
        saveSelectedInsights()
    }
    
    // MARK: - Insights Management
    
    // Load selected insights from UserDefaults
    func loadSelectedInsights() {
        if let savedInsights: [InsightType] = userDefaultsManager.load(key: "selected_insights") {
            selectedInsights = savedInsights
        } else {
            // Default insights if none are saved
            selectedInsights = [.savingsRate, .essentialExpenses]
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

// Note: The ReactiveStateUpdate extension is removed since it's already defined
// in your ReactiveState.swift file. No need to include it here.
