import SwiftUI
import PhotosUI

struct ProfileView: View {
    @EnvironmentObject var viewModel: BudgetViewModel
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImageData: Data?
    
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
