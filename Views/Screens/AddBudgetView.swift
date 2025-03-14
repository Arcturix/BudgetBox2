import SwiftUI

struct AddBudgetView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var viewModel: BudgetViewModel

    @State private var name = ""
    @State private var amount = ""
    @State private var selectedCurrency = Currency.usd
    @State private var selectedIcon = "house.fill"
    @State private var selectedColor = "FF5252"
    @State private var isMonthly = true
    @State private var selectedMonth = Calendar.current.component(.month, from: Date())
    @State private var selectedYear = Calendar.current.component(.year, from: Date())

    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "383C51")
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Name field
                        VStack(alignment: .leading) {
                            Text("Budget Name")
                                .foregroundColor(.white)

                            TextField("Ex: UK Budget", text: $name)
                                .padding()
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(10)
                                .foregroundColor(.white)
                        }

                        // Amount and Currency fields
                        HStack(spacing: 10) {
                            // Amount field
                            VStack(alignment: .leading) {
                                Text("Amount")
                                    .foregroundColor(.white)
                                
                                TextField("0.00", text: $amount)
                                    .keyboardType(.decimalPad)
                                    .padding()
                                    .background(Color.gray.opacity(0.2))
                                    .cornerRadius(10)
                                    .foregroundColor(.white)
                            }
                            .frame(minWidth: 0, maxWidth: .infinity)
                            
                            // Currency field
                            VStack(alignment: .leading) {
                                Text("Currency")
                                    .foregroundColor(.white)
                                
                                CurrencyPicker(selectedCurrency: $selectedCurrency, startMonth: $selectedMonth, startYear: $selectedYear)
                                    .padding()
                                    .background(Color.gray.opacity(0.2))
                                    .cornerRadius(10)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                            }
                            .frame(minWidth: 0, maxWidth: .infinity)
                        }



                        // Budget type
                        VStack(alignment: .leading) {
                            Text("Budget Type")
                                .foregroundColor(.white)

                            Picker("Budget Type", selection: $isMonthly) {
                                Text("Monthly").tag(true)
                                Text("One-time").tag(false)
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .padding(.vertical, 8)
                        }

                        // Start month and year picker
                        HStack(spacing: 10) {
                            // Start Month
                            VStack(alignment: .leading) {
                                Text("Start Month")
                                    .foregroundColor(.white)
                                
                                Picker("Start Month", selection: $selectedMonth) {
                                    ForEach(1..<13) { month in
                                        Text(DateFormatter().monthSymbols[month - 1]).tag(month)
                                    }
                                }
                                .pickerStyle(MenuPickerStyle())
                                .padding()
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(10)
                                .frame(maxWidth: .infinity)
                            }
                            .frame(minWidth: 0, maxWidth: .infinity)
                            
                            // Start Year
                            VStack(alignment: .leading) {
                                Text("Start Year")
                                    .foregroundColor(.white)
                                
                                Picker("Start Year", selection: $selectedYear) {
                                    ForEach(2000...Calendar.current.component(.year, from: Date()) + 10, id: \.self) { year in
                                        Text(String(format: "%d", year)).tag(year)
                                    }
                                }
                                .pickerStyle(MenuPickerStyle())
                                .padding()
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(10)
                                .frame(maxWidth: .infinity)
                            }
                            .frame(minWidth: 0, maxWidth: .infinity)
                        }
                        .frame(maxWidth: .infinity)


                        // Icon picker
                        VStack(alignment: .leading) {
                            Text("Icon")
                                .foregroundColor(.white)

                            IconPicker(selectedIcon: $selectedIcon, startMonth: $selectedMonth, startYear: $selectedYear)
                        }

                        // Color picker
                        VStack(alignment: .leading) {
                            Text("Color")
                                .foregroundColor(.white)

                            ColorPickerView(selectedColor: $selectedColor, startMonth: $selectedMonth, startYear: $selectedYear)
                        }

                        // Save button
                        Button(action: saveBudget) {
                            Text("Save Budget")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color(hex: "FF5E7D"), Color(hex: "A169F7")]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(10)
                        }
                        .padding(.top)
                    }
                    .padding()
                }
            }
            .navigationTitle("Add Budget")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }

    private func saveBudget() {
        guard !name.isEmpty, let amountValue = Double(amount), amountValue > 0 else {
            return
        }

        let newBudget = Budget(
            name: name,
            amount: amountValue,
            currency: selectedCurrency,
            iconName: selectedIcon,
            colorHex: selectedColor,
            isMonthly: isMonthly,
            startMonth: selectedMonth,
            startYear: selectedYear
        )

        viewModel.addBudget(newBudget)
        dismiss()
    }
}

#if DEBUG
struct AddBudgetView_Previews: PreviewProvider {
    static var previews: some View {
        AddBudgetView()
            .environmentObject(BudgetViewModel())
    }
}
#endif
