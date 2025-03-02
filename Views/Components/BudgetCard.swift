import SwiftUI

struct BudgetCard: View {
    let budget: Budget
    let showValues: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: budget.iconName)
                    .foregroundColor(Color(hex: budget.colorHex))
                    .font(.title)
                
                VStack(alignment: .leading) {
                    Text(budget.name)
                        .font(.title2)
                    Text("Monthly Budget")
                        .font(.body)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                if showValues {
                    Text("\(budget.amount.formatted(.currency(code: budget.currency.rawValue)))")
                        .font(.title)
                        .bold()
                } else {
                    Text("****")
                        .font(.title)
                        .bold()
                }
            }
            
            // Progress bar
            ZStack(alignment: .leading) {
                Rectangle()
                    .foregroundColor(Color.gray.opacity(0.3))
                    .frame(height: 15)
                    .cornerRadius(7.5)
                
                Rectangle()
                    .foregroundColor(Color(hex: budget.colorHex))
                    .frame(width: max(0, CGFloat(budget.percentRemaining) / 100 * UIScreen.main.bounds.width * 0.8), height: 15)
                    .cornerRadius(7.5)
            }
            
            HStack {
                Text("Remaining")
                    .font(.body)
                    .foregroundColor(.gray)
                
                Spacer()
                
                if showValues {
                    Text("\(budget.remainingAmount.formatted(.currency(code: budget.currency.rawValue)))")
                        .foregroundColor(budget.remainingAmount > 0 ? .green : .red)
                        .font(.title2)
                } else {
                    Text("****")
                        .foregroundColor(.green)
                        .font(.title2)
                }
                
                Text("\(budget.percentRemaining)%")
                    .font(.body)
                    .foregroundColor(.gray)
            }
        }
        .padding(20)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(20)
    }
}
