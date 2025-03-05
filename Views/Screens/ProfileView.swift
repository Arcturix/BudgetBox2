import SwiftUI
import PhotosUI

struct ProfileView: View {
    @EnvironmentObject var viewModel: BudgetViewModel
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImageData: Data?
    @State private var selectedLoanCurrency: Currency = .usd
    
    var body: some View {
        ZStack {
            Color(hex: "383C51")
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Text("Profile Settings")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                VStack {
                    if let avatarData = viewModel.userAvatar,
                       let uiImage = UIImage(data: avatarData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 120, height: 120)
                            .clipShape(Circle())
                    } else {
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .frame(width: 120, height: 120)
                            .foregroundColor(.gray)
                    }
                    
                    PhotosPicker(
                        selection: $selectedItem,
                        matching: .images,
                        photoLibrary: .shared()) {
                            Text("Change Profile Picture")
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.gray.opacity(0.3))
                                .cornerRadius(10)
                        }
                        .padding(.top)
                }
                
                // Settings Section
                VStack(spacing: 15) {
                    // Show Values Toggle
                    Toggle(isOn: $viewModel.showValuesEnabled) {
                        Text("Show Amount Values")
                            .foregroundColor(.white)
                    }
                    .toggleStyle(SwitchToggleStyle(tint: Color(hex: "A169F7")))
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(10)
                    .onChange(of: viewModel.showValuesEnabled) { viewModel.saveData() }
                    
                    // Student Loan Section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Student Loan")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            // Tooltip Button
                            Button(action: {
                                // Show tooltip info (can be expanded later)
                            }) {
                                Image(systemName: "info.circle")
                                    .foregroundColor(.gray)
                            }
                            .help("Enter your student loan details to track them in your budgeting. This information will be used for financial planning and is stored locally on your device only. You can update this information anytime as your loan balance changes.")
                        }
                        
                        // Outstanding Balance Field with Currency Selector
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Outstanding Balance")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            
                            HStack {
                                TextField("0.00", value: $viewModel.studentLoanBalance, format: .number)
                                    .keyboardType(.decimalPad)
                                    .padding(10)
                                    .background(Color.black.opacity(0.2))
                                    .cornerRadius(8)
                                    .foregroundColor(.white)
                                    .onChange(of: viewModel.studentLoanBalance) { viewModel.saveData() }
                                
                                // Currency Picker
                                Menu {
                                    ForEach(Currency.allCases, id: \.self) { currency in
                                        Button(action: {
                                            viewModel.studentLoanCurrency = currency
                                            viewModel.saveData()
                                        }) {
                                            HStack {
                                                Text("\(currency.symbol) \(currency.rawValue)")
                                                if viewModel.studentLoanCurrency == currency {
                                                    Image(systemName: "checkmark")
                                                }
                                            }
                                        }
                                    }
                                } label: {
                                    Text(viewModel.studentLoanCurrency.symbol)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(Color.gray.opacity(0.3))
                                        .cornerRadius(8)
                                }
                            }
                        }
                        
                        // Interest Rate Field
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Interest Rate (%)")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            
                            TextField("0.00", value: $viewModel.studentLoanInterestRate, format: .number.precision(.fractionLength(2)))
                                .keyboardType(.decimalPad)
                                .padding(10)
                                .background(Color.black.opacity(0.2))
                                .cornerRadius(8)
                                .foregroundColor(.white)
                                .onChange(of: viewModel.studentLoanInterestRate) { viewModel.saveData() }
                                .overlay(
                                    Text("%")
                                        .foregroundColor(.gray)
                                        .padding(.trailing, 12),
                                    alignment: .trailing
                                )
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(10)
                    
                    // Budget Item Limit Toggle
                    VStack(alignment: .leading, spacing: 5) {
                        Toggle(isOn: $viewModel.budgetItemLimitEnabled) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Budget Item Limit")
                                    .foregroundColor(.white)
                                
                                Text("Limit of 10 items per budget")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                        .toggleStyle(SwitchToggleStyle(tint: Color(hex: "A169F7")))
                        .onChange(of: viewModel.budgetItemLimitEnabled) { viewModel.saveData() }
                        
                        if !viewModel.budgetItemLimitEnabled {
                            Text("Developer Mode: Unlimited items enabled")
                                .font(.caption)
                                .foregroundColor(.orange)
                                .padding(.leading)
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(10)
                }
                
                Spacer()
            }
            .padding()
        }
        .onChange(of: selectedItem) {
            Task {
                if let data = try? await selectedItem?.loadTransferable(type: Data.self) {
                    selectedImageData = data
                    viewModel.setUserAvatar(data)
                }
            }
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
            .environmentObject(BudgetViewModel())
            .preferredColorScheme(.dark)
    }
}
