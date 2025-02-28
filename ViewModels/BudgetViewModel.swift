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
            
            budgets[index].expenses.append(expense)
            saveData()
        }
    }
    
    func updateExpense(_ expense: Expense, in budgetId: UUID) {
        if let budgetIndex = budgets.firstIndex(where: { $0.id == budgetId }),
           let expenseIndex = budgets[budgetIndex].expenses.firstIndex(where: { $0.id == expense.id }) {
            budgets[budgetIndex].expenses[expenseIndex] = expense
            saveData()
        }
    }
    
    func deleteExpense(id: UUID, from budgetId: UUID) {
        if let budgetIndex = budgets.firstIndex(where: { $0.id == budgetId }) {
            budgets[budgetIndex].expenses.removeAll(where: { $0.id == id })
            saveData()
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
