import SwiftUI

struct BudgetDetailView: View {
    @EnvironmentObject var viewModel: BudgetViewModel
    @State var budget: Budget
    
    @State private var isShowingSheet = false
    @State private var sheetMode: SheetMode = .add
    @State private var expenseToEdit: Expense?
    @State private var showTotalExpense = true
    
    enum SheetMode {
        case add, edit
    }
    
    // Sort expenses by date (earliest first)
    var sortedExpenses: [Expense] {
        budget.expenses.sorted(by: { $0.date < $1.date })
    }
    
    var body: some View {
        ZStack {
            Color(hex: "383C51")
                .ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 10) {
                Text("Budget Plan")
                    .foregroundColor(.gray)
                    .padding(.horizontal)
                
                HStack {
                    Text(budget.name)
                        .font(.largeTitle)
                        .bold()
                        .foregroundColor(.white)
                        .padding(.horizontal)
                    
                    Spacer()
                    
                    Circle()
                        .fill(Color(hex: budget.colorHex))
                        .frame(width: 50, height: 50)
                        .overlay(
                            Image(systemName: budget.iconName)
                                .font(.title2)
                                .foregroundColor(.white)
                        )
                        .padding(.horizontal)
                }
                
                HStack(spacing: 20) {
                    // Total Budget
                    VStack(alignment: .leading, spacing: 5) {
                        HStack {
                            Image(systemName: "arrow.down")
                                .foregroundColor(.white)
                                .opacity(0.7)
                            
                            Text("Total Budget")
                                .foregroundColor(.white)
                                .opacity(0.7)
                                .font(.caption)
                        }
                        
                        if viewModel.showValuesEnabled {
                            Text(budget.amount.formatted(.currency(code: budget.currency.rawValue)))
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        } else {
                            Text("****")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                    }
                    .padding()
                    .frame(width: 180, height: 100, alignment: .leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        ZStack {
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(hex: budget.colorHex),
                                    Color(hex: budget.colorHex).opacity(0.7)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            
                            Image(systemName: "eurosign")
                                .resizable()
                                .scaledToFit()
                                .foregroundColor(.white.opacity(0.1))
                                .frame(width: 100, height: 100)
                                .position(x: UIScreen.main.bounds.width * 0.36, y: 50)
                        }
                    )
                    .cornerRadius(16)
                    .shadow(color: Color(hex: budget.colorHex).opacity(0.4), radius: 10, x: 0, y: 4)
                    
                    // Total Expense
                    VStack(alignment: .leading, spacing: 5) {
                        HStack {
                            Image(systemName: "arrow.up")
                                .foregroundColor(.white)
                                .opacity(0.7)
                            
                            Text(showTotalExpense ? "Total Expense" : "Remaining Budget")
                                .foregroundColor(.white)
                                .opacity(0.7)
                                .font(.caption)
                        }
                        
                        if viewModel.showValuesEnabled {
                            Button(action: {
                                withAnimation {
                                    showTotalExpense.toggle()
                                }
                            }) {
                                VStack(alignment: .leading, spacing: 0) {
                                    if showTotalExpense {
                                        Text((budget.amount - budget.remainingAmount).formatted(.currency(code: budget.currency.rawValue)))
                                            .font(.title2)
                                            .fontWeight(.bold)
                                            .foregroundColor(.white)
                                    } else {
                                        Text(budget.remainingAmount.formatted(.currency(code: budget.currency.rawValue)))
                                            .font(.title2)
                                            .fontWeight(.bold)
                                            .foregroundColor(.white)
                                        
                                        Text("\(Int((budget.remainingAmount / budget.amount) * 100))% Remaining")
                                            .font(.caption)
                                            .foregroundColor(.white.opacity(0.7))
                                    }
                                }
                            }
                        } else {
                            Text("****")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                    }
                    .padding()
                    .frame(width: 180, height: 100, alignment: .leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        ZStack {
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(hex: budget.colorHex).opacity(0.7),
                                    Color(hex: budget.colorHex).opacity(0.4)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            
                            Image(systemName: "creditcard")
                                .resizable()
                                .scaledToFit()
                                .foregroundColor(.white.opacity(0.05))
                                .frame(width: 100, height: 100)
                                .position(x: UIScreen.main.bounds.width * 0.36, y: 50)
                        }
                    )
                    .cornerRadius(16)
                    .shadow(color: Color(hex: budget.colorHex).opacity(0.4), radius: 10, x: 0, y: 4)
                    }
                    .padding(.horizontal)
                
                
                // Budget Items
                VStack(alignment: .leading) {
                    HStack {
                        Text("Budget Items")
                            .foregroundColor(.white)
                            .font(.headline)
                        
                        Spacer()
                        
                        Text("\(budget.expenses.count)/10")
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal)
                    
                    // Expense List
                    if budget.expenses.isEmpty {
                        Text("No expenses yet")
                            .foregroundColor(.gray)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .center)
                    } else {
                        List {
                            ForEach(sortedExpenses) { expense in
                                ExpenseRow(
                                    expense: expense,
                                    showValues: viewModel.showValuesEnabled,
                                    budgetCurrency: budget.currency
                                )
                                .listRowBackground(Color.gray.opacity(0.1))
                                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        viewModel.deleteExpense(id: expense.id, from: budget.id)
                                        updateBudgetFromViewModel()
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                                .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                    Button {
                                        expenseToEdit = expense
                                        sheetMode = .edit
                                        isShowingSheet = true
                                    } label: {
                                        Label("Edit", systemImage: "pencil")
                                    }
                                    .tint(.blue)
                                }
                            }
                            .listRowSeparator(.hidden)
                        }
                        .listStyle(PlainListStyle())
                        .background(Color(hex: "383C51"))
                        .scrollContentBackground(.hidden)
                    }
                }
                
                Spacer()
                
                // Add Expense Button
                Button(action: {
                    expenseToEdit = nil
                    sheetMode = .add
                    isShowingSheet = true
                }) {
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
                                Color(hex: budget.colorHex),
                                Color(hex: budget.colorHex).opacity(0.7)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(30)
                    .padding(.horizontal)
                    .padding(.bottom)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Edit Budget") {
                            // Open edit budget
                        }
                        
                        Button("Delete Budget", role: .destructive) {
                            viewModel.deleteBudget(id: budget.id)
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .sheet(isPresented: $isShowingSheet, onDismiss: {
            updateBudgetFromViewModel()
            // Reset state after sheet is dismissed
            if sheetMode == .edit {
                expenseToEdit = nil
            }
            // Always reset to add mode after dismissal
            sheetMode = .add
        }) {
            if sheetMode == .edit && expenseToEdit != nil {
                EditExpenseView(budgetId: budget.id, expense: expenseToEdit!)
                    .environmentObject(viewModel)
            } else {
                AddExpenseView(budgetId: budget.id)
                    .environmentObject(viewModel)
            }
        }
        .onAppear {
            // Update budget from viewModel when view appears
            updateBudgetFromViewModel()
            
            // Add notification observer for real-time updates
            NotificationCenter.default.addObserver(
                forName: NSNotification.Name("RefreshBudgetDetail"),
                object: nil,
                queue: .main
            ) { _ in
                updateBudgetFromViewModel()
            }
        }
        .onDisappear {
            // Update viewModel when navigating away
            if let updatedBudget = viewModel.budgets.first(where: { $0.id == budget.id }) {
                viewModel.updateBudget(updatedBudget)
            }
            
            // Remove notification observer
            NotificationCenter.default.removeObserver(self, name: NSNotification.Name("RefreshBudgetDetail"), object: nil)
        }
    }
    
    func updateBudgetFromViewModel() {
        if let updatedBudget = viewModel.budgets.first(where: { $0.id == budget.id }) {
            budget = updatedBudget
        }
    }
}
