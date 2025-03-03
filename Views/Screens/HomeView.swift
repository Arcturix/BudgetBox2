// Views/Screens/HomeView.swift

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var viewModel: BudgetViewModel
    @State private var showingAddBudget = false
    
    var body: some View {
        NavigationView {
            ZStack {
                ThemeManager.Colors.primary
                    .ignoresSafeArea()
                
                VStack(alignment: .leading, spacing: 10) {
                    // App Title
                    Text("BudgetBox")
                        .foregroundColor(ThemeManager.Colors.secondaryText)
                        .padding(.horizontal)
                    
                    // Header with Controls
                    HStack {
                        Text("My Budgets")
                            .font(.largeTitle)
                            .bold()
                            .foregroundColor(ThemeManager.Colors.primaryText)
                            .padding(.horizontal)
                        
                        Spacer()
                        
                        // Show/Hide Values Button
                        Button(action: {
                            viewModel.toggleShowValues()
                        }) {
                            Image(systemName: viewModel.showValuesEnabled ? "eye.fill" : "eye.slash.fill")
                                .foregroundColor(ThemeManager.Colors.primaryText)
                                .font(.title2)
                        }
                        .padding(.horizontal)
                        
                        // Profile Button
                        NavigationLink(destination: ProfileView().environmentObject(viewModel)) {
                            if let avatarData = viewModel.userAvatar,
                               let uiImage = UIImage(data: avatarData) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 40, height: 40)
                                    .clipShape(Circle())
                                    .padding(.horizontal)
                            } else {
                                Image(systemName: "person.crop.circle")
                                    .foregroundColor(ThemeManager.Colors.primaryText)
                                    .font(.title)
                                    .padding(.horizontal)
                            }
                        }
                    }
                    
                    // Budget List
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(viewModel.budgets) { budget in
                                NavigationLink(destination: BudgetDetailView(budgetId: budget.id)) {
                                    BudgetCard(budget: budget, showValues: viewModel.showValuesEnabled)
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
                            .padding(.horizontal)
                        }
                    }
                    
                    // Add Budget Button
                    Button(action: {
                        showingAddBudget = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                            
                            Text("Add Budget")
                                .font(.title3)
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [ThemeManager.Colors.secondaryAccent, ThemeManager.Colors.secondaryAccent]),
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
            }
            .sheet(isPresented: $showingAddBudget) {
                AddBudgetView()
            }
            .navigationBarHidden(true)
        }
    }
}

#Preview {
    let viewModel = BudgetViewModel()
    return HomeView()
        .environmentObject(viewModel)
}
