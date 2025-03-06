import SwiftUI

struct HomeView: View {
    @EnvironmentObject var viewModel: BudgetViewModel
    @State private var showingAddBudget = false
    @State private var showingEditInsights = false
    @State private var showingBudgetStatusSettings = false
    
    // MARK: - Layout Constants (Adjust these to fine-tune the layout)
    private let horizontalMargin: CGFloat = 44 // Increase this for more margin from edges
    private let titleTopPadding: CGFloat = 20
    private let titleBottomSpacing: CGFloat = 65 // Increase this for more space below "My Budgets"
    private let cardSpacing: CGFloat = 16 // Space between budget cards
    private let cardVerticalPadding: CGFloat = 20 // Internal top/bottom padding of cards
    private let cardHorizontalPadding: CGFloat = 24 // Internal left/right padding of cards
    private let avatarSize: CGFloat = 48 // Increased from 40 to 48 for a larger profile image
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background image
                Image("LaunchBG3")
                    .resizable()
                    .scaledToFill()
                    .edgesIgnoringSafeArea(.all)
                
                // Content
                VStack(alignment: .leading, spacing: 0) {
                    // App Title
                    Text("BudgetBox")
                        .foregroundColor(ThemeManager.Colors.secondaryText)
                        .padding(.horizontal, horizontalMargin)
                        .padding(.top, titleTopPadding)
                    
                    // Header with Controls
                    HStack {
                        Text("My Budgets")
                            .font(.largeTitle)
                            .bold()
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        // Budget Status Filter Button
                        Button(action: {
                            showingBudgetStatusSettings = true
                        }) {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                                .foregroundColor(.white)
                                .font(.title2)
                        }
                        .padding(.horizontal, 5)
                        
                        // Show/Hide Values Button
                        Button(action: {
                            viewModel.toggleShowValues()
                        }) {
                            Image(systemName: viewModel.showValuesEnabled ? "eye.fill" : "eye.slash.fill")
                                .foregroundColor(.white)
                                .font(.title2)
                        }
                        .padding(.horizontal, 5)
                        
                        // Profile Button - now larger with white border
                        NavigationLink(destination: ProfileView().environmentObject(viewModel)) {
                            if let avatarData = viewModel.userAvatar,
                               let uiImage = UIImage(data: avatarData) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: avatarSize, height: avatarSize)
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white, lineWidth: 2) // Changed to white border
                                    )
                            } else {
                                Image(systemName: "person.crop.circle")
                                    .foregroundColor(.white)
                                    .font(.system(size: avatarSize * 0.8)) // Scale icon to match new size
                            }
                        }
                    }
                    .padding(.horizontal, horizontalMargin)
                    .padding(.top, 10)
                    // Add significant space between title and first card
                    .padding(.bottom, titleBottomSpacing)
                    
                    // Status indicator and filter info
                    if !viewModel.visibleBudgets.isEmpty {
                        HStack {
                            if viewModel.budgets.count != viewModel.visibleBudgets.count {
                                Text("Showing \(viewModel.visibleBudgets.count) of \(viewModel.budgets.count) budgets")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            
                            Spacer()
                            
                            if viewModel.budgets.count != viewModel.activeBudgets.count {
                                Text("\(viewModel.activeBudgets.count) active, \(viewModel.budgets.count - viewModel.activeBudgets.count) inactive")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(.horizontal, horizontalMargin)
                        .padding(.bottom, 10)
                    }
                    
                    ScrollView {
                        VStack(spacing: 24) {
                            // Empty state message if no visible budgets
                            if viewModel.visibleBudgets.isEmpty {
                                if viewModel.budgets.isEmpty {
                                    // No budgets at all
                                    VStack(spacing: 16) {
                                        Image(systemName: "tray")
                                            .font(.system(size: 50))
                                            .foregroundColor(.gray)
                                        
                                        Text("No budgets yet")
                                            .font(.headline)
                                            .foregroundColor(.white)
                                        
                                        Text("Add your first budget to get started")
                                            .foregroundColor(.gray)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.top, 60)
                                } else {
                                    // Has budgets but all are filtered out
                                    VStack(spacing: 16) {
                                        Image(systemName: "eye.slash")
                                            .font(.system(size: 50))
                                            .foregroundColor(.gray)
                                        
                                        Text("No visible budgets")
                                            .font(.headline)
                                            .foregroundColor(.white)
                                        
                                        Button(action: {
                                            showingBudgetStatusSettings = true
                                        }) {
                                            Text("Adjust filter settings")
                                                .foregroundColor(Color(hex: "A169F7"))
                                        }
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.top, 60)
                                }
                            }
                            
                            // Budget List
                            LazyVStack(spacing: cardSpacing) {
                                ForEach(viewModel.visibleBudgets) { budget in
                                    NavigationLink(destination: BudgetDetailView(budgetId: budget.id)) {
                                        VStack(alignment: .leading, spacing: 5) {
                                            // Header row with icon, name, and amount
                                            HStack {
                                                // Icon with color
                                                Image(systemName: budget.iconName)
                                                    // Use the budget's actual color
                                                    .foregroundColor(Color(hex: budget.colorHex))
                                                    .font(.title)
                                                    .frame(width: 40, height: 40)
                                                    .padding(.trailing, 5)
                                                
                                                // Budget name and type with status indicator
                                                VStack(alignment: .leading) {
                                                    HStack {
                                                        Text(budget.name)
                                                            .font(.headline)
                                                            .foregroundColor(.white)
                                                        
                                                        // Status indicator for inactive budgets
                                                        if !budget.isActive {
                                                            Text("INACTIVE")
                                                                .font(.system(size: 10))
                                                                .padding(.horizontal, 5)
                                                                .padding(.vertical, 2)
                                                                .background(Color.gray.opacity(0.5))
                                                                .foregroundColor(.white)
                                                                .cornerRadius(4)
                                                        }
                                                    }
                                                    
                                                    Text(budget.isMonthly ? "Monthly Budget" : "One-time Budget")
                                                        .font(.subheadline)
                                                        .foregroundColor(.gray)
                                                }
                                                
                                                Spacer()
                                                
                                                // Amount
                                                if viewModel.showValuesEnabled {
                                                    Text("\(budget.amount.formatted(.currency(code: budget.currency.rawValue)))")
                                                        .font(.title3)
                                                        .bold()
                                                        .foregroundColor(.white)
                                                } else {
                                                    Text("****")
                                                        .font(.title3)
                                                        .bold()
                                                        .foregroundColor(.white)
                                                }
                                            }
                                            
                                            // Progress indicator
                                            GeometryReader { geometry in
                                                ZStack(alignment: .leading) {
                                                    // Background
                                                    RoundedRectangle(cornerRadius: 3)
                                                        .foregroundColor(.gray.opacity(0.3))
                                                        .frame(height: 6)
                                                    
                                                    // Progress - using the budget's color
                                                    RoundedRectangle(cornerRadius: 3)
                                                        .foregroundColor(Color(hex: budget.colorHex))
                                                        .frame(width: max(0, CGFloat(budget.percentRemaining) / 100.0 * geometry.size.width), height: 6)
                                                }
                                            }
                                            .frame(height: 6)
                                            .padding(.vertical, 10)
                                            
                                            // Remaining amount and percentage
                                            HStack {
                                                Text("Remaining")
                                                    .font(.caption)
                                                    .foregroundColor(.gray)
                                                
                                                Spacer()
                                                
                                                if viewModel.showValuesEnabled {
                                                    // Use green text for positive remaining amounts
                                                    Text("\(budget.remainingAmount.formatted(.currency(code: budget.currency.rawValue)))")
                                                        .foregroundColor(.green)
                                                        .font(.subheadline)
                                                } else {
                                                    Text("****")
                                                        .foregroundColor(.green)
                                                        .font(.subheadline)
                                                }
                                                
                                                Text("\(budget.percentRemaining)%")
                                                    .font(.caption)
                                                    .foregroundColor(.gray)
                                                    .frame(width: 50, alignment: .trailing)
                                            }
                                        }
                                        .padding(.horizontal, cardHorizontalPadding)
                                        .padding(.vertical, cardVerticalPadding)
                                        .background(Color.black.opacity(0.6))
                                        .opacity(budget.isActive ? 1.0 : 0.7) // Reduce opacity for inactive budgets
                                        .cornerRadius(20)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .contextMenu {
                                        // Toggle active status option
                                        Button(action: {
                                            viewModel.toggleBudgetActive(id: budget.id)
                                        }) {
                                            Label(budget.isActive ? "Deactivate Budget" : "Activate Budget",
                                                  systemImage: budget.isActive ? "pause.circle" : "play.circle")
                                        }
                                        
                                        NavigationLink(destination: EditBudgetView(budget: budget)) {
                                            Label("Edit", systemImage: "pencil")
                                        }
                                        
                                        Button(role: .destructive, action: {
                                            viewModel.deleteBudget(id: budget.id)
                                        }) {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                                }
                                .padding(.horizontal, horizontalMargin)
                            }
                            
                            // Only show insights if there are active budgets
                            if !viewModel.activeBudgets.isEmpty {
                                // Budget Insights with Edit capability
                                BudgetInsights(
                                    budgets: viewModel.activeBudgets,
                                    showValues: viewModel.showValuesEnabled,
                                    selectedInsights: viewModel.selectedInsights,
                                    onEditTapped: {
                                        showingEditInsights = true
                                    }
                                )
                                .padding(.top, 24) // Add extra space between budget cards and insights
                                .background(Color.black.opacity(0.3)) // Semi-transparent background
                                .cornerRadius(20) // Rounded corners to match budget cards
                                .padding(.horizontal, horizontalMargin) // Match the budget cards' horizontal margins
                            } else if !viewModel.budgets.isEmpty {
                                // Show message when there are budgets but none are active
                                VStack(spacing: 16) {
                                    Image(systemName: "chart.bar.xaxis")
                                        .font(.system(size: 30))
                                        .foregroundColor(.gray)
                                    
                                    Text("No active budgets")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                    
                                    Text("Activate a budget to see insights")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 30)
                                .background(Color.black.opacity(0.3))
                                .cornerRadius(20)
                                .padding(.horizontal, horizontalMargin)
                                .padding(.top, 24)
                            }
                            
                            // Add spacing at the bottom for proper scrolling
                            Spacer(minLength: 100)
                        }
                    }
                    
                    Spacer() // Push content up, add budget button down
                    
                    // Add Budget Button
                    Button(action: {
                        showingAddBudget = true
                    }) {
                        HStack {
                            Image(systemName: "plus")
                                .font(.headline)
                            
                            Text("Add Budget")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(hex: "FF5E7D"))
                        .foregroundColor(.white)
                        .cornerRadius(28)
                        .padding(.horizontal, horizontalMargin)
                        .padding(.bottom, 20)
                    }
                }
            }
            .sheet(isPresented: $showingAddBudget) {
                AddBudgetView()
            }
            .sheet(isPresented: $showingEditInsights) {
                EditInsightsView()
                    .environmentObject(viewModel)
            }
            .sheet(isPresented: $showingBudgetStatusSettings) {
                BudgetStatusSettingsView()
                    .environmentObject(viewModel)
            }
            .navigationBarHidden(true)
        }
    }
}

// MARK: - Budget Status Settings View
struct BudgetStatusSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var viewModel: BudgetViewModel
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "383C51")
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    // Show/Hide Inactive Budgets Toggle
                    Toggle(isOn: $viewModel.showInactiveBudgets) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Show Inactive Budgets")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Text("Display budgets that are not included in calculations")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    .toggleStyle(SwitchToggleStyle(tint: Color(hex: "A169F7")))
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(10)
                    .onChange(of: viewModel.showInactiveBudgets) { _ in
                        viewModel.saveData()
                    }
                    
                    // Budget Status List
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Budget Status")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal)
                        
                        if viewModel.budgets.isEmpty {
                            Text("No budgets created yet")
                                .foregroundColor(.gray)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .center)
                        } else {
                            ScrollView {
                                VStack(spacing: 12) {
                                    ForEach(viewModel.budgets) { budget in
                                        HStack {
                                            // Budget name with icon
                                            HStack {
                                                Image(systemName: budget.iconName)
                                                    .foregroundColor(Color(hex: budget.colorHex))
                                                
                                                Text(budget.name)
                                                    .foregroundColor(.white)
                                            }
                                            
                                            Spacer()
                                            
                                            // Toggle switch
                                            Toggle("", isOn: Binding(
                                                get: { budget.isActive },
                                                set: { _ in
                                                    viewModel.toggleBudgetActive(id: budget.id)
                                                }
                                            ))
                                            .labelsHidden()
                                            .toggleStyle(SwitchToggleStyle(tint: Color(hex: "A169F7")))
                                        }
                                        .padding()
                                        .background(Color.gray.opacity(0.2))
                                        .cornerRadius(10)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Info about inactive budgets
                    VStack(alignment: .leading, spacing: 8) {
                        Text("About Inactive Budgets")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text("• Inactive budgets are excluded from insights and calculations")
                            .foregroundColor(.gray)
                        
                        Text("• Use this feature to archive old budgets or create mockups")
                            .foregroundColor(.gray)
                        
                        Text("• You can still view and edit inactive budgets")
                            .foregroundColor(.gray)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(10)
                    .padding(.horizontal)
                }
                .padding()
            }
            .navigationTitle("Budget Status")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    let viewModel = BudgetViewModel()
    // Add sample budgets for preview
    let budget1 = Budget(
        name: "ES Family",
        amount: 3000.0,
        currency: .eur,
        iconName: "house.fill",
        colorHex: "FF5252", // Red color
        isMonthly: true,
        startMonth: 1,
        startYear: 2023,
        isActive: true
    )
    viewModel.addBudget(budget1)
    
    let budget2 = Budget(
        name: "Jaz Personal",
        amount: 600.0,
        currency: .eur,
        iconName: "gamecontroller.fill",
        colorHex: "536DFE", // Blue color
        isMonthly: true,
        startMonth: 1,
        startYear: 2023,
        isActive: false // Inactive
    )
    viewModel.addBudget(budget2)
    
    let budget3 = Budget(
        name: "Japan Trip",
        amount: 500.0,
        currency: .jpy,
        iconName: "airplane",
        colorHex: "9C27B0", // Purple color
        isMonthly: true,
        startMonth: 1,
        startYear: 2023,
        isActive: true
    )
    viewModel.addBudget(budget3)
    
    return HomeView()
        .environmentObject(viewModel)
}
