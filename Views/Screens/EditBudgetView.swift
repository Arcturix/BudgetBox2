import SwiftUI

struct EditBudgetView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var viewModel: BudgetViewModel
    
    @State var budget: Budget
    @State private var name: String
    @State private var amount: String
    @State private var selectedCurrency: Currency
    @State private var selectedIcon: String
    @State private var selectedColor: String
    @State private var isMonthly: Bool
    @State private var selectedMonth: Int
    @State private var selectedYear: Int
    @State private var isActive: Bool
    
    init(budget: Budget) {
        self._budget = State(initialValue: budget)
        self._name = State(initialValue: budget.name)
        self._amount = State(initialValue: String(budget.amount))
        self._selectedCurrency = State(initialValue: budget.currency)
        self._selectedIcon = State(initialValue: budget.iconName)
        self._selectedColor = State(initialValue: budget.colorHex)
        self._isMonthly = State(initialValue: budget.isMonthly)
        self._selectedMonth = State(initialValue: budget.startMonth)
        self._selectedYear = State(initialValue: budget.startYear)
        self._isActive = State(initialValue: budget.isActive)
    }
    
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
                        
                        // Amount field
                        VStack(alignment: .leading) {
                            Text("Amount")
                                .foregroundColor(.white)
                            
                            HStack {
                                TextField("0.00", text: $amount)
                                    .keyboardType(.decimalPad)
                                    .padding()
                                    .background(Color.gray.opacity(0.2))
                                    .cornerRadius(10)
                                    .foregroundColor(.white)
                                
                                CurrencyPicker(selectedCurrency: $selectedCurrency, startMonth: $selectedMonth, startYear: $selectedYear)
                                    .foregroundColor(.white)
                            }
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
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Start Month")
                                    .foregroundColor(.white)
                                
                                Picker("Start Month", selection: $selectedMonth) {
                                    ForEach(1..<13) { month in
                                        Text(DateFormatter().monthSymbols[month - 1]).tag(month)
                                    }
                                }
                                .pickerStyle(MenuPickerStyle())
                                .padding(.vertical, 8)
                                .frame(maxWidth: .infinity)
                            }
                            
                            VStack(alignment: .leading) {
                                Text("Start Year")
                                    .foregroundColor(.white)
                                
                                Picker("Start Year", selection: $selectedYear) {
                                    ForEach(2000...Calendar.current.component(.year, from: Date()) + 10, id: \.self) { year in
                                        Text(String(format: "%d", year)).tag(year)
                                    }
                                }
                                .pickerStyle(MenuPickerStyle())
                                .padding(.vertical, 8)
                                .frame(maxWidth: .infinity)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        
                        // Active status toggle
                        VStack(alignment: .leading) {
                            Toggle(isOn: $isActive) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Active Budget")
                                        .foregroundColor(.white)
                                    
                                    Text("Inactive budgets are excluded from insights and calculations")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                            .toggleStyle(SwitchToggleStyle(tint: Color(hex: "A169F7")))
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(10)
                        }
                        
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
            .navigationTitle("Edit Budget")
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
        
        let updatedBudget = Budget(
            id: budget.id,
            name: name,
            amount: amountValue,
            currency: selectedCurrency,
            iconName: selectedIcon,
            colorHex: selectedColor,
            isMonthly: isMonthly,
            expenses: budget.expenses,
            startMonth: selectedMonth,
            startYear: selectedYear,
            isActive: isActive  // Save the active status
        )
        
        viewModel.updateBudget(updatedBudget)
        dismiss()
    }
}

#if DEBUG
struct EditBudgetView_Previews: PreviewProvider {
    static var previews: some View {
        // Create a sample budget for preview
        let sampleBudget = Budget(
            name: "Sample Budget",
            amount: 500.0,
            currency: .usd,
            iconName: "house.fill",
            colorHex: "FF5252",
            isMonthly: true,
            expenses: [],
            startMonth: 1,
            startYear: 2023,
            isActive: true
        )
        
        return EditBudgetView(budget: sampleBudget)
            .environmentObject(BudgetViewModel())
            .preferredColorScheme(.dark)
    }
}
#endif
