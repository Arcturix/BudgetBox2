import SwiftUI

@main
struct BudgetBoxApp: App {
    @StateObject private var budgetViewModel = BudgetViewModel()
    
    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(budgetViewModel)
                .preferredColorScheme(.dark)
        }
    }
}
