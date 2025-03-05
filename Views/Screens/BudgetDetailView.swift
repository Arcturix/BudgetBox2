import SwiftUI

struct BudgetDetailView: View {
    @EnvironmentObject var viewModel: BudgetViewModel
    let budgetId: UUID
    
    // MARK: - State
    @State private var selectedTab = 0
    @State private var isShowingAddExpenseSheet = false
    @State private var isShowingEditBudgetView = false
    @State private var expenseToEdit: Expense?
    @State private var showTotalExpense = false // This shows the alternative view first
    @State private var refreshID = UUID() // Used for forcing view updates
    
    // MARK: - Configurable UI Constants for easy testing on different screen sizes
    private let horizontalMargin: CGFloat = 20 // Adjust this value to change horizontal margins
    private let cardSpacing: CGFloat = 16 // Space between cards
    private let cardCornerRadius: CGFloat = 20 // Corner radius for cards
    private let headerBottomPadding: CGFloat = 8 // Space below header section
    private let sectionSpacing: CGFloat = 24 // Space between major sections
    
    // MARK: - Computed Properties
    private var budget: Budget? {
        viewModel.budgets.first(where: { $0.id == budgetId })
    }
    
    private var sortedExpenses: [Expense] {
        budget?.expenses.sorted(by: { $0.date > $1.date }) ?? []
    }
    
    private var isAddButtonDisabled: Bool {
        guard let budget = budget else { return true }
        return viewModel.budgetItemLimitEnabled && budget.expenses.count >= 10
    }
    
    // MARK: - Body
    var body: some View {
        ZStack {
            // Background
            Color(hex: "020514")
                .ignoresSafeArea()
            
            if let budget = budget {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        // Header
                        VStack(alignment: .leading) {
                            Text("Budget Plan")
                                .foregroundColor(.gray)
                                .padding(.horizontal, horizontalMargin)

                            HStack {
                                Text(budget.name)
                                    .font(.largeTitle)
                                    .bold()
                                    .foregroundColor(.white)
                                    .padding(.horizontal, horizontalMargin)

                                Spacer()

                                // Move the circle inside the HStack's bounds
                                Circle()
                                    .fill(Color(hex: budget.colorHex))
                                    .frame(width: 50, height: 50)
                                    .overlay(
                                        Image(systemName: budget.iconName)
                                            .font(.title2)
                                            .foregroundColor(.white)
                                    )
                                    .padding(.trailing, horizontalMargin) // Use configurable margin
                            }
                            .padding(.bottom, headerBottomPadding)
                        }
                        
                        // Budget Summary Cards
                        HStack(spacing: 20) {
                            // Total Budget Card
                            summaryCard(
                                iconName: "arrow.down",
                                title: "Total Budget",
                                value: viewModel.showValuesEnabled ? budget.amount.formatted(.currency(code: budget.currency.rawValue)) : "****",
                                secondaryValue: nil,
                                gradient: [
                                    Color(hex: budget.colorHex),
                                    Color(hex: budget.colorHex).opacity(0.7)
                                ],
                                backgroundIcon: currencyIconName(for: budget.currency)
                            )

                            // Expenses/Remaining Card
                            summaryCard(
                                iconName: "arrow.up",
                                title: showTotalExpense ? "Total Expense" : "Remaining Budget",
                                value: viewModel.showValuesEnabled ?
                                    (showTotalExpense ?
                                        (budget.amount - budget.remainingAmount).formatted(.currency(code: budget.currency.rawValue)) :
                                        budget.remainingAmount.formatted(.currency(code: budget.currency.rawValue))) :
                                    "****",
                                secondaryValue: showTotalExpense ? nil :
                                    "\(Int((budget.remainingAmount / budget.amount) * 100))% Remaining",
                                gradient: [
                                    Color(hex: budget.colorHex).opacity(0.7),
                                    Color(hex: budget.colorHex).opacity(0.4)
                                ],
                                backgroundIcon: "creditcard",
                                action: { showTotalExpense.toggle() }
                            )
                        }
                        .padding(.horizontal, horizontalMargin)
                        .padding(.top, sectionSpacing)
                        
                        // Tab Content - Using conditional rendering instead of TabView to avoid swipe conflicts
                        if selectedTab == 0 {
                            expensesTabContent(budget: budget)
                                .padding(.top, sectionSpacing)
                        } else if selectedTab == 1 {
                            AnalysisView(budget: budget)
                                .padding(.top, sectionSpacing)
                        } else if selectedTab == 2 {
                            SavingsView(budget: budget)
                                .padding(.top, sectionSpacing)
                        }
                        
                        // Add Budget Item Button
                        if selectedTab == 0 {
                            VStack {
                                Button {
                                    isShowingAddExpenseSheet = true
                                } label: {
                                    HStack {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.title2)

                                        Text("Add Budget Item")
                                            .font(.title3)
                                            .fontWeight(.semibold)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                isAddButtonDisabled ? Color.gray : Color(hex: budget.colorHex),
                                                isAddButtonDisabled ? Color.gray.opacity(0.7) : Color(hex: budget.colorHex).opacity(0.7)
                                            ]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .foregroundColor(.white)
                                    .cornerRadius(30)
                                    .padding(.horizontal, horizontalMargin)
                                    .padding(.top, sectionSpacing)
                                    .padding(.bottom, 8)
                                }
                                .disabled(isAddButtonDisabled)
                                .opacity(isAddButtonDisabled ? 0.6 : 1.0)

                                if viewModel.budgetItemLimitEnabled && budget.expenses.count >= 10 {
                                    Text("Maximum of 10 items reached. Disable limit in Profile.")
                                        .font(.caption)
                                        .foregroundColor(.orange)
                                        .frame(maxWidth: .infinity, alignment: .center)
                                        .padding(.bottom)
                                }
                            }
                        }
                        
                        // Add extra space at the bottom for better scrolling
                        Spacer(minLength: 100)
                    }
                }
                
