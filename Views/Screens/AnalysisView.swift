import SwiftUI
import Foundation

struct AnalysisView: View {
    // MARK: - Properties
    var budget: Budget
    
    // MARK: - Computed Properties
    
    /// Gets the amount of an expense converted to the budget's currency
    func convertedAmount(for expense: Expense) -> Double {
        // If currencies match, no conversion needed
        if expense.currency == budget.currency {
            return expense.amount
        }
        
        // Otherwise, use the expense's built-in conversion method
        return expense.convertedAmount(to: budget.currency)
    }
    
    /// Groups expenses by category and calculates total for each
    var expensesByCategory: [(category: ExpenseCategory, total: Double)] {
        // Group expenses by category
        let groupedExpenses = Dictionary(grouping: budget.expenses) { expense in
            expense.category
        }
        
        // Map all possible categories and get totals (with currency conversion)
        return ExpenseCategory.allCases.map { category in
            let expenses = groupedExpenses[category] ?? []
            let total = expenses.reduce(0) { sum, expense in
                sum + convertedAmount(for: expense)
            }
            return (category: category, total: total)
        }.filter { $0.total > 0 }.sorted { $0.total > $1.total }
    }
    
    /// Calculates percentage of each category against total budget
    func percentageOfBudget(amount: Double) -> Double {
        guard budget.amount > 0 else { return 0 }
        return (amount / budget.amount) * 100
    }
    
    /// Returns appropriate color based on percentage of budget used
    func indicatorColor(percentage: Double) -> Color {
        switch percentage {
        case 0..<30:
            return .green
        case 30..<70:
            return .yellow
        case 70..<100:
            return .orange
        default:
            return .red
        }
    }
    
    /// Formats currency based on budget settings
    func formatAmount(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = budget.currency.rawValue
        
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }
    
    // Calculate total expenses with currency conversion
    var totalExpenses: Double {
        budget.expenses.reduce(0) { sum, expense in
            sum + convertedAmount(for: expense)
        }
    }
    
    // Calculate remaining budget
    var remainingBudget: Double {
        max(0, budget.amount - totalExpenses)
    }
    
    // MARK: - Body
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack {
                    Text("Category Analysis")
                        .foregroundColor(.white)
                        .font(.headline)
                    
                    Spacer()
                    
                    Text("\(expensesByCategory.count) categories")
                        .foregroundColor(.gray)
                }
                .padding(.horizontal)
                .padding(.top, 8)
                
                if expensesByCategory.isEmpty {
                    // Empty state
                    VStack(spacing: 25) {
                        Spacer(minLength: 40)
                        
                        Image(systemName: "chart.pie.fill")
                            .font(.system(size: 60))
                            .foregroundColor(Color(hex: budget.colorHex).opacity(0.5))
                        
                        Text("No expense data to analyze")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text("Add expenses to see category breakdown")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                        
                        Spacer(minLength: 40)
                    }
                    .frame(minHeight: 300)
                    .frame(maxWidth: .infinity)
                } else {
                    // Top spending categories
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Top Spending")
                            .foregroundColor(.white)
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(expensesByCategory.prefix(3), id: \.category) { item in
                                    TopCategoryCard(
                                        category: item.category,
                                        amount: item.total,
                                        percentage: percentageOfBudget(amount: item.total),
                                        colorHex: budget.colorHex,
                                        currencySymbol: budget.currency.symbol
                                    )
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // All categories grid
                    VStack(alignment: .leading, spacing: 12) {
                        Text("All Categories")
                            .foregroundColor(.white)
                            .font(.headline)
                            .padding(.horizontal)
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                            ForEach(expensesByCategory, id: \.category) { item in
                                CategoryCard(
                                    category: item.category,
                                    amount: item.total,
                                    percentage: percentageOfBudget(amount: item.total),
                                    colorHex: budget.colorHex,
                                    currencySymbol: budget.currency.symbol
                                )
                            }
                        }
                        .padding(.horizontal)
                        
                        // Budget usage summary
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Budget Usage")
                                .foregroundColor(.white)
                                .font(.headline)
                            
                            HStack {
                                Text("Total Spent:")
                                    .foregroundColor(.gray)
                                Spacer()
                                Text(formatAmount(totalExpenses))
                                    .bold()
                                    .foregroundColor(.white)
                            }
                            
                            HStack {
                                Text("Budget Remaining:")
                                    .foregroundColor(.gray)
                                Spacer()
                                Text(formatAmount(remainingBudget))
                                    .bold()
                                    .foregroundColor(remainingBudget > 0 ? .green : .red)
                            }
                            
                            // Progress bar
                            VStack(alignment: .leading, spacing: 8) {
                                GeometryReader { geometry in
                                    ZStack(alignment: .leading) {
                                        // Background
                                        Capsule()
                                            .fill(Color.gray.opacity(0.2))
                                            .frame(height: 12)
                                        
                                        // Progress
                                        Capsule()
                                            .fill(
                                                LinearGradient(
                                                    gradient: Gradient(colors: [
                                                        Color(hex: budget.colorHex),
                                                        Color(hex: budget.colorHex).opacity(0.7)
                                                    ]),
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                            )
                                            .frame(
                                                width: min(geometry.size.width * CGFloat(totalExpenses / budget.amount), geometry.size.width),
                                                height: 12
                                            )
                                    }
                                }
                                .frame(height: 12)
                                
                                HStack {
                                    Text("0%")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    
                                    Spacer()
                                    
                                    Text("100%")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(16)
                        .padding(.horizontal)
                        .padding(.bottom, 24)
                    }
                }
            }
        }
        .background(Color(hex: "383C51"))
    }
}

