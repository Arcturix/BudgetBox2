import SwiftUI

// Represents all available insight types that can be displayed
enum InsightType: String, CaseIterable, Identifiable, Codable {
    case savingsRate = "Savings Rate"
    case essentialExpenses = "Essential Expenses"
    case topCategory = "Top Category"
    case budgetsExceeding = "Budgets Exceeding"
    case totalSpent = "Total Spent"
    case monthlyAverage = "Monthly Average"
    case largestExpense = "Largest Expense"
    case recentActivity = "Recent Activity"
    case upcomingPayments = "Upcoming Payments"
    case savingsGoal = "Savings Goal"
    case spendingTrend = "Spending Trend"
    case categoryDistribution = "Category Distribution"
    
    var id: String { self.rawValue }
    
    // Icons for each insight type
    var icon: String {
        switch self {
        case .savingsRate:
            return "chart.line.uptrend.xyaxis"
        case .essentialExpenses:
            return "staroflife.fill"
        case .topCategory:
            return "list.bullet.rectangle"
        case .budgetsExceeding:
            return "exclamationmark.circle"
        case .totalSpent:
            return "banknote"
        case .monthlyAverage:
            return "calendar.badge.clock"
        case .largestExpense:
            return "arrow.up.forward"
        case .recentActivity:
            return "clock"
        case .upcomingPayments:
            return "calendar.badge.exclamationmark"
        case .savingsGoal:
            return "flag.fill"
        case .spendingTrend:
            return "chart.xyaxis.line"
        case .categoryDistribution:
            return "chart.pie.fill"
        }
    }
    
    // Default color for each insight type
    var defaultColor: String {
        switch self {
        case .savingsRate:
            return "4CAF50" // Green
        case .essentialExpenses:
            return "FF9800" // Orange
        case .topCategory:
            return "9C27B0" // Purple
        case .budgetsExceeding:
            return "FF5252" // Red
        case .totalSpent:
            return "2196F3" // Blue
        case .monthlyAverage:
            return "00BCD4" // Cyan
        case .largestExpense:
            return "FFC107" // Amber
        case .recentActivity:
            return "3F51B5" // Indigo
        case .upcomingPayments:
            return "E91E63" // Pink
        case .savingsGoal:
            return "8BC34A" // Light Green
        case .spendingTrend:
            return "FF5722" // Deep Orange
        case .categoryDistribution:
            return "607D8B" // Blue Grey
        }
    }
}
