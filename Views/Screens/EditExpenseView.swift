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
    @State private var isFlagged: Bool
    @State private var notes: String
    @State private var expenseDate: Date
    @State private var showReminder: Bool
    @State private var reminderDate: Date
    @State private var reminderFrequency: Reminder.Frequency
    @State private var interestRate: String
    @State private var expectedAnnualReturn: String
    @State private var currentBalance: Double
    @State private var isStudentLoanPayment: Bool
    @State private var showStudentLoanAlert = false
    @State private var existingStudentLoanPayment: (budgetId: UUID, expense: Expense)? = nil
    
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
        _isFlagged = State(initialValue: expense.isFlagged)
        _notes = State(initialValue: expense.notes)
        _expenseDate = State(initialValue: expense.date)
        _showReminder = State(initialValue: expense.reminder != nil)
        _reminderDate = State(initialValue: expense.reminder?.date ?? Date())
        _reminderFrequency = State(initialValue: expense.reminder?.frequency ?? .once)
        _interestRate = State(initialValue: expense.interestRate ?? "")
        _expectedAnnualReturn = State(initialValue: expense.expectedAnnualReturn ?? "")
        _currentBalance = State(initialValue: expense.startingBalance ?? 0.0)
        _isStudentLoanPayment = State(initialValue: expense.isStudentLoanPayment)
    }
    
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
                                            Button(action: {
                                                selectedCategory = category
                                                // If changing away from debt, reset student loan payment flag
                                                if category != .debt {
                                                    isStudentLoanPayment = false
                                                }
                                                // If changing to debt, check for existing student loan payment
                                                if category == .debt && !isStudentLoanPayment {
                                                    let existing = viewModel.findExistingStudentLoanPayment()
                                                    if let existing = existing, existing.expense.id != expense.id {
                                                        existingStudentLoanPayment = existing
                                                    }
                                                }
                                                // If changing away from savings, clear savings fields
                                                if category != .savings {
                                                    interestRate = ""
                                                    expectedAnnualReturn = ""
                                                    currentBalance = 0
                                                }
                                            }) {
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
                        
                        // Student Loan Payment Option (only shown for Debt category)
                        if selectedCategory == .debt {
                            cardView {
                                Toggle(isOn: $isStudentLoanPayment) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Student Loan Payment")
                                            .foregroundColor(textColor)
                                        
                                        Text("Attribute this payment to your student loan")
                                            .font(.caption)
                                            .foregroundColor(secondaryTextColor)
                                    }
                                }
                                .toggleStyle(SwitchToggleStyle(tint: Color(hex: "F44336")))
                                .onChange(of: isStudentLoanPayment) { newValue in
                                    if newValue && existingStudentLoanPayment != nil {
                                        showStudentLoanAlert = true
                                    }
                                }
                                .alert("Another payment is already attributed", isPresented: $showStudentLoanAlert) {
                                    Button("Cancel", role: .cancel) {
                                        isStudentLoanPayment = false
                                    }
                                    Button("Replace", role: .destructive) {
                                        // Keep isStudentLoanPayment as true
                                    }
                                } message: {
                                    Text("Only one expense can be attributed to your student loan at a time. Do you want to replace the existing attribution?")
                                }
                            }
                        }
                        
                        // Savings fields (if category is savings)
                        if selectedCategory == .savings {
                            savingsFields
                        }
                        
                        // Essential toggle
                        cardView {
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
                        }
                        
                        // Flag toggle
                        cardView {
                            Toggle(isOn: $isFlagged) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Flag Expense")
                                        .foregroundColor(textColor)
                                    
                                    Text("Flag this expense for any reason")
                                        .font(.caption)
                                        .foregroundColor(secondaryTextColor)
                                }
                            }
                            .toggleStyle(SwitchToggleStyle(tint: accentColor))
                        }
                        
                        // Reminder toggle and settings
                        cardView {
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
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(secondaryTextColor.opacity(0.3), lineWidth: 1)
                                    )
                            }
                        }
                        
                        // Update Button
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
                        .disabled(name.isEmpty || amount.isEmpty || Double(amount) == nil || Double(amount)! <= 0)
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
            .onAppear {
                // Check for existing student loan payment when view appears
                let existing = viewModel.findExistingStudentLoanPayment()
                if let existing = existing, existing.expense.id != expense.id {
                    existingStudentLoanPayment = existing
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
                                                    TextField("Initial savings amount", value: $currentBalance, format: .number)
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
                                    
                                    // Create updated expense
                                    let updatedExpense = Expense(
                                        id: expense.id,  // Keep the original ID
                                        name: name,
                                        amount: amountValue,
                                        currency: selectedCurrency,
                                        category: selectedCategory,
                                        date: expenseDate,
                                        isEssential: isEssential,
                                        isFlagged: isFlagged,
                                        notes: notes,
                                        reminder: reminder,
                                        interestRate: selectedCategory == .savings ? interestRate : nil,
                                        expectedAnnualReturn: selectedCategory == .savings ? expectedAnnualReturn : nil,
                                        startingBalance: selectedCategory == .savings ? currentBalance : nil,
                                        isStudentLoanPayment: selectedCategory == .debt && isStudentLoanPayment
                                    )
                                    
                                    // Update expense in view model
                                    viewModel.updateExpense(updatedExpense, in: budgetId)
                                    
                                    // Dismiss the view
                                    dismiss()
                                }
                            }

                            #Preview {
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
