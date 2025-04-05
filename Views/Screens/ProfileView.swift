import SwiftUI
import PhotosUI
import MessageUI
import StoreKit

// Define product identifiers for in-app purchases
enum ProductIdentifier: String, CaseIterable {
    case smallCoffee = "com.jazworrell.BudgetBox2.smallCoffee"
    case mediumCoffee = "com.jazworrell.BudgetBox2.mediumCoffee"
    case largeCoffee = "com.jazworrell.BudgetBox2.largeCoffee"
}

struct ProfileView: View {
    @EnvironmentObject var viewModel: BudgetViewModel
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImageData: Data?
    @State private var selectedLoanCurrency: Currency = .usd
    @State private var isShowingMailView = false
    @State private var mailResult: Result<MFMailComposeResult, Error>?
    @State private var showMailAlert = false
    
    // For in-app purchases
    @State private var showingCoffeeOptions = false
    @State private var isPurchasing = false
    @State private var purchaseError: String?
    @State private var showPurchaseError = false
    @State private var showPurchaseSuccess = false
    
    var body: some View {
        ZStack {
            Color(hex: "383C51")
                .ignoresSafeArea()
            
            ScrollView {
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
                        .toggleStyle(SwitchToggleStyle(tint: Color(hex: "FD5E7D")))
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(10)
                        .onChange(of: viewModel.showValuesEnabled) { viewModel.saveData() }
                        
                        // Student Loan Section
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Loan Tracker")
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
                        
                        // Buy Me a Coffee Section
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Support the Developer")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                Image(systemName: "heart.fill")
                                    .foregroundColor(.pink)
                            }
                            
                            Text("Enjoying BudgetBox? Consider buying me a coffee to support ongoing development!")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .padding(.vertical, 4)
                            
                            Button(action: {
                                showingCoffeeOptions = true
                            }) {
                                HStack {
                                    Image(systemName: "cup.and.saucer.fill")
                                    Text("Buy Me a Coffee")
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(hex: "FF5E7D"))
                                .cornerRadius(10)
                            }
                            .actionSheet(isPresented: $showingCoffeeOptions) {
                                ActionSheet(
                                    title: Text("Support BudgetBox"),
                                    message: Text("Choose a donation amount"),
                                    buttons: [
                                        .default(Text("Small Coffee (€1.99)")) {
                                            makePurchase(.smallCoffee)
                                        },
                                        .default(Text("Medium Coffee (€4.99)")) {
                                            makePurchase(.mediumCoffee)
                                        },
                                        .default(Text("Large Coffee (€9.99)")) {
                                            makePurchase(.largeCoffee)
                                        },
                                        .cancel()
                                    ]
                                )
                            }
                            .alert("Purchase Error", isPresented: $showPurchaseError) {
                                Button("OK", role: .cancel) { }
                            } message: {
                                Text(purchaseError ?? "An unknown error occurred.")
                            }
                            .alert("Thank You!", isPresented: $showPurchaseSuccess) {
                                Button("You're Welcome!", role: .cancel) { }
                            } message: {
                                Text("Your support means a lot! Enjoy your BudgetBox experience.")
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(10)
                        
                        // Feedback Section - simplified to direct email
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Send Feedback")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Text("We'd love to hear your thoughts on BudgetBox! Tap the button below to send us an email with your feedback.")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .padding(.vertical, 4)
                            
                            Button(action: {
                                // First check if mail is available on the device
                                if MFMailComposeViewController.canSendMail() {
                                    // Try to open mail composer directly first
                                    let composeVC = MFMailComposeViewController()
                                    composeVC.setToRecipients(["budgetbox1app@gmail.com"])
                                    composeVC.setSubject("BudgetBox App Feedback")
                                    // Present mail composer would go here, but we can't do that from a button action
                                    // Instead, try the URL method as fallback
                                    if let emailURL = createEmailURL(), UIApplication.shared.canOpenURL(emailURL) {
                                        UIApplication.shared.open(emailURL)
                                    } else {
                                        showMailAlert = true
                                    }
                                } else {
                                    // If mail composer isn't available, try mailto: URL
                                    if let emailURL = createEmailURL(), UIApplication.shared.canOpenURL(emailURL) {
                                        UIApplication.shared.open(emailURL)
                                    } else {
                                        showMailAlert = true
                                    }
                                }
                            }) {
                                HStack {
                                    Image(systemName: "envelope.fill")
                                    Text("Send Feedback Email")
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(hex: "FD5E7D"))
                                .cornerRadius(10)
                            }
                            .alert(isPresented: $showMailAlert) {
                                Alert(
                                    title: Text("Email Not Available"),
                                    message: Text("Your device is not configured to send emails. Please check your mail settings and try again."),
                                    dismissButton: .default(Text("OK"))
                                )
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
            
            // Loading indicator for purchases
            if isPurchasing {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                
                VStack {
                    ProgressView()
                        .scaleEffect(1.5)
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    
                    Text("Processing Purchase...")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.top)
                }
                .frame(width: 200, height: 100)
                .background(Color(hex: "383C51"))
                .cornerRadius(10)
                .shadow(radius: 10)
            }
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
    
    // Create mailto URL
    private func createEmailURL() -> URL? {
        let recipient = "budgetbox1app@gmail.com"
        let subject = "BudgetBox App Feedback"
        
        // Make sure to properly encode all components
        let encodedRecipient = recipient.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        // Create the mailto URL with proper formatting
        let urlString = "mailto:\(encodedRecipient)?subject=\(encodedSubject)"
        
        return URL(string: urlString)
    }
    
    // Handle in-app purchase
    private func makePurchase(_ product: ProductIdentifier) {
        isPurchasing = true
        
        Task {
            do {
                // Request product from App Store
                let products = try await Product.products(for: [product.rawValue])
                guard let storeProduct = products.first else {
                    isPurchasing = false
                    purchaseError = "Product not found in the App Store."
                    showPurchaseError = true
                    return
                }
                
                // Purchase the product
                let result = try await storeProduct.purchase()
                
                await MainActor.run {
                    isPurchasing = false
                    
                    switch result {
                    case .success(let verification):
                        // Handle successful purchase
                        switch verification {
                        case .verified:
                            // Successful purchase verification
                            showPurchaseSuccess = true
                        case .unverified:
                            // Failed verification
                            purchaseError = "Purchase verification failed."
                            showPurchaseError = true
                        }
                    case .userCancelled:
                        // User canceled the purchase - do nothing
                        break
                    case .pending:
                        // Purchase is pending (e.g., needs parental approval)
                        purchaseError = "Purchase is pending approval."
                        showPurchaseError = true
                    @unknown default:
                        purchaseError = "An unknown error occurred."
                        showPurchaseError = true
                    }
                }
            } catch {
                await MainActor.run {
                    isPurchasing = false
                    purchaseError = error.localizedDescription
                    showPurchaseError = true
                }
            }
        }
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
            .environmentObject(BudgetViewModel())
            .preferredColorScheme(.dark)
    }
}
