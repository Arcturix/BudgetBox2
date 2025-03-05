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
            insightCard(
                icon: insight.icon,
                title: insight.rawValue,
                value: showValues ? netWorth.formatted(.currency(code: primaryCurrency.rawValue)) : "****",
                color: Color(hex: insight.defaultColor)
            )
            
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
            
        case .studentLoanDebt:
            // Create a custom student loan debt card
            studentLoanDebtCard()
            
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
    
    // MARK: - Student Loan Debt Card
    
    private func studentLoanDebtCard() -> some View {
        // Get student loan details from the viewModel
        let loanBalance = viewModel.studentLoanBalance
        let loanCurrency = viewModel.studentLoanCurrency
        let payoffDate = viewModel.calculateStudentLoanPayoffDate()
        let monthlyPayment = viewModel.getStudentLoanMonthlyPayment()
        
        return VStack(alignment: .leading, spacing: 4) {
            // Title row with icon
            HStack {
                ZStack {
                    Circle()
                        .fill(Color(hex: "F44336").opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "creditcard.and.arrow.down")
                        .font(.system(size: 16))
                        .foregroundColor(Color(hex: "F44336"))
                }
                
                Text("Student Loan Debt")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                Spacer()
            }
            
            // Balance
            if showValues {
                Text(loanBalance, format: .currency(code: loanCurrency.rawValue))
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.top, 4)
            } else {
                Text("****")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.top, 4)
            }
            
            // Show monthly payment if exists
            if let payment = monthlyPayment {
                if showValues {
                    Text("Monthly Payment: \(payment, format: .currency(code: loanCurrency.rawValue))")
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.top, 2)
                } else {
                    Text("Monthly Payment: ****")
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.top, 2)
                }
            } else {
                Text("No monthly payment set")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.top, 2)
            }
            
            // Show projected payoff date if available
            if let date = payoffDate {
                if showValues {
                    VStack(alignment: .leading) {
                        Text("Projected Payoff:")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        HStack {
                            Text(date, style: .date)
                                .font(.caption)
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.top, 2)
                } else {
                    Text("Projected Payoff: ****")
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.top, 2)
                }
            }
        }
        .padding()
        .background(Color.black.opacity(0.4))
        .cornerRadius(16)
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Helper Views
    
    private func insightCard(icon: String, title: String, value: String, color: Color) -> some View {
        HStack {
            // Icon with color background
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(color)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                Text(value)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .lineLimit(1)
            }
            .padding(.leading, 8)
            
            Spacer()
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
