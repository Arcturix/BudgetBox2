import SwiftUI
import Foundation

struct AnalysisView: View {
    // MARK: - Properties
    var budget: Budget
    @State private var selectedSection: AnalysisSection = .categories
    
    enum AnalysisSection: String, CaseIterable {
        case categories = "Categories"
        case currencies = "Currencies"
    }
    
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
        }
        .filter { $0.total > 0 }
        .sorted { (a: (category: ExpenseCategory, total: Double), b: (category: ExpenseCategory, total: Double)) -> Bool in
            return a.total > b.total
        }
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
    
    // MARK: - Body
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Section Selector
                segmentedPicker
                    .padding(.horizontal)
                
                Divider()
                    .background(Color.gray.opacity(0.3))
                    .padding(.horizontal)
                
                if budget.expenses.isEmpty {
                    // Empty state
                    emptyStateView
                } else {
                    // Content based on selected section
                    switch selectedSection {
                    case .categories:
                        categoryAnalysisSection
                    case .currencies:
                        CurrencyBreakdownSection(budget: budget, colorHex: budget.colorHex)
                    }
                }
            }
        }
        .background(Color(hex: "020514"))
    }
    
    // MARK: - UI Components
    
    private var segmentedPicker: some View {
        HStack {
            ForEach(AnalysisSection.allCases, id: \.self) { section in
                Button(action: {
                    withAnimation {
                        selectedSection = section
                    }
                }) {
                    VStack(spacing: 8) {
                        Text(section.rawValue)
                            .fontWeight(selectedSection == section ? .bold : .regular)
                            .foregroundColor(selectedSection == section ? .white : .gray)
                        
                        // Indicator bar
                        Rectangle()
                            .fill(selectedSection == section ? Color(hex: budget.colorHex) : Color.clear)
                            .frame(height: 3)
                            .cornerRadius(1.5)
                    }
                    .padding(.vertical, 8)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 25) {
            Spacer(minLength: 40)
            
            Image(systemName: "chart.pie.fill")
                .font(.system(size: 60))
                .foregroundColor(Color(hex: budget.colorHex).opacity(0.5))
            
            Text("No expense data to analyze")
                .font(.headline)
                .foregroundColor(.white)
            
            Text("Add expenses to see category and currency breakdowns")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
            
            Spacer(minLength: 40)
        }
        .frame(minHeight: 300)
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Category Analysis Section
    
    private var categoryAnalysisSection: some View {
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
                .padding(.bottom, 24)
            }
        }
    }
}

// MARK: - Currency Breakdown Section
struct CurrencyBreakdownSection: View {
    let budget: Budget
    let colorHex: String
    
    // Computed properties
    var currencyBreakdown: [(currency: Currency, amount: Double, converted: Double)] {
        // Group expenses by currency
        let groupedByCurrency = Dictionary(grouping: budget.expenses) { expense in
            expense.currency
        }
        
        // Calculate totals for each currency (both original and converted)
        let breakdownData = Currency.allCases.compactMap { currency -> (Currency, Double, Double)? in
            let expensesInCurrency = groupedByCurrency[currency] ?? []
            
            // Skip if no expenses in this currency
            if expensesInCurrency.isEmpty {
                return nil
            }
            
            // Original amount in currency
            let originalAmount = expensesInCurrency.reduce(0) { $0 + $1.amount }
            
            // Converted amount to budget currency
            let convertedAmount = expensesInCurrency.reduce(0) { $0 + $1.convertedAmount(to: budget.currency) }
            
            return (currency, originalAmount, convertedAmount)
        }
        
        return breakdownData.sorted { (a: (Currency, Double, Double), b: (Currency, Double, Double)) -> Bool in
            return a.2 > b.2
        }
    }
    
    var totalExpensesConverted: Double {
        currencyBreakdown.reduce(0) { $0 + $1.converted }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("Currency Breakdown")
                    .foregroundColor(.white)
                    .font(.headline)
                
                Spacer()
                
                Text("\(currencyBreakdown.count) currencies")
                    .foregroundColor(.gray)
            }
            .padding(.horizontal)
            
            if currencyBreakdown.isEmpty {
                Text("No expenses to analyze")
                    .foregroundColor(.gray)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .center)
            } else {
                // Currency Distribution Chart
                VStack(alignment: .leading, spacing: 4) {
                    Text("Distribution")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .padding(.horizontal)
                    
                    CurrencyDistributionChart(
                        currencyData: currencyBreakdown.map { ($0.currency, $0.converted) },
                        totalAmount: totalExpensesConverted,
                        colorHex: colorHex
                    )
                    .frame(height: 30)
                    .padding(.horizontal)
                    
                    // Legend
                    CurrencyLegend()
                        .padding(.top, 4)
                }
                
                // Currency Detail Cards
                ForEach(currencyBreakdown, id: \.currency) { currencyData in
                    let percentage = (currencyData.converted / totalExpensesConverted) * 100
                    let isMainCurrency = currencyData.currency == budget.currency
                    
                    CurrencyBreakdownCard(
                        currency: currencyData.currency,
                        amount: currencyData.amount,
                        percentage: percentage,
                        convertedAmount: currencyData.converted,
                        budgetCurrency: budget.currency,
                        colorHex: colorHex,
                        isMainCurrency: isMainCurrency
                    )
                    .padding(.horizontal)
                }
            }
        }
    }
}

