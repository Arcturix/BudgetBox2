import SwiftUI

// A component that displays key financial insights across all active budgets
struct BudgetInsights: View {
    @EnvironmentObject var viewModel: BudgetViewModel
    
    let budgets: [Budget]  // This should now be only active budgets
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
    
    // MARK: - Layout Constants
    
    // Padding for the entire component relative to screen edges
    private let componentHorizontalPadding: CGFloat = 12
    
    // Vertical spacing between elements
    private let verticalSpacing: CGFloat = 8
    
    // Spacing between the title and insights grid
    private let titleBottomSpacing: CGFloat = 8
    
    // Spacing between items
    private let itemSpacing: CGFloat = 8
    
    // Padding for the entire component top and bottom
    private let componentVerticalPadding: CGFloat = 16
    
    // Icon size
    private let iconSize: CGFloat = 28
    
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
                            .font(.caption)
                            .foregroundColor(.white)
                    }
                    .foregroundColor(Color(hex: "A169F7"))
                    .padding(.vertical, 3)
                    .padding(.horizontal, 8)
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(12)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, titleBottomSpacing)
            
            // Note about active budgets only
            if viewModel.budgets.count != viewModel.activeBudgets.count {
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundColor(.gray)
                        .font(.caption2)
                    Text("Showing insights for active budgets only")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
                .padding(.horizontal)
                .padding(.bottom, 4)
            }
            
            // Single row compact insights
            VStack(spacing: itemSpacing) {
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
        case .netWorth:
            singleRowInsightCard(
                icon: insight.icon,
                title: insight.rawValue,
                value: showValues ? netWorth.formatted(.currency(code: primaryCurrency.rawValue)) : "****",
                color: Color(hex: insight.defaultColor)
            )
            
        case .savingsRate:
            singleRowInsightCard(
                icon: insight.icon,
                title: insight.rawValue,
                value: showValues ? "\(Int(savingsRate))%" : "**%",
                color: Color(hex: insight.defaultColor)
            )
        
        case .essentialExpenses:
            singleRowInsightCard(
                icon: insight.icon,
                title: insight.rawValue,
                value: showValues ? "\(Int(essentialPercentage))%" : "**%",
                color: Color(hex: insight.defaultColor)
            )
        
        case .topCategory:
            singleRowInsightCard(
                icon: topCategory?.category.iconName ?? insight.icon,
                title: insight.rawValue,
                value: showValues ? topCategory?.category.rawValue ?? "None" : "****",
                color: Color(hex: insight.defaultColor)
            )
        
        case .budgetsExceeding:
            singleRowInsightCard(
                icon: budgetsExceedingLimit > 0 ? "exclamationmark.circle" : "checkmark.circle",
                title: insight.rawValue,
                value: "\(budgetsExceedingLimit)/\(budgets.count)",
                color: Color(hex: insight.defaultColor)
            )
            
        case .totalSpent:
            singleRowInsightCard(
                icon: insight.icon,
                title: insight.rawValue,
                value: showValues ? totalSpent.formatted(.currency(code: primaryCurrency.rawValue)) : "****",
                color: Color(hex: insight.defaultColor)
            )
            
        case .monthlyAverage:
            singleRowInsightCard(
                icon: insight.icon,
                title: insight.rawValue,
                value: showValues ? monthlyAverage.formatted(.currency(code: primaryCurrency.rawValue)) : "****",
                color: Color(hex: insight.defaultColor)
            )
            
        case .largestExpense:
            singleRowInsightCard(
                icon: largestExpense?.category.iconName ?? insight.icon,
                title: insight.rawValue,
                value: showValues ? (largestExpense != nil ? "\(largestExpense!.amount.formatted(.currency(code: largestExpense!.currency.rawValue)))" : "None") : "****",
                color: Color(hex: insight.defaultColor)
            )
            
        case .recentActivity:
            singleRowInsightCard(
                icon: recentActivity?.category.iconName ?? insight.icon,
                title: insight.rawValue,
                value: showValues ? (recentActivity != nil ? recentActivity!.name : "None") : "****",
                color: Color(hex: insight.defaultColor)
            )
            
        case .studentLoanDebt:
            // Student loan needs special handling for the dual-stat (balance + payoff date)
            studentLoanSingleRow()
            
        // Placeholder implementations for remaining insight types
        case .upcomingPayments, .savingsGoal, .spendingTrend, .categoryDistribution:
            singleRowInsightCard(
                icon: insight.icon,
                title: insight.rawValue,
                value: "Coming Soon",
                color: Color(hex: insight.defaultColor)
            )
        }
    }
    
    // MARK: - Student Loan Debt Card
    
    private func studentLoanSingleRow() -> some View {
        // Get student loan details from the viewModel
        let loanBalance = viewModel.studentLoanBalance
        let loanCurrency = viewModel.studentLoanCurrency
        let payoffDate = viewModel.calculateStudentLoanPayoffDate()
        
        return HStack(spacing: 8) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color(hex: "F44336").opacity(0.2))
                    .frame(width: iconSize, height: iconSize)
                
                Image(systemName: "creditcard.and.arrow.down")
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "F44336"))
            }
            
            // Title
            Text("Student Loan Debt")
                .font(.subheadline)
                .foregroundColor(.gray)
                .lineLimit(1)
            
            Spacer()
            
            // Value section - includes balance and payoff date if available
            if showValues {
                VStack(alignment: .trailing, spacing: 1) {
                    // Balance
                    Text(loanBalance, format: .currency(code: loanCurrency.rawValue))
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    // Payoff date (if available)
                    if let date = payoffDate {
                        Text("Until \(date, style: .date)")
                            .font(.caption2)
                            .foregroundColor(.gray)
                            .lineLimit(1)
                    }
                }
            } else {
                Text("****")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(Color.black.opacity(0.4))
        .cornerRadius(12)
    }
    
    // MARK: - Helper Views
    
    private func singleRowInsightCard(icon: String, title: String, value: String, color: Color) -> some View {
        HStack(spacing: 8) {
            // Icon
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: iconSize, height: iconSize)
                
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(color)
            }
            
            // Title
            Text(title)
                .font(.subheadline)
                .foregroundColor(.gray)
                .lineLimit(1)
            
            Spacer()
            
            // Value
            Text(value)
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(Color.black.opacity(0.4))
        .cornerRadius(12)
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
                    startYear: 2023,
                    isActive: true
                )
            ],
            showValues: true,
            selectedInsights: [.netWorth, .savingsRate, .essentialExpenses, .studentLoanDebt, .topCategory, .totalSpent],
            onEditTapped: {}
        )
        .padding()
        .environmentObject(BudgetViewModel())
    }
}
