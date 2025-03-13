// Views/Components/BudgetCard.swift

import SwiftUI

struct BudgetCard: View {
    let budget: Budget
    let showValues: Bool
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header
            HStack {
                // Icon with color
                Image(systemName: budget.iconName)
                    .foregroundColor(Color(hex: budget.colorHex))
                    .font(.title)
                    .frame(width: 40, height: 40)
                
                // Budget name and type
                VStack(alignment: .leading) {
                    Text(budget.name)
                        .font(.title2)
                        .foregroundColor(ThemeManager.Colors.primaryText)
                    
                    Text(budget.isMonthly ? "Monthly Budget" : "One-time Budget")
                        .font(.body)
                        .foregroundColor(ThemeManager.Colors.secondaryText)
                }
                
                Spacer()
                
                // Amount
                Text(showValues ?
                     budget.amount.formatted(.currency(code: budget.currency.rawValue)) :
                     "****")
                    .font(.title3)
                    .bold()
                    .foregroundColor(ThemeManager.Colors.primaryText)
            }
            
            // Progress bar
            ProgressBarView(
                percent: CGFloat(budget.percentRemaining) / 100,
                color: Color(hex: budget.colorHex)
            )
            .frame(height: 15)
            
            // Remaining amount and percentage
            HStack {
                Text("Remaining")
                    .font(.body)
                    .foregroundColor(ThemeManager.Colors.secondaryText)
                
                Spacer()
                
                Text(showValues ?
                     budget.remainingAmount.formatted(.currency(code: budget.currency.rawValue)) :
                     "****")
                    .foregroundColor(budget.remainingAmount > 0 ? .green : .red)
                    .font(.title3)
                
                Text("\(budget.percentRemaining)%")
                    .font(.body)
                    .foregroundColor(ThemeManager.Colors.secondaryText)
            }
        }
        .padding(20)
        .background(ThemeManager.Colors.tertiary)
        .cornerRadius(20)
    }
}

struct ProgressBarView: View {
    let percent: CGFloat
    let color: Color
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: 7.5)
                    .foregroundColor(Color.gray.opacity(0.3))
                    .frame(height: geometry.size.height)
                
                // Progress
                RoundedRectangle(cornerRadius: 7.5)
                    .foregroundColor(color)
                    .frame(width: max(0, percent * geometry.size.width), height: geometry.size.height)
                    .animation(.easeInOut(duration: 0.5), value: percent)
            }
        }
    }
}

#Preview {
    let sampleBudget = Budget(
        name: "Monthly Budget",
        amount: 1000.0,
        currency: .usd,
        iconName: "dollarsign.circle",
        colorHex: "A169F7",
        isMonthly: true,
        expenses: [],
        startMonth: 1,
        startYear: 2023
    )
    
    return Group {
        BudgetCard(budget: sampleBudget, showValues: true)
            .padding()
            .preferredColorScheme(.light)
        
        BudgetCard(budget: sampleBudget, showValues: false)
            .padding()
            .preferredColorScheme(.dark)
    }
}
