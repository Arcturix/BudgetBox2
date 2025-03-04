import SwiftUI

// A component that displays key financial insights across all budgets
struct BudgetInsights: View {
    let budgets: [Budget]
    let showValues: Bool
    let selectedInsights: [InsightType]
    let onEditTapped: () -> Void
    
    // MARK: - Computed Properties
    
    // Get all expenses across all budgets
    private var allExpenses: [Expense] {
        budgets.flatMap { $0.expenses }
    }
    
    // Calculate savings rate (savings / total expenses)
    private var savingsRate: Double {
        guard !allExpenses.isEmpty else { return 0 }
        
        let totalExpenses = allExpenses.reduce(0) { $0 + $1.amount }
        let savingsAmount = allExpenses
            .filter { $0.category == .savings }
            .reduce(0) { $0 + $1.amount }
        
        return totalExpenses > 0 ? (savingsAmount / totalExpenses) * 100 : 0
    }
    
    // Find top spending category
    private var topCategory: (category: ExpenseCategory, amount: Double)? {
        guard !allExpenses.isEmpty else { return nil }
        
        let groupedByCategory = Dictionary(grouping: allExpenses) { $0.category }
        let categoryTotals = groupedByCategory.mapValues { expenses in
            expenses.reduce(0) { $0 + $1.amount }
        }
        
        // Find the category with the highest total amount
        if let maxCategory = categoryTotals.max(by: { $0.value < $1.value }) {
            return (category: maxCategory.key, amount: maxCategory.value)
        }
        
        return nil
    }
    
    // Calculate percentage of essential expenses
    private var essentialPercentage: Double {
        guard !allExpenses.isEmpty else { return 0 }
        
        let totalAmount = allExpenses.reduce(0) { $0 + $1.amount }
        let essentialAmount = allExpenses
            .filter { $0.isEssential }
            .reduce(0) { $0 + $1.amount }
        
        return totalAmount > 0 ? (essentialAmount / totalAmount) * 100 : 0
    }
    
    // Calculate number of budgets exceeding their limits
    private var budgetsExceedingLimit: Int {
        budgets.filter { $0.remainingAmount < 0 }.count
    }
    
    // Total amount spent across all budgets
    private var totalSpent: Double {
        allExpenses.reduce(0) { $0 + $1.amount }
    }
    
    // Monthly average spending
    private var monthlyAverage: Double {
        guard !allExpenses.isEmpty else { return 0 }
        
        // Get the date of the earliest expense
        if let earliestDate = allExpenses.map({ $0.date }).min() {
            let months = max(1, Calendar.current.dateComponents([.month], from: earliestDate, to: Date()).month ?? 1)
            return totalSpent / Double(months)
        }
        
        return totalSpent
    }
    
    // Largest single expense
    private var largestExpense: Expense? {
        allExpenses.max { $0.amount < $1.amount }
    }
    
    // Most recent activity
    private var recentActivity: Expense? {
        allExpenses.max { $0.date < $1.date }
    }
    
    // Determine primary currency across all budgets
    private var primaryCurrency: Currency {
        let currencyCounts = Dictionary(grouping: budgets) { $0.currency }
            .mapValues { $0.count }
        
        return currencyCounts.max { $0.value < $1.value }?.key ?? .usd
    }
    
    // MARK: - Layout Constants (Customize these to adjust spacing and padding)
    
    // Padding for the entire component relative to screen edges
    private let componentHorizontalPadding: CGFloat = 16
    
    // Vertical spacing between elements
    private let verticalSpacing: CGFloat = 16
    
    // Spacing between the title and insights grid
    private let titleBottomSpacing: CGFloat = 12
    
    // Spacing between grid items
    private let gridItemSpacing: CGFloat = 14
    
