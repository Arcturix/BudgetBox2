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
                                
                                CurrencyPicker(selectedCurrency: $selectedCurrency)
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
                        
                        // Icon picker
                        VStack(alignment: .leading) {
                            Text("Icon")
                                .foregroundColor(.white)
                            
                            IconPicker(selectedIcon: $selectedIcon)
                        }
                        
                        // Color picker
                        VStack(alignment: .leading) {
                            Text("Color")
                                .foregroundColor(.white)
                            
                            ColorPickerView(selectedColor: $selectedColor)
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
            isMonthly: isMonthly
        )
        
        viewModel.addBudget(newBudget)
        dismiss()
    }
}
