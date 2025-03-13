import SwiftUI
import Combine

// Protocol for reactive state updates
protocol ReactiveStateUpdate {
    var stateUpdatePublisher: PassthroughSubject<UUID, Never> { get }
}

// Extension for View to subscribe to reactive state updates
extension View {
    func onReactiveStateUpdate<T: ReactiveStateUpdate>(from source: T, perform action: @escaping () -> Void) -> some View {
        self.onReceive(source.stateUpdatePublisher) { _ in
            action()
        }
    }
}

// Extension for BudgetViewModel to make it a reactive state source
extension BudgetViewModel: ReactiveStateUpdate {
    var stateUpdatePublisher: PassthroughSubject<UUID, Never> {
        if _stateUpdatePublisher == nil {
            _stateUpdatePublisher = PassthroughSubject<UUID, Never>()
        }
        return _stateUpdatePublisher!
    }
    
    func triggerStateUpdate(for budgetId: UUID) {
        DispatchQueue.main.async {
            self.stateUpdatePublisher.send(budgetId)
            // Also post notification for backward compatibility
            NotificationCenter.default.post(
                name: NSNotification.Name("ForceRefreshBudget"),
                object: nil,
                userInfo: ["budgetId": budgetId]
            )
        }
    }
}
