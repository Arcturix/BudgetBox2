import SwiftUI

struct EditExpenseView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var viewModel: BudgetViewModel
    
    let budgetId: UUID
    let expense: Expense
    
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
    
    init(budgetId: UUID, expense: Expense) {
        self.budgetId = budgetId
        self.expense = expense
        
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
                            Text("Expense Name")
                                .foregroundColor(.white)
                            
                            TextField("Ex: Rent", text: $name)
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
                        
                        // Category picker
                        VStack(alignment: .leading) {
                            Text("Category")
                                .foregroundColor(.white)
                            
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
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(10)
                            .foregroundColor(.white)
                        }
                        
                        // Date picker
                        VStack(alignment: .leading) {
                            Text("Date")
                                .foregroundColor(.white)
                            
                            DatePicker("", selection: $expenseDate, displayedComponents: .date)
                                .datePickerStyle(CompactDatePickerStyle())
                                .labelsHidden()
                                .padding()
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(10)
                                .foregroundColor(.white)
                                .accentColor(.white)
                        }
                        
                        // Essential toggle
                        Toggle(isOn: $isEssential) {
                            Text("Mark as Essential")
                                .foregroundColor(.white)
                        }
                        .toggleStyle(SwitchToggleStyle(tint: Color(hex: "A169F7")))
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(10)
                        
                        // Reminder
                        VStack(alignment: .leading) {
                            Toggle(isOn: $showReminder) {
                                Text("Set Reminder")
                                    .foregroundColor(.white)
                            }
                            .toggleStyle(SwitchToggleStyle(tint: Color(hex: "A169F7")))
                            
                            if showReminder {
                                VStack(alignment: .leading, spacing: 15) {
                                    DatePicker("Reminder Date", selection: $reminderDate)
                                        .foregroundColor(.white)
                                        .accentColor(.white)
                                    
                                    Picker("Frequency", selection: $reminderFrequency) {
                                        Text("Once").tag(Reminder.Frequency.once)
                                        Text("Daily").tag(Reminder.Frequency.daily)
                                        Text("Weekly").tag(Reminder.Frequency.weekly)
                                        Text("Monthly").tag(Reminder.Frequency.monthly)
                                        Text("Yearly").tag(Reminder.Frequency.yearly)
                                    }
                                    .pickerStyle(SegmentedPickerStyle())
                                }
                                .padding(.top)
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(10)
                        
                        // Notes
                        VStack(alignment: .leading) {
                            Text("Notes (Optional)")
                                .foregroundColor(.white)
                            
                            TextEditor(text: $notes)
                                .frame(minHeight: 100)
                                .padding(4)
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(10)
                                .foregroundColor(.white)
                        }
                        
                        // Save button
                        Button(action: saveExpense) {
                            Text("Update Expense")
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
            .navigationTitle("Edit Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
            .onChange(of: showReminder) { oldValue, newValue in
                // When toggling reminder, immediately update the parent view
                if newValue {
                    // Create temporary expense with current reminder
                    let tempExpense = createUpdatedExpense()
                    viewModel.updateExpense(tempExpense, in: budgetId)
                    
                    // Post notification to refresh BudgetDetailView
                    NotificationCenter.default.post(name: NSNotification.Name("RefreshBudgetDetail"), object: nil)
                }
            }
        }
    }
    
    private func createUpdatedExpense() -> Expense {
        var reminder: Reminder?
        if showReminder {
            reminder = Reminder(date: reminderDate, frequency: reminderFrequency)
        }
        
        // Create new expense with current values
        return Expense(
            id: expense.id,  // Keep the original ID
            name: name,
            amount: Double(amount) ?? expense.amount,
            currency: selectedCurrency,
            category: selectedCategory,
            date: expenseDate,
            isEssential: isEssential,
            notes: notes,
            reminder: reminder
        )
    }
    
    private func saveExpense() {
        guard !name.isEmpty, let amountValue = Double(amount), amountValue > 0 else {
            return
        }
        
        let updatedExpense = createUpdatedExpense()
        viewModel.updateExpense(updatedExpense, in: budgetId)
        
        // Post notification to refresh BudgetDetailView
        NotificationCenter.default.post(name: NSNotification.Name("RefreshBudgetDetail"), object: nil)
        
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
        
        return EditExpenseView(budgetId: UUID(), expense: sampleExpense)
            .environmentObject(BudgetViewModel())
            .preferredColorScheme(.dark)
    }
}
