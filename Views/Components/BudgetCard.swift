import SwiftUI

struct BudgetCard: View {
    let budget: Budget
    let showValues: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Image(systemName: budget.iconName)
                    .foregroundColor(Color(hex: budget.colorHex))
                    .font(.title2)
                
                VStack(alignment: .leading) {
                    Text(budget.name)
                        .font(.headline)
                    Text("Monthly Budget")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                if showValues {
                    Text("\(budget.amount.formatted(.currency(code: budget.currency.rawValue)))")
                        .font(.title3)
                        .bold()
                } else {
                    Text("****")
                        .font(.title3)
                        .bold()
                }
            }
            
            // Progress bar
            ZStack(alignment: .leading) {
                Rectangle()
                    .foregroundColor(Color.gray.opacity(0.3))
                    .frame(height: 10)
                    .cornerRadius(5)
                
                Rectangle()
                    .foregroundColor(Color(hex: budget.colorHex))
                    .frame(width: max(0, CGFloat(budget.percentRemaining) / 100 * UIScreen.main.bounds.width * 0.8), height: 10)
                    .cornerRadius(5)
            }
            
            HStack {
                Text("Remaining")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Spacer()
                
                if showValues {
                    Text("\(budget.remainingAmount.formatted(.currency(code: budget.currency.rawValue)))")
                        .foregroundColor(budget.remainingAmount > 0 ? .green : .red)
                        .font(.headline)
                } else {
                    Text("****")
                        .foregroundColor(.green)
                        .font(.headline)
                }
                
                Text("\(budget.percentRemaining)%")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(15)
    }
}
