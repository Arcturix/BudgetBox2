import SwiftUI

struct HomeView: View {
    @EnvironmentObject var viewModel: BudgetViewModel
    @State private var showingAddBudget = false
    
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
                        
                        // Show/Hide Values Button
                        Button(action: {
                            viewModel.toggleShowValues()
                        }) {
                            Image(systemName: viewModel.showValuesEnabled ? "eye.fill" : "eye.slash.fill")
                                .foregroundColor(.white)
                                .font(.title2)
                        }
                        .padding(.horizontal, 10)
                        
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
                    
                    // Budget List
                    ScrollView {
                        LazyVStack(spacing: cardSpacing) {
                            ForEach(viewModel.budgets) { budget in
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
                                            
                                            // Budget name and type
                                            VStack(alignment: .leading) {
                                                Text(budget.name)
                                                    .font(.headline)
                                                    .foregroundColor(.white)
                                                
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
                                    .cornerRadius(20)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .contextMenu {
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
                        
                        // Add spacing at the bottom for proper scrolling
                        Spacer(minLength: 100)
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
            .navigationBarHidden(true)
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
        startYear: 2023
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
        startYear: 2023
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
        startYear: 2023
    )
    viewModel.addBudget(budget3)
    
    return HomeView()
        .environmentObject(viewModel)
}