    // Padding for the entire component top and bottom
    private let componentVerticalPadding: CGFloat = 20
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: verticalSpacing) {
            // Title with Edit button
            HStack {
                Text("Quick Insights")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: onEditTapped) {
                    HStack(spacing: 4) {
                        Image(systemName: "pencil")
                            .font(.caption)
                        
                        Text("Edit")
                            .font(.subheadline)
                    }
                    .foregroundColor(Color(hex: "A169F7"))
                    .padding(.vertical, 4)
                    .padding(.horizontal, 10)
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(14)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, titleBottomSpacing)
            
            // Insights Grid
            let columns = Array(repeating: GridItem(.flexible()), count: min(2, max(1, selectedInsights.count)))
            
            LazyVGrid(columns: columns, spacing: gridItemSpacing) {
                ForEach(selectedInsights) { insight in
                    insightCardFor(insight: insight)
                }
            }
            .padding(.horizontal)
        }
        // Apply padding to the entire component
        .padding(.horizontal, componentHorizontalPadding)
        .padding(.vertical, componentVerticalPadding)
    }
    
    // MARK: - Helper Functions
    
    @ViewBuilder
    private func insightCardFor(insight: InsightType) -> some View {
        switch insight {
        case .savingsRate:
            insightCard(
                icon: insight.icon,
                title: insight.rawValue,
                value: showValues ? "\(Int(savingsRate))%" : "**%",
                color: Color(hex: insight.defaultColor)
            )
        
        case .essentialExpenses:
            insightCard(
                icon: insight.icon,
                title: insight.rawValue,
                value: showValues ? "\(Int(essentialPercentage))%" : "**%",
                color: Color(hex: insight.defaultColor)
            )
        
        case .topCategory:
            insightCard(
                icon: topCategory?.category.iconName ?? insight.icon,
                title: insight.rawValue,
                value: showValues ? topCategory?.category.rawValue ?? "None" : "****",
                color: Color(hex: insight.defaultColor)
            )
        
        case .budgetsExceeding:
            insightCard(
                icon: budgetsExceedingLimit > 0 ? "exclamationmark.circle" : "checkmark.circle",
                title: insight.rawValue,
                value: "\(budgetsExceedingLimit)/\(budgets.count)",
                color: Color(hex: insight.defaultColor)
            )
            
        case .totalSpent:
            insightCard(
                icon: insight.icon,
                title: insight.rawValue,
                value: showValues ? totalSpent.formatted(.currency(code: primaryCurrency.rawValue)) : "****",
                color: Color(hex: insight.defaultColor)
            )
            
        case .monthlyAverage:
            insightCard(
                icon: insight.icon,
                title: insight.rawValue,
                value: showValues ? monthlyAverage.formatted(.currency(code: primaryCurrency.rawValue)) : "****",
                color: Color(hex: insight.defaultColor)
            )
            
        case .largestExpense:
            insightCard(
                icon: largestExpense?.category.iconName ?? insight.icon,
                title: insight.rawValue,
                value: showValues ? (largestExpense != nil ? "\(largestExpense!.amount.formatted(.currency(code: largestExpense!.currency.rawValue)))" : "None") : "****",
                color: Color(hex: insight.defaultColor)
            )
            
        case .recentActivity:
            insightCard(
                icon: recentActivity?.category.iconName ?? insight.icon,
                title: insight.rawValue,
                value: showValues ? (recentActivity != nil ? recentActivity!.name : "None") : "****",
                color: Color(hex: insight.defaultColor)
            )
            
        // Placeholder implementations for remaining insight types
        case .upcomingPayments, .savingsGoal, .spendingTrend, .categoryDistribution:
            insightCard(
                icon: insight.icon,
                title: insight.rawValue,
                value: "Coming Soon",
                color: Color(hex: insight.defaultColor)
            )
        }
    }
    
    // MARK: - Helper Views
    
    private func insightCard(icon: String, title: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.body)
                    .foregroundColor(.white) // Changed to white for all icons
                
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineLimit(1)
        }
        .padding()
        .background(Color.black.opacity(0.4))
        .cornerRadius(16)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color(hex: "383C51").ignoresSafeArea()
        
        BudgetInsights(
            budgets: [
                Budget(
                    name: "Monthly Budget",
                    amount: 1000.0,
                    currency: .usd,
                    iconName: "dollarsign.circle",
                    colorHex: "A169F7",
                    isMonthly: true,
                    expenses: [
                        Expense(
                            name: "Rent",
                            amount: 500,
                            currency: .usd,
                            category: .housing,
                            isEssential: true
                        ),
                        Expense(
                            name: "Groceries",
                            amount: 200,
                            currency: .usd,
                            category: .food,
                            isEssential: true
                        ),
                        Expense(
                            name: "Savings",
                            amount: 150,
                            currency: .usd,
                            category: .savings,
                            isEssential: true
                        ),
                        Expense(
                            name: "Entertainment",
                            amount: 100,
                            currency: .usd,
                            category: .entertainment,
                            isEssential: false
                        )
                    ],
                    startMonth: 1,
                    startYear: 2023
                )
            ],
            showValues: true,  // This parameter was missing
            selectedInsights: [.savingsRate, .essentialExpenses],
            onEditTapped: {}
        )
        .padding()
    }
}
