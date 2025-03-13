// Views/Components/ExpenseRow.swift

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
        expense.name.count > 25 ? String(expense.name.prefix(22)) + "..." : expense.name
    }
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 0) {
            // Main row content
            HStack(spacing: 12) {
                // Category icon
                CategoryIconView(category: expense.category)
                
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
                            EssentialBadge(colorHex: budgetColorHex)
                        }
                    }
                    
                    // Category
                    Text(expense.category.rawValue)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                // Amount and date column
                AmountColumn(
                    expense: expense,
                    showValues: showValues,
                    budgetCurrency: budgetCurrency,
                    budgetColorHex: budgetColorHex
                )
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
                NotesSection(notes: expense.notes)
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

// MARK: - Subcomponents

struct CategoryIconView: View {
    let category: ExpenseCategory
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color(hex: category.colorHex).opacity(0.2))
                .frame(width: 40, height: 40)
            
            Image(systemName: category.iconName)
                .foregroundColor(Color(hex: category.colorHex))
                .font(.system(size: 16))
        }
    }
}

struct EssentialBadge: View {
    let colorHex: String
    
    var body: some View {
        Text("Essential")
            .font(.caption)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color(hex: colorHex).opacity(0.2))
            .foregroundColor(Color(hex: colorHex))
            .cornerRadius(4)
    }
}

struct AmountColumn: View {
    let expense: Expense
    let showValues: Bool
    let budgetCurrency: Currency
    let budgetColorHex: String
    
    var body: some View {
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
}

struct NotesSection: View {
    let notes: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Divider()
                .background(Color.gray.opacity(0.3))
            
            HStack(alignment: .top) {
                Image(systemName: "text.quote")
                    .foregroundColor(.gray)
                    .font(.caption)
                    .padding(.top, 2)
                
                Text(notes)
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
