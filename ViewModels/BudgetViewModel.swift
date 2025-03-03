import Foundation
import SwiftUI
import Combine

class BudgetViewModel: ObservableObject {
    @Published var budgets: [Budget] = []
    @Published var showValuesEnabled: Bool = true
    @Published var userAvatar: Data?
    @Published var budgetItemLimitEnabled: Bool = true
    
    private let saveKey = "saved_budgets"
    private let userDefaultsManager = UserDefaultsManager()
    
    // For reactive state updates
    public var _stateUpdatePublisher: PassthroughSubject<UUID, Never>?

    
    init() {
        loadData()
    }
    
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
    }
    
    func addBudget(_ budget: Budget) {
        budgets.append(budget)
        saveData()
    }
    
    func updateBudget(_ budget: Budget) {
        if let index = budgets.firstIndex(where: { $0.id == budget.id }) {
            budgets[index] = budget
            saveData()
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
            
            // Post multiple notifications with highest priority dispatch
            DispatchQueue.main.async {
                // Post notification that budget data has changed
                NotificationCenter.default.post(
                    name: NSNotification.Name("BudgetViewModelUpdated"),
                    object: nil
                )
                
                // Post notification that an expense was added to a specific budget
                NotificationCenter.default.post(
                    name: NSNotification.Name("ExpenseAdded"),
                    object: nil,
                    userInfo: ["budgetId": budgetId]
                )
                
                // Post general refresh notification
                NotificationCenter.default.post(
                    name: NSNotification.Name("RefreshBudgetDetail"),
                    object: nil
                )
                
                // Post force refresh notification
                NotificationCenter.default.post(
                    name: NSNotification.Name("ForceRefreshBudget"),
                    object: nil,
                    userInfo: ["budgetId": budgetId]
                )
            }
            
            // Trigger reactive state update
            self.triggerStateUpdate(for: budgetId)
        }
    }
    
    func updateExpense(_ expense: Expense, in budgetId: UUID) {
        if let budgetIndex = budgets.firstIndex(where: { $0.id == budgetId }),
           let expenseIndex = budgets[budgetIndex].expenses.firstIndex(where: { $0.id == expense.id }) {
            // Update expense in the budget
            budgets[budgetIndex].expenses[expenseIndex] = expense
            
            // Save data to UserDefaults
            saveData()
            
            // Post multiple notifications with highest priority dispatch
            DispatchQueue.main.async {
                // Post notification that budget data has changed
                NotificationCenter.default.post(
                    name: NSNotification.Name("BudgetViewModelUpdated"),
                    object: nil
                )
                
                // Post notification that an expense was edited in a specific budget
                NotificationCenter.default.post(
                    name: NSNotification.Name("ExpenseEdited"),
                    object: nil,
                    userInfo: ["budgetId": budgetId]
                )
                
                // Post general refresh notification
                NotificationCenter.default.post(
                    name: NSNotification.Name("RefreshBudgetDetail"),
                    object: nil
                )
                
                // Post force refresh notification
                NotificationCenter.default.post(
                    name: NSNotification.Name("ForceRefreshBudget"),
                    object: nil,
                    userInfo: ["budgetId": budgetId]
                )
            }
            
            // Trigger reactive state update
            self.triggerStateUpdate(for: budgetId)
        }
    }
    
    func deleteExpense(id: UUID, from budgetId: UUID) {
        if let budgetIndex = budgets.firstIndex(where: { $0.id == budgetId }) {
            // Remove expense from the budget
            budgets[budgetIndex].expenses.removeAll(where: { $0.id == id })
            
            // Save data to UserDefaults
            saveData()
            
            // Post multiple notifications with highest priority dispatch
            DispatchQueue.main.async {
                // Post notification that budget data has changed
                NotificationCenter.default.post(
                    name: NSNotification.Name("BudgetViewModelUpdated"),
                    object: nil
                )
                
                // Post notification that an expense was deleted from a specific budget
                NotificationCenter.default.post(
                    name: NSNotification.Name("ExpenseDeleted"),
                    object: nil,
                    userInfo: ["budgetId": budgetId]
                )
                
                // Post general refresh notification
                NotificationCenter.default.post(
                    name: NSNotification.Name("RefreshBudgetDetail"),
                    object: nil
                )
                
                // Post force refresh notification
                NotificationCenter.default.post(
                    name: NSNotification.Name("ForceRefreshBudget"),
                    object: nil,
                    userInfo: ["budgetId": budgetId]
                )
            }
            
            // Trigger reactive state update
            self.triggerStateUpdate(for: budgetId)
        }
    }
    
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
