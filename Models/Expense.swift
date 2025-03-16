import Foundation
import SwiftUI

struct Expense: Identifiable, Codable, Hashable, Equatable {
    var id: UUID = UUID()
    var name: String
    var amount: Double
    var currency: Currency
    var category: ExpenseCategory
    var date: Date = Date()
    var isEssential: Bool = false
    var isFlagged: Bool = false
    var notes: String = ""
    var reminder: Reminder?
    var interestRate: String? // Property for interest rate
    var expectedAnnualReturn: String? // Property for expected annual return
    var startingBalance: Double? // Renamed from currentBalance
    var isStudentLoanPayment: Bool = false // New property to identify student loan payments
    
    // Implement Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    // Implement Equatable
    static func == (lhs: Expense, rhs: Expense) -> Bool {
        return lhs.id == rhs.id
    }
    
    func convertedAmount(to targetCurrency: Currency) -> Double {
        Currency.convert(amount: amount, from: currency, to: targetCurrency)
    }
    
    // Convert starting balance to target currency if needed
    func convertedStartingBalance(to targetCurrency: Currency) -> Double? {
        guard let balance = startingBalance else { return nil }
        return Currency.convert(amount: balance, from: currency, to: targetCurrency)
    }
}

enum ExpenseCategory: String, Codable, CaseIterable, Hashable {
    case savings = "Savings"
    case housing = "Housing"
    case food = "Food"
    case transportation = "Transportation"
    case utilities = "Utilities"
    case entertainment = "Entertainment"
    case healthcare = "Healthcare"
    case shopping = "Shopping"
    case subscriptions = "Subscriptions"
    case debt = "Debt" // Debt category
    case other = "Other"
    
    var iconName: String {
        switch self {
        case .savings: return "chart.line.uptrend.xyaxis.circle.fill"
        case .housing: return "house.fill"
        case .food: return "fork.knife"
        case .transportation: return "car.fill"
        case .utilities: return "bolt.fill"
        case .entertainment: return "gamecontroller.fill"
        case .healthcare: return "heart.fill"
        case .shopping: return "bag.fill"
        case .subscriptions: return "tv.fill"
        case .debt: return "building.columns" // Icon for debt
        case .other: return "ellipsis.circle.fill"
        }
    }
    
    var colorHex: String {
        switch self {
        case .savings: return "FFD700" // Yellow
        case .housing: return "FF5252" // Red
        case .food: return "4CAF50"    // Green
        case .transportation: return "2196F3" // Blue
        case .utilities: return "FF5252" // Red (same as housing)
        case .entertainment: return "9C27B0" // Purple
        case .healthcare: return "E91E63" // Pink
        case .shopping: return "FF9800" // Orange
        case .subscriptions: return "607D8B" // Blue Grey
        case .debt: return "F44336" // Red for debt
        case .other: return "795548" // Brown
        }
    }
}

struct Reminder: Codable, Hashable, Equatable {
    enum Frequency: String, Codable, Hashable {
        case once, daily, weekly, monthly, yearly
    }
    
    var date: Date
    var frequency: Frequency = .once
}