// MARK: - Supporting Views

struct TopCategoryCard: View {
    var category: ExpenseCategory
    var amount: Double
    var percentage: Double
    var colorHex: String
    var currencySymbol: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Category icon with circle background
            ZStack {
                Circle()
                    .fill(Color(hex: category.colorHex))
                    .frame(width: 50, height: 50)
                
                Image(systemName: category.iconName)
                    .font(.title2)
                    .foregroundColor(.white)
            }
            
            // Category name
            Text(category.rawValue)
                .font(.headline)
                .foregroundColor(.white)
                .lineLimit(1)
            
            // Amount
            Text("\(currencySymbol)\(String(format: "%.2f", amount))")
                .font(.subheadline)
                .bold()
                .foregroundColor(Color(hex: colorHex))
            
            // Percentage
            Text(String(format: "%.1f%% of budget", percentage))
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding()
        .frame(width: 150, height: 160)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(16)
    }
}

struct CategoryCard: View {
    var category: ExpenseCategory
    var amount: Double
    var percentage: Double
    var colorHex: String
    var currencySymbol: String
    
    var body: some View {
        ZStack {
            // Background with category icon
            Image(systemName: category.iconName)
                .font(.system(size: 50))
                .foregroundColor(Color(hex: category.colorHex).opacity(0.15))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                .padding(.trailing, 8)
                .padding(.bottom, 8)
            
            // Content
            VStack(alignment: .leading, spacing: 8) {
                // Category name
                Text(category.rawValue)
                    .font(.headline)
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                // Amount
                Text("\(currencySymbol)\(String(format: "%.2f", amount))")
                    .font(.title3)
                    .bold()
                    .foregroundColor(Color(hex: colorHex))
                
                // Percentage of budget
                Text(String(format: "%.1f%%", percentage))
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.top, 2)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color.gray.opacity(0.1))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(hex: category.colorHex).opacity(0.5), lineWidth: 1)
        )
    }
}

// Note: Using existing Color(hex:) and Currency.symbol extensions

// MARK: - Preview Provider

struct AnalysisView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleExpenses = [
            Expense(
                name: "Groceries",
                amount: 150.0,
                currency: .usd,
                category: .food,
                date: Date(),
                isEssential: true,
                notes: "Weekly grocery shopping"
            ),
            Expense(
                name: "Rent",
                amount: 1200.0,
                currency: .usd,
                category: .housing,
                date: Date(),
                isEssential: true,
                notes: "Monthly rent"
            ),
            Expense(
                name: "Netflix",
                amount: 15.99,
                currency: .usd,
                category: .entertainment,
                date: Date(),
                isEssential: false,
                notes: "Monthly subscription"
            ),
            Expense(
                name: "Investment",
                amount: 500.0,
                currency: .usd,
                category: .savings,
                date: Date(),
                isEssential: true,
                notes: "Monthly investment"
            )
        ]

        let sampleBudget = Budget(
            name: "Monthly Budget",
            amount: 2000.0,
            currency: .usd,
            iconName: "dollarsign.circle",
            colorHex: "A169F7",
            isMonthly: true,
            expenses: sampleExpenses,
            startMonth: 1,
            startYear: 2023
        )

        return AnalysisView(budget: sampleBudget)
            .preferredColorScheme(.dark)
    }
}
