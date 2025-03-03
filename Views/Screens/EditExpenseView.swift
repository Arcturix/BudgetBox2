import SwiftUI

struct EditExpenseView: View {
    // MARK: - Environment Properties
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var viewModel: BudgetViewModel
    
    // MARK: - Data Properties
    let budgetId: UUID
    let expense: Expense
    let startYear: Int
    
    // MARK: - State Properties
    @State private var name: String
    @State private var amount: String
    @State private var selectedCurrency: Currency
    @State private var selectedCategory: ExpenseCategory
    @State private var isEssential: Bool
    @State private var notes: String
    @State private var expenseDate: Date
    @State private var showReminder: Bool
    @State private var reminderDate: Date
    @State private var reminderFrequency: Reminder.Frequency
    @State private var interestRate: String
    @State private var expectedAnnualReturn: String
    @State private var currentBalance: Double
    
    // MARK: - UI Constants
    private let backgroundColor = Color(hex: "282C3E")
    private let cardBackground = Color(hex: "383C51")
    private let accentColor = Color(hex: "42A5F5")
    private let textColor = Color.white
    private let secondaryTextColor = Color.gray.opacity(0.7)
    private let cornerRadius: CGFloat = 16
    
    // MARK: - Initialization
    init(budgetId: UUID, expense: Expense, startYear: Int) {
        self.budgetId = budgetId
        self.expense = expense
        self.startYear = startYear
        
        // Initialize state with expense values
        _name = State(initialValue: expense.name)
        _amount = State(initialValue: String(format: "%.2f", expense.amount))
        _selectedCurrency = State(initialValue: expense.currency)
        _selectedCategory = State(initialValue: expense.category)
        _isEssential = State(initialValue: expense.isEssential)
        _notes = State(initialValue: expense.notes)
        _expenseDate = State(initialValue: expense.date)
        _showReminder = State(initialValue: expense.reminder != nil)
        _reminderDate = State(initialValue: expense.reminder?.date ?? Date())
        _reminderFrequency = State(initialValue: expense.reminder?.frequency ?? .once)
        _interestRate = State(initialValue: expense.interestRate ?? "")
        _expectedAnnualReturn = State(initialValue: expense.expectedAnnualReturn ?? "")
        _currentBalance = State(initialValue: expense.currentBalance ?? 0.0)
    }
    
    // MARK: - Main View
    var body: some View {
        NavigationView {
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
                                    
                                    // Simple currency picker
                                    Picker("Currency", selection: $selectedCurrency) {
                                        ForEach(Currency.allCases, id: \.self) { currency in
                                            Text(currency.symbol + " " + currency.rawValue).tag(currency)
                                        }
                                    }
                                    .pickerStyle(MenuPickerStyle())
                                    .foregroundColor(textColor)
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
                                    
                                    Picker("Category", selection: $selectedCategory) {
                                        ForEach(ExpenseCategory.allCases, id: \.self) { category in
                                            HStack {
                                                Image(systemName: category.iconName)
                                                Text(category.rawValue)
                                            }
                                            .tag(category)
                                        }
                                    }
                                    .pickerStyle(MenuPickerStyle())
                                    .foregroundColor(textColor)
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
                                    }
                                }
                                
                                cardView {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Annual Return")
                                            .font(.subheadline)
                                            .foregroundColor(secondaryTextColor)
                                        
                                        TextField("Ex: 5%", text: $expectedAnnualReturn)
                                            .keyboardType(.decimalPad)
                                            .foregroundColor(textColor)
                                            .padding(.vertical, 8)
                                    }
                                }
                            }
                            
                            cardView {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Current Balance")
                                        .font(.subheadline)
                                        .foregroundColor(secondaryTextColor)
                                    
                                    TextField("", value: $currentBalance, format: .number)
                                        .keyboardType(.decimalPad)
                                        .foregroundColor(textColor)
                                        .padding(.vertical, 8)
                                }
                            }
                        }
                        
                        // Essential toggle
                        cardView {
                            Toggle("Essential Expense", isOn: $isEssential)
                                .foregroundColor(textColor)
                        }
                        
                        // Reminder toggle and settings
                        cardView {
                            VStack(alignment: .leading, spacing: 12) {
                                Toggle("Set Reminder", isOn: $showReminder)
                                    .foregroundColor(textColor)
                                
                                if showReminder {
                                    DatePicker("Reminder Date", selection: $reminderDate)
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
                        }
                        
                        // Notes
                        cardView {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Notes (Optional)")
                                    .font(.subheadline)
                                    .foregroundColor(secondaryTextColor)
                                
                                TextEditor(text: $notes)
                                    .frame(minHeight: 100)
                                    .foregroundColor(textColor)
                                    .background(Color.clear)
                            }
                        }
                        
                        // Save Button
                        Button(action: saveExpense) {
                            Text("Update Expense")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(accentColor)
                                .cornerRadius(cornerRadius)
                        }
                        .padding(.top)
                    }
                    .padding()
                }
            }
            .navigationTitle("Edit Expense")
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
    
    // MARK: - Helper Views
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
        
        // Create updated expense
        let updatedExpense = Expense(
            id: expense.id,  // Keep the original ID
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
            currentBalance: selectedCategory == .savings ? currentBalance : nil
        )
        
        // Update expense in view model
        viewModel.updateExpense(updatedExpense, in: budgetId)
        
        // Dismiss the view - this will trigger the onDismiss callback in BudgetDetailView
        dismiss()
    }
}

struct EditExpenseView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleExpense = Expense(
            name: "Rent",
            amount: 500,
            currency: .gbp,
            category: .housing,
            isEssential: true
        )
        
        return EditExpenseView(budgetId: UUID(), expense: sampleExpense, startYear: 2023)
            .environmentObject(BudgetViewModel())
            .preferredColorScheme(.dark)
    }
}
