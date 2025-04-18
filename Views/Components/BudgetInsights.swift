import SwiftUI

// A component that displays key financial insights across all budgets
struct BudgetInsights: View {
    @EnvironmentObject var viewModel: BudgetViewModel
    
    let budgets: [Budget]
    let showValues: Bool
    let selectedInsights: [InsightType]
    let onEditTapped: () -> Void
    
    // MARK: - Computed Properties
    
    // Get all expenses across all budgets
    private var allExpenses: [Expense] {
        budgets.flatMap { $0.expenses }
    }
    
    // Calculate total net worth (savings expenses + their starting balances)
    private var netWorth: Double {
        let savingsExpenses = allExpenses.filter { $0.category == .savings }
        
        let savingsContributions = savingsExpenses.reduce(0.0) { result, expense in
            // Convert to primary currency if needed
            let amount = expense.currency == primaryCurrency ?
                expense.amount :
                expense.convertedAmount(to: primaryCurrency)
                
            return result + amount
        }
        
        let startingBalances = savingsExpenses.reduce(0.0) { result, expense in
            guard let balance = expense.startingBalance else { return result }
            
            // Convert to primary currency if needed
            let convertedBalance = expense.currency == primaryCurrency ?
                balance :
                expense.convertedStartingBalance(to: primaryCurrency) ?? 0.0
                
            return result + convertedBalance
        }
        
        return savingsContributions + startingBalances
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
    private let gridItemSpacing: CGFloat = 10
    
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
                            .foregroundColor(.white)
                        
                        Text("Edit")
                            .font(.subheadline)
                            .foregroundColor(.white)
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
            
            // Linear Insights Layout
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: gridItemSpacing) {
                    ForEach(selectedInsights) { insight in
                        insightCardFor(insight: insight)
                    }
                }
                .padding(.horizontal)
            }
        }
        // Apply padding to the entire component
        .padding(.horizontal, componentHorizontalPadding)
        .padding(.vertical, componentVerticalPadding)
    }
    
    // MARK: - Helper Functions
    
    @ViewBuilder
    private func insightCardFor(insight: InsightType) -> some View {
        switch insight {
        case .netWorth:
            compactInsightCard(
                icon: insight.icon,
                title: insight.rawValue,
                value: showValues ? netWorth.formatted(.currency(code: primaryCurrency.rawValue)) : "****",
                color: Color(hex: insight.defaultColor)
            )
            
        case .savingsRate:
            compactInsightCard(
                icon: insight.icon,
                title: insight.rawValue,
                value: showValues ? "\(Int(savingsRate))%" : "**%",
                color: Color(hex: insight.defaultColor)
            )
        
        case .essentialExpenses:
            compactInsightCard(
                icon: insight.icon,
                title: insight.rawValue,
                value: showValues ? "\(Int(essentialPercentage))%" : "**%",
                color: Color(hex: insight.defaultColor)
            )
        
        case .topCategory:
            compactInsightCard(
                icon: topCategory?.category.iconName ?? insight.icon,
                title: insight.rawValue,
                value: showValues ? topCategory?.category.rawValue ?? "None" : "****",
                color: Color(hex: insight.defaultColor)
            )
        
        case .budgetsExceeding:
            compactInsightCard(
                icon: budgetsExceedingLimit > 0 ? "exclamationmark.circle" : "checkmark.circle",
                title: insight.rawValue,
                value: "\(budgetsExceedingLimit)/\(budgets.count)",
                color: Color(hex: insight.defaultColor)
            )
            
        case .totalSpent:
            compactInsightCard(
                icon: insight.icon,
                title: insight.rawValue,
                value: showValues ? totalSpent.formatted(.currency(code: primaryCurrency.rawValue)) : "****",
                color: Color(hex: insight.defaultColor)
            )
            
        case .monthlyAverage:
            compactInsightCard(
                icon: insight.icon,
                title: insight.rawValue,
                value: showValues ? monthlyAverage.formatted(.currency(code: primaryCurrency.rawValue)) : "****",
                color: Color(hex: insight.defaultColor)
            )
            
        case .largestExpense:
            compactInsightCard(
                icon: largestExpense?.category.iconName ?? insight.icon,
                title: insight.rawValue,
                value: showValues ? (largestExpense != nil ? "\(largestExpense!.amount.formatted(.currency(code: largestExpense!.currency.rawValue)))" : "None") : "****",
                color: Color(hex: insight.defaultColor)
            )
            
        case .recentActivity:
            compactInsightCard(
                icon: recentActivity?.category.iconName ?? insight.icon,
                title: insight.rawValue,
                value: showValues ? (recentActivity != nil ? recentActivity!.name : "None") : "****",
                color: Color(hex: insight.defaultColor)
            )
            
        case .studentLoanDebt:
            // Create a custom student loan debt card
            compactStudentLoanDebtCard()
            
        // Removed the "Coming Soon" placeholders for:
        // .upcomingPayments, .savingsGoal, .spendingTrend, .categoryDistribution
        default:
            EmptyView()
        }
    }
    
    // MARK: - Compact Student Loan Debt Card
    
    private func compactStudentLoanDebtCard() -> some View {
        // Get student loan details from the viewModel
        let loanBalance = viewModel.studentLoanBalance
        let loanCurrency = viewModel.studentLoanCurrency
        let payoffDate = viewModel.calculateStudentLoanPayoffDate()
        
        return HStack {
            // Icon
            ZStack {
                Circle()
                    .fill(Color(hex: "F44336").opacity(0.2))
                    .frame(width: 36, height: 36)
                
                Image(systemName: "building.columns")
                    .font(.system(size: 16))
                    .foregroundColor(Color(hex: "F44336"))
            }
            
            // Title and Balance
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text("Loan Tracker")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    if showValues {
                        Text(loanCurrency.symbol + "\(Int(loanBalance))")
                            .font(.headline)
                            .foregroundColor(.white)
                    } else {
                        Text("****")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                }
                
                // Show projected payoff date if available
                if let date = payoffDate, showValues {
                    Text("Payoff: \(date, style: .date)")
                        .font(.caption)
                        .foregroundColor(.green)
                } else if showValues {
                    Text("No payoff date available")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(Color.black.opacity(0.4))
        .cornerRadius(16)
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Compact Insight Card
    
    private func compactInsightCard(icon: String, title: String, value: String, color: Color) -> some View {
        HStack {
            // Icon
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 36, height: 36)
                
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(color)
            }
            
            // Title
            Text(title)
                .font(.subheadline)
                .foregroundColor(.gray)
            
            Spacer()
            
            // Value
            Text(value)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .lineLimit(1)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(Color.black.opacity(0.4))
        .cornerRadius(16)
        .frame(maxWidth: .infinity)
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
            showValues: true,
            selectedInsights: [.netWorth, .savingsRate, .essentialExpenses, .studentLoanDebt],
            onEditTapped: {}
        )
        .padding()
        .environmentObject(BudgetViewModel())
    }
}
