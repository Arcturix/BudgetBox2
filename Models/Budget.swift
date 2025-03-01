import Foundation

struct Budget: Identifiable, Codable, Hashable, Equatable {
    var id: UUID = UUID()
    var name: String
    var amount: Double
    var currency: Currency
    var iconName: String
    var colorHex: String
    var isMonthly: Bool = true
    var expenses: [Expense] = []
    var startMonth: Int
    var startYear: Int
    
    
    // Implement Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    // Implement Equatable
    static func == (lhs: Budget, rhs: Budget) -> Bool {
        return lhs.id == rhs.id
    }
    
    var remainingAmount: Double {
        amount - expenses.reduce(0) { total, expense in
            if expense.currency == currency {
                return total + expense.amount
            } else {
                return total + expense.convertedAmount(to: currency)
            }
        }
    }
    
    var percentRemaining: Int {
        let percent = (remainingAmount / amount) * 100
        return max(0, min(100, Int(percent)))
    }
}
