import SwiftUI

struct AddExpenseView: View {
    // MARK: - Environment Properties
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var viewModel: BudgetViewModel
    
    // MARK: - Data Properties
    let budgetId: UUID
    let startYear: Int
    let budgetCurrency: Currency
    
    init(budgetId: UUID, startYear: Int) {
        self.budgetId = budgetId
        self.startYear = startYear
        self.budgetCurrency = Currency.usd
        self._selectedCurrency = State(initialValue: Currency.usd)
    }
    
    init(budgetId: UUID, startYear: Int, budgetCurrency: Currency) {
        self.budgetId = budgetId
        self.startYear = startYear
        self.budgetCurrency = budgetCurrency
        self._selectedCurrency = State(initialValue: budgetCurrency)
    }
    
    // MARK: - State Properties
    @State private var name = ""
    @State private var amount = ""
    @State private var selectedCurrency: Currency
    @State private var selectedCategory = ExpenseCategory.other
    @State private var isEssential = false
    @State private var notes = ""
    @State private var expenseDate = Date()
    @State private var showReminder = false
    @State private var reminderDate = Date()
    @State private var reminderFrequency = Reminder.Frequency.once
    @State private var showAdvancedSettings = false
    @State private var interestRate: String = ""
    @State private var expectedAnnualReturn: String = ""
    @State private var currentSavingsBalance: Double = 0.0
    
    // MARK: - UI Constants
    private let backgroundColor = Color(hex: "282C3E")
    private let cardBackground = Color(hex: "383C51")
    private let accentColor = Color(hex: "42A5F5")
    private let textColor = Color.white
    private let secondaryTextColor = Color.gray.opacity(0.7)
    private let cornerRadius: CGFloat = 16
    
    // MARK: - Main View
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                backgroundColor.ignoresSafeArea()
                
