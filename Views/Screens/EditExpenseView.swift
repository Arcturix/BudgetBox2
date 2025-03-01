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
    @State private var showAdvancedSettings = true // Default to true for edit view
    @State private var interestRate: String
    @State private var expectedAnnualReturn: String

    // MARK: - UI Constants
    private let backgroundColor = Color(hex: "282C3E")
    private let cardBackground = Color(hex: "383C51")
    private let accentColor = Color(hex: "42A5F5") // Blue accent color to match AddExpenseView
    private let textColor = Color.white
    private let secondaryTextColor = Color.gray.opacity(0.7)
    private let cornerRadius: CGFloat = 16
    private let iconSize: CGFloat = 20

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
                        // Header Section
                        headerSection

                        // Fields Section
                        nameField
                        amountField
                        categoryAndDateRow

                        // Advanced Settings Section
                        advancedSettingsSection

                        // Save Button
                        updateButton
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
            .onChange(of: showReminder) { newValue in
                // When toggling reminder, immediately update the parent view
                if newValue {
                    // Create temporary expense with current reminder
                    let tempExpense = createUpdatedExpense()
                    viewModel.updateExpense(tempExpense, in: budgetId)

                    // Force immediate update in all possible ways
                    postNotifications()
                }
            }
        }
    }

    // MARK: - UI Components

    // Header Section
    private var headerSection: some View {
        Text("Edit Expense")
            .font(.title)
            .fontWeight(.bold)
            .foregroundColor(textColor)
            .padding(.bottom, 5)
    }

    // Name Field
    private var nameField: some View {
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
    }

    // Amount Field
    private var amountField: some View {
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
                        .fontWeight(.medium)

                    Spacer()

                    CurrencyPicker(selectedCurrency: $selectedCurrency, startMonth: .constant(1), startYear: .constant(startYear))
                        .foregroundColor(textColor)
                }
                .padding(.vertical, 8)
            }
        }
    }

    // Category and Date Row
    private var categoryAndDateRow: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                // Category Picker
                cardView {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Category")
                            .font(.subheadline)
                            .foregroundColor(secondaryTextColor)

                        Picker(
                            selection: $selectedCategory,
                            label: HStack {
                                // Category icon in blue circle
                                ZStack {
                                    Circle()
                                        .fill(accentColor)
                                        .frame(width: 32, height: 32)

                                    Image(systemName: selectedCategory.iconName)
                                        .font(.system(size: iconSize - 3))
                                        .foregroundColor(.white)
                                }

                                // Small spacer
                                Spacer()
                                    .frame(width: 10)

                                // Category text
                                Text(selectedCategory.rawValue)
                                    .foregroundColor(textColor)
                                    .font(.system(size: 18))

                                Spacer()

                                // Dropdown indicator
                                Image(systemName: "chevron.down")
                                    .font(.caption)
                                    .foregroundColor(secondaryTextColor)
                            }
                        ) {
                            ForEach(ExpenseCategory.allCases, id: \.self) { category in
                                HStack {
                                    ZStack {
                                        Circle()
                                            .fill(accentColor)
                                            .frame(width: 24, height: 24)

                                        Image(systemName: category.iconName)
                                            .font(.system(size: 12))
                                            .foregroundColor(.white)
                                    }

                                    Text(category.rawValue)
                                        .foregroundColor(textColor)
                                }
                                .tag(category)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .padding(.vertical, 8)
                    }
                }
                .frame(maxWidth: .infinity)

                // Date Picker
                cardView {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Date")
                            .font(.subheadline)
                            .foregroundColor(secondaryTextColor)

                        HStack {
                            Image(systemName: "calendar")
                                .font(.system(size: iconSize))
                                .foregroundColor(accentColor)
                                .frame(width: 30)

                            DatePicker("", selection: $expenseDate, displayedComponents: .date)
                                .datePickerStyle(CompactDatePickerStyle())
                                .labelsHidden()
                                .foregroundColor(textColor)
                        }
                        .padding(.vertical, 8)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    // Advanced Settings Section
    private var advancedSettingsSection: some View {
        cardView {
            VStack(alignment: .leading, spacing: 16) {
                // Advanced Settings Header (Clickable)
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

                // Advanced Settings Content (Expandable)
                if showAdvancedSettings {
                    Divider()
                        .background(secondaryTextColor)
                        .padding(.vertical, 8)

                    // Essential Toggle
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Essential Expense")
                                .foregroundColor(textColor)

                            Text("Tag expenses you can't live without")
                                .font(.caption)
                                .foregroundColor(secondaryTextColor)
                        }

                        Spacer()

                        Toggle("", isOn: $isEssential)
                            .toggleStyle(SwitchToggleStyle(tint: accentColor))
                            .labelsHidden()
                    }
                    .padding(.bottom, 12)

                    // Reminder Toggle & Settings
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Set Reminder")
                                    .foregroundColor(textColor)

                                Text("Get notified about this expense")
                                    .font(.caption)
                                    .foregroundColor(secondaryTextColor)
                            }

                            Spacer()

                            Toggle("", isOn: $showReminder)
                                .toggleStyle(SwitchToggleStyle(tint: accentColor))
                                .labelsHidden()
                        }

                        if showReminder {
                            Divider()
                                .background(secondaryTextColor)
                                .padding(.vertical, 8)

                            VStack(alignment: .leading, spacing: 15) {
                                HStack {
                                    Image(systemName: "bell.fill")
                                        .font(.system(size: iconSize))
                                        .foregroundColor(accentColor)
                                        .frame(width: 30)

                                    DatePicker("Reminder Date", selection: $reminderDate)
                                        .foregroundColor(textColor)
                                        .labelsHidden()
                                }

                                HStack {
                                    Text("Repeat")
                                        .foregroundColor(textColor)
                                    Spacer()
                                }

                                Picker("Frequency", selection: $reminderFrequency) {
                                    Text("Once").tag(Reminder.Frequency.once)
                                    Text("Daily").tag(Reminder.Frequency.daily)
                                    Text("Weekly").tag(Reminder.Frequency.weekly)
                                    Text("Monthly").tag(Reminder.Frequency.monthly)
                                    Text("Yearly").tag(Reminder.Frequency.yearly)
                                }
                                .pickerStyle(SegmentedPickerStyle())
                                .colorMultiply(accentColor)
                            }
                        }
                    }
                    .padding(.bottom, 12)

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
                    }

                    // Conditionally show additional fields for Savings category
                    if selectedCategory == .savings {
                        cardView {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Interest Rate")
                                    .font(.subheadline)
                                    .foregroundColor(secondaryTextColor)

                                TextField("Ex: 1.5%", text: $interestRate)
                                    .keyboardType(.decimalPad)
                                    .foregroundColor(textColor)
                                    .padding(.vertical, 8)
                                    .onChange(of: interestRate) { newValue in
                                        if !newValue.isEmpty {
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
                                    .onChange(of: expectedAnnualReturn) { newValue in
                                        if !newValue.isEmpty {
                                            interestRate = ""
                                        }
                                    }
                            }
                        }
                    }
                }
            }
        }
    }

    // Update Button
    private var updateButton: some View {
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

    // Card View Wrapper
    private func cardView<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack {
            content()
        }
        .padding()
        .background(cardBackground)
        .cornerRadius(cornerRadius)
    }

    // MARK: - Actions
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
            reminder: reminder,
            interestRate: interestRate.isEmpty ? nil : interestRate,
            expectedAnnualReturn: expectedAnnualReturn.isEmpty ? nil : expectedAnnualReturn
        )
    }

    private func postNotifications() {
        // Post a combination of notifications with different delays to ensure one works
        NotificationCenter.default.post(
            name: NSNotification.Name("RefreshBudgetDetail"),
            object: nil
        )

        NotificationCenter.default.post(
            name: NSNotification.Name("ExpenseEdited"),
            object: nil,
            userInfo: ["budgetId": budgetId]
        )

        // Also post a delayed notification to ensure it catches after view transitions
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            NotificationCenter.default.post(
                name: NSNotification.Name("RefreshBudgetDetail"),
                object: nil
            )
        }
    }

    private func saveExpense() {
        guard !name.isEmpty, let amountValue = Double(amount), amountValue > 0 else {
            return
        }

        let updatedExpense = createUpdatedExpense()

        // Debug print for troubleshooting
        print("Updating expense: \(updatedExpense.id) with new amount: \(amountValue) in budget: \(budgetId)")

        // Update in the view model
        viewModel.updateExpense(updatedExpense, in: budgetId)

        // Post all notifications to ensure something works
        postNotifications()

        // Post an additional notification after a brief delay (after dismiss)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            NotificationCenter.default.post(
                name: NSNotification.Name("RefreshBudgetDetail"),
                object: nil
            )
        }

        // Dismiss the view
        dismiss()
    }
}

// MARK: - Preview Provider
#if DEBUG
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
#endif