// MARK: - Currency Breakdown Card
struct CurrencyBreakdownCard: View {
    let currency: Currency
    let amount: Double
    let percentage: Double
    let convertedAmount: Double
    let budgetCurrency: Currency
    let colorHex: String
    let isMainCurrency: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // Currency Symbol
            ZStack {
                Circle()
                    .fill(Color(hex: colorHex).opacity(0.2))
                    .frame(width: 45, height: 45)
                
                Text(currency.symbol)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(Color(hex: colorHex))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                // Currency Code
                HStack {
                    Text(currency.rawValue)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    if isMainCurrency {
                        Text("(Budget Currency)")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                
                // Original Amount
                Text("\(currency.symbol)\(amount, specifier: "%.2f")")
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                // Converted amount (if different from budget currency)
                if !isMainCurrency {
                    Text("\(budgetCurrency.symbol)\(convertedAmount, specifier: "%.2f") converted")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            // Percentage
            VStack(alignment: .trailing) {
                Text("\(percentage, specifier: "%.1f")%")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(Color(hex: colorHex))
                
                PercentageBar(percent: percentage / 100, color: Color(hex: colorHex))
                    .frame(width: 60, height: 6)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(16)
    }
}

// MARK: - Percentage Bar
struct PercentageBar: View {
    let percent: CGFloat
    let color: Color
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: 3)
                    .foregroundColor(Color.gray.opacity(0.3))
                    .frame(height: geometry.size.height)
                
                // Progress
                RoundedRectangle(cornerRadius: 3)
                    .foregroundColor(color)
                    .frame(width: max(0, percent * geometry.size.width), height: geometry.size.height)
            }
        }
    }
}

// MARK: - Currency Distribution Chart
struct CurrencyDistributionChart: View {
    let currencyData: [(currency: Currency, amount: Double)]
    let totalAmount: Double
    let colorHex: String
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .top) {
                // Currency Distribution as a horizontal bar chart
                HStack(spacing: 0) {
                    ForEach(currencyData, id: \.currency) { item in
                        let width = (item.amount / totalAmount) * geometry.size.width
                        
                        Rectangle()
                            .fill(colorForCurrency(item.currency))
                            .frame(width: max(width, 1)) // Ensure at least 1px width
                    }
                }
                .frame(height: 20)
                .cornerRadius(10)
                
                // Labels on top of the chart
                HStack(spacing: 0) {
                    ForEach(currencyData, id: \.currency) { item in
                        let width = (item.amount / totalAmount) * geometry.size.width
                        
                        // Only show label if segment is wide enough
                        if width > 60 {
                            Text(item.currency.symbol)
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .frame(width: width, alignment: .center)
                        }
                    }
                }
                .frame(height: 20)
            }
        }
    }
    
    private func colorForCurrency(_ currency: Currency) -> Color {
        switch currency {
        case .usd:
            return Color.green.opacity(0.8)
        case .eur:
            return Color.blue.opacity(0.8)
        case .gbp:
            return Color.purple.opacity(0.8)
        case .jpy:
            return Color.red.opacity(0.8)
        }
    }
}

// MARK: - Legend for Currency Colors
struct CurrencyLegend: View {
    var body: some View {
        HStack(spacing: 12) {
            ForEach(Currency.allCases, id: \.self) { currency in
                HStack(spacing: 4) {
                    Circle()
                        .fill(colorForCurrency(currency))
                        .frame(width: 8, height: 8)
                    
                    Text(currency.rawValue)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(.horizontal)
    }
    
    private func colorForCurrency(_ currency: Currency) -> Color {
        switch currency {
        case .usd:
            return Color.green.opacity(0.8)
        case .eur:
            return Color.blue.opacity(0.8)
        case .gbp:
            return Color.purple.opacity(0.8)
        case .jpy:
            return Color.red.opacity(0.8)
        }
    }
}

// MARK: - Supporting Views for Categories
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
            // Background with icon
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
            ),
            Expense(
                name: "Europe Trip",
                amount: 300.0,
                currency: .eur,
                category: .entertainment,
                date: Date(),
                isEssential: false,
                notes: "Weekend getaway"
            ),
            Expense(
                name: "UK Subscription",
                amount: 25.0,
                currency: .gbp,
                category: .subscriptions,
                date: Date(),
                isEssential: false,
                notes: "Monthly magazine"
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