                // Content
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Name Field
                        cardView {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Expense Name")
                                    .font(.subheadline)
                                    .foregroundColor(secondaryTextColor)
                                
                                TextField("Ex: Rent", text: $name)
                                    .foregroundColor(textColor)
                                    .padding(.vertical, 8)
                            }
                        }
                        
                        // Amount Field
                        cardView {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Amount")
                                    .font(.subheadline)
                                    .foregroundColor(secondaryTextColor)
                                
                                HStack {
                                    TextField("0.00", text: $amount)
                                        .keyboardType(.decimalPad)
                                        .foregroundColor(textColor)
                                        .font(.title3)
                                    
                                    Spacer()
                                    
                                    // Currency picker
                                    Menu {
                                        ForEach(Currency.allCases, id: \.self) { currency in
                                            Button(action: { selectedCurrency = currency }) {
                                                HStack {
                                                    Text("\(currency.symbol) \(currency.rawValue)")
                                                    if currency == selectedCurrency {
                                                        Image(systemName: "checkmark")
                                                    }
                                                }
                                            }
                                        }
                                    } label: {
                                        Text("\(selectedCurrency.symbol) \(selectedCurrency.rawValue)")
                                            .foregroundColor(textColor)
                                            .padding(.horizontal, 8)
                                    }
                                }
                                .padding(.vertical, 8)
                            }
                        }
                        
                        // Category and Date
                        HStack(spacing: 12) {
                            // Category
                            cardView {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Category")
                                        .font(.subheadline)
                                        .foregroundColor(secondaryTextColor)
                                    
                                    Menu {
                                        ForEach(ExpenseCategory.allCases, id: \.self) { category in
                                            Button(action: { selectedCategory = category }) {
                                                HStack {
                                                    Image(systemName: category.iconName)
                                                        .foregroundColor(Color(hex: category.colorHex))
                                                    Text(category.rawValue)
                                                    if category == selectedCategory {
                                                        Image(systemName: "checkmark")
                                                    }
                                                }
                                            }
                                        }
                                    } label: {
                                        HStack {
                                            Image(systemName: selectedCategory.iconName)
                                                .foregroundColor(Color(hex: selectedCategory.colorHex))
                                            Text(selectedCategory.rawValue)
                                                .foregroundColor(textColor)
                                            Spacer()
                                            Image(systemName: "chevron.down")
                                                .font(.caption)
                                                .foregroundColor(secondaryTextColor)
                                        }
                                        .padding(.vertical, 8)
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity)
                            
                            // Date
                            cardView {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Date")
                                        .font(.subheadline)
                                        .foregroundColor(secondaryTextColor)
                                    
                                    DatePicker("", selection: $expenseDate, displayedComponents: .date)
                                        .datePickerStyle(CompactDatePickerStyle())
                                        .labelsHidden()
                                        .foregroundColor(textColor)
                                }
                            }
                            .frame(maxWidth: .infinity)
                        }
                        
                        // Savings fields (if category is savings)
                        if selectedCategory == .savings {
                            savingsFields
                        }
                        
                        // Advanced Settings Section
                        advancedSettingsSection
                        
                        // Save Button
                        Button(action: saveExpense) {
                            Text("Save Expense")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(accentColor)
                                .cornerRadius(cornerRadius)
                        }
                        .padding(.top)
                        .disabled(name.isEmpty || amount.isEmpty || Double(amount) == nil || Double(amount)! <= 0)
                    }
                    .padding()
                }
            }
            .navigationTitle("Add Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(textColor)
                }
            }
        }
    }
    
    // MARK: - UI Components
    
    private var savingsFields: some View {
        Group {
            HStack(spacing: 12) {
                cardView {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Interest Rate")
                            .font(.subheadline)
                            .foregroundColor(secondaryTextColor)
                        
                        TextField("Ex: 1.5%", text: $interestRate)
                            .keyboardType(.decimalPad)
                            .foregroundColor(textColor)
                            .padding(.vertical, 8)
                            .onChange(of: interestRate) {
                                if !interestRate.isEmpty {
                                    expectedAnnualReturn = ""
                                }
                            }
                    }
                }
                
                cardView {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Expected Annual Return")
                            .font(.subheadline)
                            .foregroundColor(secondaryTextColor)
                        
                        TextField("Ex: 5%", text: $expectedAnnualReturn)
                            .keyboardType(.decimalPad)
                            .foregroundColor(textColor)
                            .padding(.vertical, 8)
                            .onChange(of: expectedAnnualReturn) {
                                if !expectedAnnualReturn.isEmpty {
                                    interestRate = ""
                                }
                            }
                    }
                }
            }
            
            cardView {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Starting Balance")
                        .font(.subheadline)
                        .foregroundColor(secondaryTextColor)
                    
                    HStack {
                        TextField("Initial savings amount", value: $currentSavingsBalance, format: .number)
                            .keyboardType(.decimalPad)
                            .foregroundColor(textColor)
                            .padding(.vertical, 8)
                        
                        Spacer()
                        
                        // Add a small currency symbol
                        Text(selectedCurrency.symbol)
                            .foregroundColor(secondaryTextColor)
                            .padding(.trailing, 8)
                    }
                }
            }
        }
    }
    
    private var advancedSettingsSection: some View {
        cardView {
            VStack(alignment: .leading, spacing: 16) {
                // Advanced Settings Header
                Button(action: {
                    withAnimation {
                        showAdvancedSettings.toggle()
                    }
                }) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Advanced Settings")
                                .font(.headline)
                                .foregroundColor(textColor)
                            
                            Text("Additional expense options")
                                .font(.caption)
                                .foregroundColor(secondaryTextColor)
                        }
                        
                        Spacer()
                        
                        Image(systemName: showAdvancedSettings ? "chevron.up" : "chevron.down")
                            .foregroundColor(accentColor)
                            .font(.system(size: 16))
                    }
                }
                
                if showAdvancedSettings {
                    Divider()
                        .background(secondaryTextColor)
                        .padding(.vertical, 8)
                    
                    // Essential Toggle
                    Toggle(isOn: $isEssential) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Essential Expense")
                                .foregroundColor(textColor)
                            
                            Text("Tag expenses you can't live without")
                                .font(.caption)
                                .foregroundColor(secondaryTextColor)
                        }
                    }
                    .toggleStyle(SwitchToggleStyle(tint: accentColor))
                    
                    // Reminder Toggle & Settings
                    VStack(alignment: .leading, spacing: 12) {
                        Toggle(isOn: $showReminder) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Set Reminder")
                                    .foregroundColor(textColor)
                                
                                Text("Get notified about this expense")
                                    .font(.caption)
                                    .foregroundColor(secondaryTextColor)
                            }
                        }
                        .toggleStyle(SwitchToggleStyle(tint: accentColor))
                        
                        if showReminder {
                            Divider()
                                .background(secondaryTextColor)
                                .padding(.vertical, 8)
                            
                            DatePicker("Reminder Date", selection: $reminderDate)
                                .foregroundColor(textColor)
                            
                            Text("Repeat")
                                .foregroundColor(textColor)
                            
                            Picker("Frequency", selection: $reminderFrequency) {
                                Text("Once").tag(Reminder.Frequency.once)
                                Text("Daily").tag(Reminder.Frequency.daily)
                                Text("Weekly").tag(Reminder.Frequency.weekly)
                                Text("Monthly").tag(Reminder.Frequency.monthly)
                                Text("Yearly").tag(Reminder.Frequency.yearly)
                            }
                            .pickerStyle(SegmentedPickerStyle())
                        }
                    }
                    
                    // Notes Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Notes (Optional)")
                            .font(.subheadline)
                            .foregroundColor(secondaryTextColor)
                        
                        TextEditor(text: $notes)
                            .frame(minHeight: 100)
                            .padding(4)
                            .foregroundColor(textColor)
                            .background(Color.clear)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(secondaryTextColor.opacity(0.3), lineWidth: 1)
                            )
                    }
                }
            }
        }
    }
    
    // Card View Wrapper
    @ViewBuilder
    private func cardView<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack {
            content()
        }
        .padding()
        .background(cardBackground)
        .cornerRadius(cornerRadius)
    }
    
    // MARK: - Actions
    private func saveExpense() {
        guard !name.isEmpty, let amountValue = Double(amount), amountValue > 0 else {
            return
        }
        
        var reminder: Reminder?
        if showReminder {
            reminder = Reminder(date: reminderDate, frequency: reminderFrequency)
        }
        
        // Create a new expense
        let newExpense = Expense(
            name: name,
            amount: amountValue,
            currency: selectedCurrency,
            category: selectedCategory,
            date: expenseDate,
            isEssential: isEssential,
            notes: notes,
            reminder: reminder,
            interestRate: selectedCategory == .savings ? interestRate : nil,
            expectedAnnualReturn: selectedCategory == .savings ? expectedAnnualReturn : nil,
            startingBalance: selectedCategory == .savings ? currentSavingsBalance : nil
        )
        
        // Add expense to the viewModel
        viewModel.addExpense(newExpense, to: budgetId)
        
        // Dismiss the view
        dismiss()
    }
}

#Preview {
    AddExpenseView(budgetId: UUID(), startYear: 2023, budgetCurrency: .eur)
        .environmentObject(BudgetViewModel())
        .preferredColorScheme(.dark)
}
