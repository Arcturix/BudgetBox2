import SwiftUI

struct ExpenseRow: View {
    let expense: Expense
    let showValues: Bool
    let budgetCurrency: Currency
    @State private var showNotes = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Main row content
            HStack {
                Image(systemName: expense.category.iconName)
                    .foregroundColor(expense.category == .savings ? .yellow :
                                     (expense.isEssential ? .blue : .gray))
                    .font(.title3)
                    .frame(width: 40, height: 40)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                
                VStack(alignment: .leading) {
                    HStack {
                        Text(expense.name)
                            .font(.headline)
                        
                        // Notes icon - shows if the expense has notes
                        if !expense.notes.isEmpty {
                            Image(systemName: "note.text")
                                .foregroundColor(.gray)
                                .font(.caption)
                        }
                    }
                    
                    Text(expense.category.rawValue)
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    if expense.isEssential {
                        Text("Essential")
                            .font(.caption)
                            .foregroundColor(.blue)
                                       }
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    if showValues {
                        Text("-\(expense.amount.formatted(.currency(code: expense.currency.rawValue)))")
                            .foregroundColor(.red)
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
                            .foregroundColor(.red)
                            .font(.headline)
                    }
                    
                    HStack {
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
            .padding(.vertical, 8)
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
                            .padding(.vertical, 4)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.bottom, 8)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .background(showNotes ? Color.gray.opacity(0.15) : Color.clear)
        .cornerRadius(10)
    }
}
