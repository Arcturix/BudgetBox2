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
    var notes: String = ""
    var reminder: Reminder?
    var interestRate: String? // New property for interest rate
    var expectedAnnualReturn: String? // New property for expected annual return
    var currentBalance: Double? // New property for current balance
    
    // Implement Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    // Implement Equatable
    static func == (lhs: Expense, rhs: Expense) -> Bool {
        return lhs.id == rhs.id
    }
    
    func convertedAmount(to targetCurrency: Currency) -> Double {
        if currency == targetCurrency {
            return amount
        }
        // In a real app, you'd use a currency conversion service
        // For now, using dummy conversion rates
        let rates: [Currency: [Currency: Double]] = [
            .usd: [.eur: 0.85, .gbp: 0.75, .jpy: 110.0],
            .eur: [.usd: 1.18, .gbp: 0.88, .jpy: 129.5],
            .gbp: [.usd: 1.33, .eur: 1.14, .jpy: 147.0],
            .jpy: [.usd: 0.009, .eur: 0.0077, .gbp: 0.0068]
        ]
        
        if let conversionRate = rates[currency]?[targetCurrency] {
            return amount * conversionRate
        }
        return amount
    }
    
    // Convert current balance to target currency if needed
    func convertedCurrentBalance(to targetCurrency: Currency) -> Double? {
        guard let balance = currentBalance else { return nil }
        
        if currency == targetCurrency {
            return balance
        }
        
        // Use the same conversion rates as for the amount
        let rates: [Currency: [Currency: Double]] = [
            .usd: [.eur: 0.85, .gbp: 0.75, .jpy: 110.0],
            .eur: [.usd: 1.18, .gbp: 0.88, .jpy: 129.5],
            .gbp: [.usd: 1.33, .eur: 1.14, .jpy: 147.0],
            .jpy: [.usd: 0.009, .eur: 0.0077, .gbp: 0.0068]
        ]
        
        if let conversionRate = rates[currency]?[targetCurrency] {
            return balance * conversionRate
        }
        return balance
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
    case subscriptions = "Subscriptions" // Changed from personal
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
        case .subscriptions: return "tv.fill" // Changed from personal
        case .other: return "ellipsis.circle.fill"
        }
    }
    
    var colorHex: String {
        switch self {
        case .savings: return "FFC107"   // Amber
        case .housing: return "FF5252" // Red
        case .food: return "4CAF50"    // Green
        case .transportation: return "2196F3" // Blue
        case .utilities: return "FFC107" // Amber
        case .entertainment: return "9C27B0" // Purple
        case .healthcare: return "E91E63" // Pink
        case .shopping: return "FF9800" // Orange
        case .subscriptions: return "607D8B" // Blue Grey // Changed from personal
        case .other: return "795548"    // Brown
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
