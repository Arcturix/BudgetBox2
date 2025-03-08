// In Views/Components/ExpenseRow.swift

import SwiftUI

struct ExpenseRow: View {
    // MARK: - Properties
    let expense: Expense
    let showValues: Bool
    let budgetCurrency: Currency
    let budgetColorHex: String
    
    // MARK: - State
    @State private var showNotes = false
    
    // MARK: - Computed Properties
    private var truncatedName: String {
        // Limit to 25 characters to ensure it fits on one line
        if expense.name.count > 25 {
            return String(expense.name.prefix(22)) + "..."
        }
        return expense.name
    }
    
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
                        Text(truncatedName)
                            .font(.headline)
                            .foregroundColor(.white)
                            .lineLimit(1)
                        
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
                                .background(Color(hex: budgetColorHex).opacity(0.2))
                                .foregroundColor(Color(hex: budgetColorHex))
                                .cornerRadius(4)
                        }
                    }
                    
                    // Category
                    Text(expense.category.rawValue)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                // Amount and date column
                VStack(alignment: .trailing, spacing: 4) {
                    // Amount
                    if showValues {
                        Text("-\(expense.amount.formatted(.currency(code: expense.currency.rawValue)))")
                            .foregroundColor(Color(hex: budgetColorHex))
                            .font(.headline)
                        
                        // Show conversion if currencies differ
                        if expense.currency != budgetCurrency {
                            Text("(\(expense.convertedAmount(to: budgetCurrency).formatted(.currency(code: budgetCurrency.rawValue))))")
                                .foregroundColor(.orange)
                                .font(.caption)
                        }
                    } else {
                        Text("-****")
                            .foregroundColor(Color(hex: budgetColorHex))
                            .font(.headline)
                    }
                    
                    // Date and notification row
                    HStack(spacing: 4) {
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
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.gray.opacity(0.3), lineWidth: 0.5)
        )
    }
}

#Preview {
    let expense = Expense(
        name: "Groceries",
        amount: 75.5,
        currency: .usd,
        category: .food,
        date: Date(),
        isEssential: true,
        notes: "Weekly shopping at Trader Joe's"
    )
    
    return ExpenseRow(
        expense: expense,
        showValues: true,
        budgetCurrency: .usd,
        budgetColorHex: "A169F7"
    )
    .padding()
    .background(Color(hex: "383C51"))
    .preferredColorScheme(.dark)
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
        ),
        Expense(
            name: "This is a very long expense name that should be truncated properly",
            amount: 50,
            currency: .usd,
            category: .shopping,
            date: Date(),
            notes: "This is an example of a very long expense name"
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
