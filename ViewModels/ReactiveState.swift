import SwiftUI
import Combine

// This protocol can be used to create a reactive state update system
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
    // Access the subject if needed
    var stateUpdatePublisher: PassthroughSubject<UUID, Never> {
        get {
            // Create the subject if needed
            if self._stateUpdatePublisher == nil {
                self._stateUpdatePublisher = PassthroughSubject<UUID, Never>()
            }
            return self._stateUpdatePublisher!
        }
    }
    
    // Trigger a state update for a specific budget
    func triggerStateUpdate(for budgetId: UUID) {
        DispatchQueue.main.async {
            self.stateUpdatePublisher.send(budgetId)
        }
    }
}
