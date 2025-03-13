import SwiftUI
import Foundation

// Modified sparkline that shows both contributions and current value
private func simpleSparklineView(color: Color) -> some View {
    ZStack {
        // Contributions line (solid)
        Path { path in
            path.move(to: CGPoint(x: 0, y: 30))
            path.addLine(to: CGPoint(x: 20, y: 24))
            path.addLine(to: CGPoint(x: 40, y: 18))
            path.addLine(to: CGPoint(x: 60, y: 12))
            path.addLine(to: CGPoint(x: 80, y: 6))
            path.addLine(to: CGPoint(x: 100, y: 0))
        }
        .stroke(color, lineWidth: 2)
        
        // Current value line (dotted)
        Path { path in
            path.move(to: CGPoint(x: 0, y: 30))
            path.addLine(to: CGPoint(x: 20, y: 23))
            path.addLine(to: CGPoint(x: 40, y: 16))
            path.addLine(to: CGPoint(x: 60, y: 9))
            path.addLine(to: CGPoint(x: 80, y: 2))
            path.addLine(to: CGPoint(x: 100, y: -5))  // Goes slightly higher to show growth
        }
        .stroke(color, style: StrokeStyle(
            lineWidth: 2,
            dash: [4, 4]  // Creates dotted line effect
        ))
        .opacity(0.6)  // Makes the dotted line slightly transparent
    }
}

struct SavingsView: View {
    // MARK: - Properties
    
    let budget: Budget
    @State private var selectedSavingsItem: Expense? = nil
    
    // Time periods for projections
    let projectionPeriods = [
        (months: 6, label: "6 Months"),
        (months: 12, label: "1 Year"),
        (months: 24, label: "2 Years"),
        (months: 60, label: "5 Years"),
        (months: 120, label: "10 Years")
    ]
    
    // MARK: - Computed Properties
    
    // Filter expenses to only include those in the 'savings' category
    var savingsItems: [Expense] {
        budget.expenses.filter { $0.category == .savings }
            .sorted(by: { $0.date > $1.date })
    }
    
