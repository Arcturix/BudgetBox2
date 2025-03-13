import Foundation
import UserNotifications

class NotificationService {
    static let shared = NotificationService()
    
    private init() {}
    
    func requestPermissions(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                completion(granted)
            }
            
            if let error = error {
                print("Notification permission error: \(error)")
            }
        }
    }
    
    func scheduleNotification(for expense: Expense, budgetName: String) {
        // Only proceed if expense has a reminder
        guard let reminder = expense.reminder else { return }
        
        // Remove any existing notifications for this expense
        cancelNotification(for: expense.id)
        
        // Create notification content
        let content = createNotificationContent(expense: expense, budgetName: budgetName)
        
        // Create trigger based on reminder date and frequency
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminder.date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        // Create and add the request
        let request = UNNotificationRequest(
            identifier: "expense-\(expense.id.uuidString)",
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request)
        
        // For repeating reminders, schedule future notifications
        if reminder.frequency != .once {
            scheduleRepeatingNotifications(for: expense, budgetName: budgetName, initialDate: reminder.date, frequency: reminder.frequency)
        }
    }
    
    private func createNotificationContent(expense: Expense, budgetName: String) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = "Expense Reminder: \(expense.name)"
        content.body = "Budget: \(budgetName) • Amount: \(expense.currency.symbol)\(String(format: "%.2f", expense.amount))"
        content.sound = .default
        return content
    }
    
    private func scheduleRepeatingNotifications(for expense: Expense, budgetName: String, initialDate: Date, frequency: Reminder.Frequency) {
        // Schedule up to 10 future notifications
        var nextDate = initialDate
        
        for i in 1...10 {
            // Calculate next date based on frequency
            nextDate = calculateNextDate(from: initialDate, frequency: frequency, iteration: i)
            
            // Create notification content
            let content = createNotificationContent(expense: expense, budgetName: budgetName)
            
            // Create trigger based on date
            let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: nextDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            
            // Create request with unique identifier for each recurring notification
            let request = UNNotificationRequest(
                identifier: "expense-\(expense.id.uuidString)-\(i)",
                content: content,
                trigger: trigger
            )
            UNUserNotificationCenter.current().add(request)
        }
    }
    
    private func calculateNextDate(from initialDate: Date, frequency: Reminder.Frequency, iteration: Int) -> Date {
        let calendar = Calendar.current
        let component: Calendar.Component
        
        switch frequency {
        case .daily:
            component = .day
        case .weekly:
            component = .weekOfYear
        case .monthly:
            component = .month
        case .yearly:
            component = .year
        case .once:
            return initialDate
        }
        
        return calendar.date(byAdding: component, value: iteration, to: initialDate) ?? initialDate
    }
    
    func cancelNotification(for expenseId: UUID) {
        // Remove the main notification
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["expense-\(expenseId.uuidString)"])
        
        // Remove any recurring notifications
        for i in 1...10 {
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["expense-\(expenseId.uuidString)-\(i)"])
        }
    }
    
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}
