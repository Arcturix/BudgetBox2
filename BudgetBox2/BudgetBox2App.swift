// BudgetBox2/BudgetBoxApp.swift

import SwiftUI

@main
struct BudgetBoxApp: App {
    @StateObject private var budgetViewModel = BudgetViewModel()
    @AppStorage("colorScheme") private var colorScheme: Int = 0 // 0: system, 1: light, 2: dark
    @State private var notificationPermissionRequested = false
    
    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(budgetViewModel)
                .preferredColorScheme(colorSchemeValue)
                .onAppear {
                    // Hide keyboard when tapped outside of text field
                    UITapGestureRecognizer.endEditingOnTap()
                    
                    // Request notification permissions if not done yet
                    if !notificationPermissionRequested {
                        NotificationService.shared.requestPermissions { granted in
                            if granted {
                                self.budgetViewModel.scheduleNotifications()
                            }
                            notificationPermissionRequested = true
                        }
                    }
                }
        }
    }
    
    var colorSchemeValue: ColorScheme? {
        switch colorScheme {
        case 1: return .light
        case 2: return .dark
        default: return nil // System default
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