    // Calculate total net worth across all savings items
    private var totalNetWorth: Double {
        savingsItems.reduce(0) { total, item in
            total + calculateCurrentValue(for: item)
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack {
                    Text("Savings Overview")
                        .foregroundColor(.white)
                        .font(.headline)
                    
                    Spacer()
                    
                    Text("\(savingsItems.count) items")
                        .foregroundColor(.gray)
                }
                .padding(.horizontal)
                .padding(.top, 8)
                
                // Net Worth Card (only show if there are savings items)
                if !savingsItems.isEmpty {
                    netWorthCard
                }
                
                if savingsItems.isEmpty {
                    emptyStateView
                } else if savingsItems.count == 1 {
                    // Automatically show details view when there's only one item
                    savingsDetailsView(for: savingsItems[0])
                } else if let selected = selectedSavingsItem {
                    // Show detailed projections for selected item when multiple items exist
                    savingsDetailsView(for: selected)
                } else {
                    // Show grid of savings items when multiple items exist
                    savingsItemsGridView
                }
            }
            .padding(.bottom, 24)
        }
        .background(Color(hex: "020514"))
        .onChange(of: savingsItems) { _, newValue in
            // If the selected item is no longer in the list, deselect it
            if let selected = selectedSavingsItem, !newValue.contains(where: { $0.id == selected.id }) {
                selectedSavingsItem = nil
            }
            
            // When there's only one item, automatically select it
            if newValue.count == 1 && selectedSavingsItem == nil {
                selectedSavingsItem = newValue[0]
            }
            
            // When there are no more items, clear selection
            if newValue.isEmpty {
                selectedSavingsItem = nil
            }
        }
        .onAppear {
            // Automatically select the single item when view appears
            if savingsItems.count == 1 && selectedSavingsItem == nil {
                selectedSavingsItem = savingsItems[0]
            }
        }
    }
    
    // MARK: - Subviews
    
    private var netWorthCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Net Worth")
                .font(.headline)
                .foregroundColor(.white)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(budget.currency.symbol)\(totalNetWorth, specifier: "%.2f")")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(Color(hex: budget.colorHex))
                    
                    Text("Total savings across all accounts")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                // Add a simple icon
                ZStack {
                    Circle()
                        .fill(Color(hex: budget.colorHex).opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: "chart.pie.fill")
                        .font(.title2)
                        .foregroundColor(Color(hex: budget.colorHex))
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(16)
        .padding(.horizontal)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 25) {
            Spacer(minLength: 40)
            
            Image(systemName: "banknote")
                .font(.system(size: 60))
                .foregroundColor(Color(hex: budget.colorHex).opacity(0.5))
            
            Text("No savings items yet")
                .font(.headline)
                .foregroundColor(.white)
            
            Text("Add expenses with the 'Savings' category to track your savings growth over time.")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Spacer(minLength: 40)
        }
        .frame(minHeight: 300)
        .frame(maxWidth: .infinity)
    }
    
    private var savingsItemsGridView: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            ForEach(savingsItems) { item in
                savingsItemCard(for: item)
                    .onTapGesture {
                        withAnimation {
                            selectedSavingsItem = item
                        }
                    }
            }
        }
        .padding(.horizontal)
    }
    
    private func savingsItemCard(for item: Expense) -> some View {
        ZStack {
            // Background with icon
            Image(systemName: "chart.line.uptrend.xyaxis.circle.fill")
                .font(.system(size: 50))
                .foregroundColor(Color.yellow.opacity(0.1))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                .padding(.trailing, 8)
                .padding(.bottom, 8)
            
            // Content
            VStack(alignment: .leading, spacing: 8) {
                // Name
                Text(item.name)
                    .font(.headline)
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                // Current value
                Text("\(budget.currency.symbol)\(calculateCurrentValue(for: item), specifier: "%.2f")")
                    .font(.title3)
                    .bold()
                    .foregroundColor(Color(hex: budget.colorHex))
                
                // Starting balance if present
                if let startingBalance = item.startingBalance, startingBalance > 0 {
                    HStack {
                        Image(systemName: "banknote")
                            .foregroundColor(.blue)
                            .font(.caption)
                        
                        Text("Initial: \(budget.currency.symbol)\(startingBalance, specifier: "%.2f")")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                
                // Monthly contribution
                HStack {
                    Image(systemName: "arrow.up.forward")
                        .foregroundColor(.green)
                        .font(.caption)
                    
                    Text("\(budget.currency.symbol)\(item.amount, specifier: "%.2f")/mo")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                // Date
                Text("since \(dateFormatter.string(from: item.date))")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color.gray.opacity(0.1))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.yellow.opacity(0.5), lineWidth: 1)
        )
    }
    
    private func savingsDetailsView(for item: Expense) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            // Only show back button when there are multiple savings items
            if savingsItems.count > 1 {
                // Header with back button
                HStack {
                    Button(action: {
                        withAnimation {
                            selectedSavingsItem = nil
                        }
                    }) {
                        HStack {
                            Image(systemName: "chevron.left")
                            Text("Back to All Savings")
                        }
                        .foregroundColor(Color(hex: budget.colorHex))
                    }
                    
                    Spacer()
                }
                .padding(.horizontal)
            }
            
            // Savings item details
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    // Add savings icon
                    ZStack {
                        Circle()
                            .fill(Color.yellow)
                            .frame(width: 50, height: 50)
                        
                        Image(systemName: "chart.line.uptrend.xyaxis.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                    
                    Text(item.name)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                
                HStack {
                    VStack(alignment: .leading) {
                        Text("Monthly contribution")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Text("\(budget.currency.symbol)\(item.amount, specifier: "%.2f")")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text("Started")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Text(dateFormatter.string(from: item.date))
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                }
                
                if let initialBalance = item.startingBalance, initialBalance > 0 {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Starting balance")
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                            Text("\(budget.currency.symbol)\(initialBalance, specifier: "%.2f")")
                                .font(.headline)
                                .foregroundColor(.blue)
                        }
                    }
                }
                
                if !item.notes.isEmpty {
                    Text(item.notes)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .padding(.top, 4)
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(16)
            .padding(.horizontal)
            
            // Current value
            currentValueSection(for: item)
            
            // Projections
            projectionsView(for: item)
        }
    }
    
    private func currentValueSection(for item: Expense) -> some View {
        let currentValue = calculateCurrentValue(for: item)
        let monthsActive = monthsSince(item.date)
        let contributions = Double(monthsActive) * item.amount
        let initialBalance = item.startingBalance ?? 0.0
        
        return VStack(alignment: .leading, spacing: 12) {
            Text("Current Value")
                .font(.headline)
                .foregroundColor(.white)
            
            HStack {
                Text("\(budget.currency.symbol)\(currentValue, specifier: "%.2f")")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(Color(hex: budget.colorHex))
                
                Spacer()
                
                // Simple sparkline
                simpleSparklineView(color: Color(hex: budget.colorHex))
                    .frame(width: 100, height: 30)
            }
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Months active")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Text("\(monthsActive)")
                        .font(.subheadline)
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Total contributions")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Text("\(budget.currency.symbol)\(contributions, specifier: "%.2f")")
                        .font(.subheadline)
                        .foregroundColor(.white)
                }
            }
            
            if initialBalance > 0 {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Starting balance")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Text("\(budget.currency.symbol)\(initialBalance, specifier: "%.2f")")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text("Interest earned")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Text("\(budget.currency.symbol)\(currentValue - contributions - initialBalance, specifier: "%.2f")")
                            .font(.subheadline)
                            .foregroundColor(.green)
                    }
                }
            } else {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Interest earned")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Text("\(budget.currency.symbol)\(currentValue - contributions, specifier: "%.2f")")
                            .font(.subheadline)
                            .foregroundColor(.green)
                    }
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(16)
        .padding(.horizontal)
    }
    
    private func projectionsView(for item: Expense) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Future Projections")
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal)
                .padding(.top, 8)
            
            ForEach(projectionPeriods, id: \.months) { period in
                let projection = calculateProjection(for: item, months: period.months)
                let currentMonths = monthsSince(item.date)
                let totalMonths = currentMonths + period.months
                let totalContributions = item.amount * Double(totalMonths)
                let initialBalance = item.startingBalance ?? 0.0
                let interestGained = max(0, projection - totalContributions - initialBalance)
                
                // Calculate the future date
                let futureDate = Calendar.current.date(byAdding: .month, value: period.months, to: Date()) ?? Date()
                
                VStack(spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(period.label)
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Text("\(projectionDateFormatter.string(from: futureDate))")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("\(budget.currency.symbol)\(projection, specifier: "%.2f")")
                                .font(.headline)
                                .foregroundColor(Color(hex: budget.colorHex))
                        }
                    }
                    
                    // Simplified projection details
                    VStack(spacing: 8) {
                        HStack {
                            Text("Total contributions:")
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                            Spacer()
                            
                            Text("\(budget.currency.symbol)\(totalContributions, specifier: "%.2f")")
                                .font(.subheadline)
                                .foregroundColor(.white)
                        }
                        
                        if initialBalance > 0 {
                            HStack {
                                Text("Starting balance:")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                
                                Spacer()
                                
                                Text("\(budget.currency.symbol)\(initialBalance, specifier: "%.2f")")
                                    .font(.subheadline)
                                    .foregroundColor(.blue)
                            }
                        }
                        
                        HStack {
                            Text("Interest earned:")
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                            Spacer()
                            
                            Text("\(budget.currency.symbol)\(interestGained, specifier: "%.2f")")
                                .font(.subheadline)
                                .foregroundColor(.green)
                        }
                    }
                    .padding(.top, 4)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(16)
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func calculateCurrentValue(for item: Expense) -> Double {
        let monthsActive = monthsSince(item.date)
        
        // Get initial balance (converted to budget currency if needed)
        let initialBalance = item.startingBalance ?? 0.0
        
        // Check if there's an interest rate specified in the fields
        if let interestRateStr = item.interestRate, !interestRateStr.isEmpty,
           let interestRate = Double(interestRateStr.trimmingCharacters(in: .whitespaces)) {
            
            let monthlyInterestRate = interestRate / 100 / 12
            
            if monthlyInterestRate > 0 {
                // Calculate future value of the regular contributions
                let contributionsFV = item.amount * ((pow(1 + monthlyInterestRate, Double(monthsActive)) - 1) / monthlyInterestRate)
                
                // Calculate future value of the initial balance
                let initialBalanceFV = initialBalance * pow(1 + monthlyInterestRate, Double(monthsActive))
                
                // Total future value is the sum of both
                return contributionsFV + initialBalanceFV
            }
        } else if let expectedReturnStr = item.expectedAnnualReturn, !expectedReturnStr.isEmpty,
                  let expectedReturn = Double(expectedReturnStr.trimmingCharacters(in: .whitespaces)) {
            
            let monthlyReturnRate = expectedReturn / 100 / 12
            
            if monthlyReturnRate > 0 {
                // Calculate using expected annual return instead
                let contributionsFV = item.amount * ((pow(1 + monthlyReturnRate, Double(monthsActive)) - 1) / monthlyReturnRate)
                let initialBalanceFV = initialBalance * pow(1 + monthlyReturnRate, Double(monthsActive))
                return contributionsFV + initialBalanceFV
            }
        }
        
        // If no interest rate or expected return is provided, or both are 0
        // it's just the sum of contributions plus initial balance
        return item.amount * Double(monthsActive) + initialBalance
    }
    
    private func calculateProjection(for item: Expense, months: Int) -> Double {
        let currentMonths = monthsSince(item.date)
        let totalMonths = currentMonths + months
        
        // Get initial balance
        let initialBalance = item.startingBalance ?? 0.0
        
        // Check if there's an interest rate specified in the fields
        if let interestRateStr = item.interestRate, !interestRateStr.isEmpty,
           let interestRate = Double(interestRateStr.trimmingCharacters(in: .whitespaces)) {
            
            let monthlyInterestRate = interestRate / 100 / 12
            
            if monthlyInterestRate > 0 {
                // Calculate future value of regular contributions from start date to projection end
                let contributionsFV = item.amount * ((pow(1 + monthlyInterestRate, Double(totalMonths)) - 1) / monthlyInterestRate)
                
                // Calculate future value of the initial balance
                let initialBalanceFV = initialBalance * pow(1 + monthlyInterestRate, Double(totalMonths))
                
                // Total future value is the sum of both
                return contributionsFV + initialBalanceFV
            }
        } else if let expectedReturnStr = item.expectedAnnualReturn, !expectedReturnStr.isEmpty,
                  let expectedReturn = Double(expectedReturnStr.trimmingCharacters(in: .whitespaces)) {
            
            let monthlyReturnRate = expectedReturn / 100 / 12
            
            if monthlyReturnRate > 0 {
                // Calculate using expected annual return instead
                let contributionsFV = item.amount * ((pow(1 + monthlyReturnRate, Double(totalMonths)) - 1) / monthlyReturnRate)
                let initialBalanceFV = initialBalance * pow(1 + monthlyReturnRate, Double(totalMonths))
                return contributionsFV + initialBalanceFV
            }
        }
        
        // If no interest rate or expected return is provided, or both are 0
        // it's just the sum of contributions plus initial balance
        return item.amount * Double(totalMonths) + initialBalance
    }
    
    private func monthsSince(_ date: Date) -> Int {
        let calendar = Calendar.current
        let startComponents = calendar.dateComponents([.year, .month], from: date)
        let currentComponents = calendar.dateComponents([.year, .month], from: Date())
        
        let yearDiff = currentComponents.year! - startComponents.year!
        let monthDiff = currentComponents.month! - startComponents.month!
        
        return max(1, yearDiff * 12 + monthDiff + 1) // +1 to include current month, minimum 1 month
    }
    
    // MARK: - Formatters
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }
    
    private var projectionDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter
    }
}

struct SavingsView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleExpenses = [
            Expense(
                name: "Retirement Fund",
                amount: 200.0,
                currency: .eur,
                category: .savings,
                date: Calendar.current.date(byAdding: .month, value: -6, to: Date())!,
                isEssential: true,
                notes: "",
                interestRate: "7.0",
                startingBalance: 1000.0
            ),
            Expense(
                name: "Emergency Fund",
                amount: 100.0,
                currency: .eur,
                category: .savings,
                date: Calendar.current.date(byAdding: .month, value: -3, to: Date())!,
                isEssential: true,
                notes: "",
                expectedAnnualReturn: "2.5",
                startingBalance: 500.0
            )
        ]
        
        let sampleBudget = Budget(
            name: "Monthly Budget",
            amount: 1000.0,
            currency: .eur,
            iconName: "dollarsign.circle",
            colorHex: "A169F7",
            isMonthly: true,
            expenses: sampleExpenses,
            startMonth: 1,
            startYear: 2023
        )
        
        return SavingsView(budget: sampleBudget)
            .preferredColorScheme(.dark)
    }
}
