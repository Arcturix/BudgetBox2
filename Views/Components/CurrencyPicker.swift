import SwiftUI

struct CurrencyPicker: View {
    @Binding var selectedCurrency: Currency
    @Binding var startMonth: Int
    @Binding var startYear: Int
    
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
}
