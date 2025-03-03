import SwiftUI

struct ExpenseRow: View {
    // MARK: - Properties
    let expense: Expense
    let showValues: Bool
    let budgetCurrency: Currency
    let budgetColorHex: String
    
    // MARK: - State
    @State private var showNotes = false
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 0) {
            // Main row content
            HStack(spacing: 12) {
                // Category icon
                ZStack {
                    Circle()
                        .fill(Color(hex: expense.category.colorHex).opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: expense.category.iconName)
                        .foregroundColor(Color(hex: expense.category.colorHex))
                        .font(.system(size: 16))
                }
                
                // Expense details
                VStack(alignment: .leading, spacing: 4) {
                    // Title row
                    HStack {
                        Text(expense.name)
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        // Notes icon - shows if the expense has notes
                        if !expense.notes.isEmpty {
                            Image(systemName: "note.text")
                                .foregroundColor(.gray)
                                .font(.caption)
                        }
                        
                        // Essential badge if applicable
                        if expense.isEssential {
                            Text("Essential")
                                .font(.caption)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.2))
                                .foregroundColor(.blue)
                                .cornerRadius(4)
                        }
                    }
                    
                    // Category and date
                    HStack {
                        Text(expense.category.rawValue)
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Spacer()
                        
                        Text(expense.date.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        // Bell icon - shows if a reminder is set
                        if expense.reminder != nil {
                            Image(systemName: "bell.fill")
                                .foregroundColor(.yellow)
                                .font(.caption)
                        }
                    }
                }
                
                Spacer()
                
                // Amount
                VStack(alignment: .trailing) {
                    if showValues {
                        Text("-\(expense.amount.formatted(.currency(code: expense.currency.rawValue)))")
                            .foregroundColor(Color(hex: budgetColorHex))
                            .font(.headline)
                        
                        // Show conversion if currencies differ
                        if expense.currency != budgetCurrency {
                            let convertedAmount = expense.convertedAmount(to: budgetCurrency)
                            Text("(\(convertedAmount.formatted(.currency(code: budgetCurrency.rawValue))))")
                                .foregroundColor(.orange)
                                .font(.caption)
                        }
                    } else {
                        Text("-****")
                            .foregroundColor(Color(hex: budgetColorHex))
                            .font(.headline)
                    }
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 8)
            .contentShape(Rectangle())
            .onTapGesture {
                if !expense.notes.isEmpty {
                    withAnimation {
                        showNotes.toggle()
                    }
                }
            }
            
            // Notes section (expandable)
            if showNotes && !expense.notes.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Divider()
                        .background(Color.gray.opacity(0.3))
                    
                    HStack(alignment: .top) {
                        Image(systemName: "text.quote")
                            .foregroundColor(.gray)
                            .font(.caption)
                            .padding(.top, 2)
                        
                        Text(expense.notes)
                            .font(.callout)
                            .foregroundColor(.white)
                            .padding(.vertical, 8)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 8)
                .transition(.move(edge: .top).combined(with: .opacity))
                .background(Color.gray.opacity(0.05))
            }
        }
        .background(showNotes ? Color.gray.opacity(0.15) : Color.clear)
        .cornerRadius(10)
    }
}

#Preview {
    let expenses = [
        Expense(
            name: "Groceries",
            amount: 75.5,
            currency: .usd,
            category: .food,
            date: Date(),
            isEssential: true,
            notes: "Weekly shopping at Trader Joe's"
        ),
        Expense(
            name: "Netflix",
            amount: 15.99,
            currency: .usd,
            category: .subscriptions,
            date: Date(),
            notes: ""
        ),
        Expense(
            name: "Savings",
            amount: 200,
            currency: .eur,
            category: .savings,
            date: Date(),
            notes: "Monthly retirement contribution",
            reminder: Reminder(date: Date(), frequency: .monthly)
        )
    ]
    
    return VStack(spacing: 16) {
        ForEach(expenses) { expense in
            ExpenseRow(
                expense: expense,
                showValues: true,
                budgetCurrency: .usd,
                budgetColorHex: "A169F7"
            )
        }
        
        ExpenseRow(
            expense: expenses[0],
            showValues: false,
            budgetCurrency: .usd,
            budgetColorHex: "A169F7"
        )
    }
    .padding()
    .background(Color(hex: "383C51"))
    .preferredColorScheme(.dark)
}
