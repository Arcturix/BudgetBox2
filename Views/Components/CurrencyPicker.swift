import SwiftUI

struct CurrencyPicker: View {
    @Binding var selectedCurrency: Currency
    
    var body: some View {
        Picker("Currency", selection: $selectedCurrency) {
            ForEach(Currency.allCases, id: \.self) { currency in
                HStack {
                    Text(currency.symbol)
                    Text(currency.rawValue)
                }
                .tag(currency)
            }
        }
        .pickerStyle(MenuPickerStyle())
    }
    
    struct BudgetCard_Previews: PreviewProvider {
        static var previews: some View {
            ZStack {
                Color(hex: "383C51")
                    .ignoresSafeArea()
                
                BudgetCard(
                    budget: Budget(
                        name: "Sample Budget",
                        amount: 950.00,
                        currency: .gbp,
                        iconName: "house.fill",
                        colorHex: "FF5252",
                        expenses: [
                            Expense(name: "Rent", amount: 500, currency: .gbp, category: .housing)
                        ]
                    ),
                    showValues: true
                )
                .padding()
            }
            .preferredColorScheme(.dark)
        }
    }
}