                // Custom Tab Bar - Fixed at the bottom
                VStack {
                    Spacer()
                    customTabBar(budget: budget)
                }
            } else {
                // Fallback view if budget not found
                VStack {
                    Text("Budget not found")
                        .font(.title)
                        .foregroundColor(.white)
                    
                    NavigationLink(destination: HomeView()) {
                        Text("Go to Home")
                            .padding()
                            .background(Color(hex: "A169F7"))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding(.top)
                }
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                budgetMenuButton
            }
        }
        .sheet(isPresented: $isShowingAddExpenseSheet) {
            if let budget = budget {
                AddExpenseView(budgetId: budget.id, startYear: budget.startYear, budgetCurrency: budget.currency)
                    .environmentObject(viewModel)
            }
        }
        .fullScreenCover(item: $expenseToEdit) { expense in
            if let budget = budget {
                EditExpenseView(budgetId: budget.id, expense: expense, startYear: budget.startYear)
                    .environmentObject(viewModel)
            }
        }
        .fullScreenCover(isPresented: $isShowingEditBudgetView) {
            if let budget = budget {
                EditBudgetView(budget: budget)
                    .environmentObject(viewModel)
            }
        }
        .onReceive(viewModel.stateUpdatePublisher) { updatedBudgetId in
            if updatedBudgetId == budgetId {
                // Force refresh when this budget is updated
                refreshID = UUID()
            }
        }
        .id(refreshID) // Force view to refresh when refreshID changes
    }
    
    // MARK: - Helper Functions
    
    // Function to get the appropriate currency icon name
    private func currencyIconName(for currency: Currency) -> String {
        switch currency {
        case .usd:
            return "dollarsign"
        case .eur:
            return "eurosign"
        case .gbp:
            return "sterlingsign"
        case .jpy:
            return "yensign"
        }
    }
    
    // MARK: - UI Components
    
    // Summary card component
    private func summaryCard(
        iconName: String,
        title: String,
        value: String,
        secondaryValue: String?,
        gradient: [Color],
        backgroundIcon: String,
        action: (() -> Void)? = nil
    ) -> some View {
        Button {
            if let action = action {
                action()
            }
        } label: {
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Image(systemName: iconName)
                        .foregroundColor(.white)
                        .opacity(0.7)

                    Text(title)
                        .foregroundColor(.white)
                        .opacity(0.7)
                        .font(.caption)
                }

                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                if let secondaryValue = secondaryValue {
                    Text(secondaryValue)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            .padding()
            .frame(height: 100, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                ZStack {
                    LinearGradient(
                        gradient: Gradient(colors: gradient),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )

                    Image(systemName: backgroundIcon)
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(.white.opacity(0.1))
                        .frame(width: 100, height: 100)
                        .position(x: UIScreen.main.bounds.width * 0.36, y: 50)
                }
            )
            .cornerRadius(cardCornerRadius)
            .shadow(color: gradient[0].opacity(0.4), radius: 10, x: 0, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(action == nil)
    }
    
    private var budgetMenuButton: some View {
        Menu {
            Button("Edit Budget") {
                isShowingEditBudgetView = true
            }
            
            Button("Duplicate Budget") {
                if let budget = budget {
                    viewModel.duplicateBudget(id: budget.id)
                }
            }
            
            Button("Delete Budget", role: .destructive) {
                if let budget = budget {
                    viewModel.deleteBudget(id: budget.id)
                }
            }
        } label: {
            Image(systemName: "ellipsis")
                .foregroundColor(.white)
        }
    }
    
    @ViewBuilder
    private func expensesTabContent(budget: Budget) -> some View {
        VStack(alignment: .leading) {
            // Budget Items List Header
            HStack {
                Text("Budget Items")
                    .foregroundColor(.white)
                    .font(.headline)

                Spacer()

                if viewModel.budgetItemLimitEnabled {
                    Text("\(budget.expenses.count)/10")
                        .foregroundColor(budget.expenses.count >= 10 ? .orange : .gray)
                } else {
                    Text("\(budget.expenses.count) items")
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal, horizontalMargin)
            .id(refreshID) // Force header to refresh when expenses change

            if sortedExpenses.isEmpty {
                // Empty state
                Text("No expenses yet")
                    .foregroundColor(.gray)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .frame(minHeight: 200)
                    .id("empty-\(refreshID)") // Force empty state to refresh
            } else {
                // List with swipe actions
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(sortedExpenses) { expense in
                            ExpenseRowWithSwipe(
                                expense: expense,
                                showValues: viewModel.showValuesEnabled,
                                budgetCurrency: budget.currency,
                                budgetColorHex: budget.colorHex,
                                onDelete: {
                                    withAnimation {
                                        viewModel.deleteExpense(id: expense.id, from: budget.id)
                                    }
                                },
                                onEdit: {
                                    expenseToEdit = expense
                                }
                            )
                            .id("expense-\(expense.id)-\(refreshID)")
                        }
                    }
                    .padding(.horizontal, horizontalMargin)
                }
                .id("list-\(refreshID)")
                .animation(.default, value: sortedExpenses.count)
            }
        }
    }
    
    private func customTabBar(budget: Budget) -> some View {
        ZStack {
            Color(hex: "282C3E")
                .edgesIgnoringSafeArea(.bottom)
                .frame(height: 60)
                .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: -2)
            
            HStack {
                Spacer()
                
                // Budget Tab Button
                tabButtonView(
                    title: "Budget",
                    icon: "list.bullet",
                    isSelected: selectedTab == 0,
                    colorHex: budget.colorHex,
                    onTap: { selectedTab = 0 }
                )
                
                Spacer()
                
                // Analysis Tab Button
                tabButtonView(
                    title: "Analysis",
                    icon: "chart.pie.fill",
                    isSelected: selectedTab == 1,
                    colorHex: budget.colorHex,
                    onTap: { selectedTab = 1 }
                )
                
                Spacer()
                
                // Savings Tab Button
                tabButtonView(
                    title: "Savings",
                    icon: "chart.line.uptrend.xyaxis",
                    isSelected: selectedTab == 2,
                    colorHex: budget.colorHex,
                    onTap: { selectedTab = 2 }
                )
                
                Spacer()
            }
            .padding(.vertical, 6)
        }
        .frame(height: 60)
    }
    
    private func tabButtonView(title: String, icon: String, isSelected: Bool, colorHex: String, onTap: @escaping () -> Void) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.3)) {
                onTap()
            }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                Text(title)
                    .font(.caption)
            }
            .foregroundColor(isSelected ? Color(hex: colorHex) : Color.gray)
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .background(
                isSelected ?
                    Color(hex: colorHex).opacity(0.2) :
                    Color.clear
            )
            .cornerRadius(8)
        }
    }
}

