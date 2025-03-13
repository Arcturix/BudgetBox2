// Views/Components/CurrencyPicker.swift

import SwiftUI

struct CurrencyPicker: View {
    @Binding var selectedCurrency: Currency
    // These properties are only used in certain contexts and could be optional
    @Binding var startMonth: Int
    @Binding var startYear: Int
    
    // Initialize with just currency when other params aren't needed
    init(selectedCurrency: Binding<Currency>) {
        self._selectedCurrency = selectedCurrency
        // Use dummy bindings for month/year that aren't used
        self._startMonth = .constant(1)
        self._startYear = .constant(Calendar.current.component(.year, from: Date()))
    }
    
    // Full initializer for when all properties are needed
    init(selectedCurrency: Binding<Currency>, startMonth: Binding<Int>, startYear: Binding<Int>) {
        self._selectedCurrency = selectedCurrency
        self._startMonth = startMonth
        self._startYear = startYear
    }
    
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
