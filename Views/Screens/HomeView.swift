import SwiftUI

struct HomeView: View {
    @EnvironmentObject var viewModel: BudgetViewModel
    @State private var showingAddBudget = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "383C51")
                    .ignoresSafeArea()
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("BudgetBox")
                        .foregroundColor(.gray)
                        .padding(.horizontal)
                    
                    HStack {
                        Text("My Budgets")
                            .font(.largeTitle)
                            .bold()
                            .foregroundColor(.white)
                            .padding(.horizontal)
                        
                        Spacer()
                        
                        Button(action: {
                            viewModel.toggleShowValues()
                        }) {
                            Image(systemName: viewModel.showValuesEnabled ? "eye.fill" : "eye.slash.fill")
                                .foregroundColor(.white)
                                .font(.title2)
                        }
                        .padding(.horizontal)
                        
                        if let avatarData = viewModel.userAvatar,
                           let uiImage = UIImage(data: avatarData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 40, height: 40)
                                .clipShape(Circle())
                                .padding(.horizontal)
                        } else {
                            Button(action: {
                                // Open profile settings
                            }) {
                                Image(systemName: "person.crop.circle")
                                    .foregroundColor(.white)
                                    .font(.title)
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(viewModel.budgets) { budget in
                                NavigationLink(destination: BudgetDetailView(budget: budget)) {
                                    BudgetCard(budget: budget, showValues: viewModel.showValuesEnabled)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .contextMenu {
                                    Button(action: {
                                        // Edit budget
                                    }) {
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
                                gradient: Gradient(colors: [Color(hex: "FF5E7D"), Color(hex: "A169F7")]),
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
    
    struct HomeView_Previews: PreviewProvider {
        static var previews: some View {
            let viewModel = BudgetViewModel()
            
            return HomeView()
                .environmentObject(viewModel)
                .preferredColorScheme(.dark)
        }
    }
}