// Custom ExpenseRow wrapper with swipe actions
struct ExpenseRowWithSwipe: View {
    let expense: Expense
    let showValues: Bool
    let budgetCurrency: Currency
    let budgetColorHex: String
    let onDelete: () -> Void
    let onEdit: () -> Void
    
    @State private var offset: CGFloat = 0
    @State private var isSwiping = false
    @State private var showDeleteButton = false
    @State private var showEditButton = false
    
    var body: some View {
        ZStack {
            // Background with swipe action buttons
            HStack(spacing: 0) {
                // Edit button (left swipe)
                Button {
                    withAnimation {
                        offset = 0
                        showEditButton = false
                        onEdit()
                    }
                } label: {
                    HStack {
                        Image(systemName: "pencil")
                        Text("Edit")
                    }
                    .padding()
                    .frame(maxHeight: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                }
                .opacity(showEditButton ? 1 : 0)
                
                Spacer()
                
                // Delete button (right swipe)
                Button {
                    withAnimation {
                        offset = 0
                        showDeleteButton = false
                        onDelete()
                    }
                } label: {
                    HStack {
                        Text("Delete")
                        Image(systemName: "trash")
                    }
                    .padding()
                    .frame(maxHeight: .infinity)
                    .background(Color.red)
                    .foregroundColor(.white)
                }
                .opacity(showDeleteButton ? 1 : 0)
            }
            .frame(maxWidth: .infinity)
            
            // Main expense row content
            ExpenseRow(
                expense: expense,
                showValues: showValues,
                budgetCurrency: budgetCurrency,
                budgetColorHex: budgetColorHex
            )
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
            .offset(x: offset)
            .gesture(
                DragGesture()
                    .onChanged { gesture in
                        if !isSwiping {
                            isSwiping = true
                        }
                        
                        // Limit the drag distance
                        let dragDistance = gesture.translation.width
                        if dragDistance > 0 {
                            // Right swipe (for edit)
                            offset = min(dragDistance, 120)
                            showEditButton = offset > 60
                            showDeleteButton = false
                        } else {
                            // Left swipe (for delete)
                            offset = max(dragDistance, -120)
                            showDeleteButton = offset < -60
                            showEditButton = false
                        }
                    }
                    .onEnded { gesture in
                        isSwiping = false
                        
                        // Decide whether to snap back or complete the action
                        let dragDistance = gesture.translation.width
                        if dragDistance > 100 {
                            // Complete edit action
                            withAnimation {
                                offset = 0
                                showEditButton = false
                                onEdit()
                            }
                        } else if dragDistance < -100 {
                            // Complete delete action
                            withAnimation {
                                offset = 0
                                showDeleteButton = false
                                onDelete()
                            }
                        } else {
                            // Snap back to original position
                            withAnimation {
                                offset = 0
                                showEditButton = false
                                showDeleteButton = false
                            }
                        }
                    }
            )
            .onTapGesture {
                withAnimation {
                    if offset != 0 {
                        offset = 0
                        showEditButton = false
                        showDeleteButton = false
                    }
                }
            }
        }
    }
}

// Preview
struct BudgetDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleExpenses = [
            Expense(
                name: "Groceries",
                amount: 100.0,
                currency: .usd,
                category: .food,
                date: Date(),
                isEssential: true,
                notes: "Weekly grocery shopping"
            ),
            Expense(
                name: "Netflix",
                amount: 15.99,
                currency: .usd,
                category: .entertainment,
                date: Date().addingTimeInterval(-86400),
                isEssential: false,
                notes: "Monthly subscription"
            )
        ]
        
        let sampleBudget = Budget(
            name: "Monthly Budget",
            amount: 1000.0,
            currency: .usd,
            iconName: "dollarsign.circle",
            colorHex: "A169F7",
            isMonthly: true,
            expenses: sampleExpenses,
            startMonth: 1,
            startYear: 2023
        )
        
        let viewModel = BudgetViewModel()
        viewModel.addBudget(sampleBudget)
        
        return NavigationView {
            BudgetDetailView(budgetId: sampleBudget.id)
                .environmentObject(viewModel)
        }
    }
}
