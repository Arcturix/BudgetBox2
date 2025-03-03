import SwiftUI

@main
struct BudgetBoxApp: App {
    @StateObject private var budgetViewModel = BudgetViewModel()
    
    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(budgetViewModel)
                .preferredColorScheme(.dark)
                .onAppear {
                    // Hide keyboard when tapped outside of text field
                    UITapGestureRecognizer.endEditingOnTap()
                }
        }
    }
}

// Extension to hide keyboard when tapping outside text fields
extension UITapGestureRecognizer {
    static func endEditingOnTap() {
        let tapGesture = UITapGestureRecognizer(target: UIApplication.shared, action: #selector(UIApplication.endEditing))
        tapGesture.cancelsTouchesInView = false
        tapGesture.delegate = TapGestureDelegate.shared
        
        // Get the key window using UIWindowScene instead of deprecated windows property
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else { return }
        
        window.addGestureRecognizer(tapGesture)
    }
}

// Delegate to ensure proper handling of tap gestures
class TapGestureDelegate: NSObject, UIGestureRecognizerDelegate {
    static let shared = TapGestureDelegate()
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

// Extension for UIApplication to end editing
extension UIApplication {
    @objc func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
