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
        let content = UNMutableNotificationContent()
        content.title = "Expense Reminder: \(expense.name)"
        content.body = "Budget: \(budgetName) • Amount: \(expense.currency.symbol)\(String(format: "%.2f", expense.amount))"
        content.sound = .default
        
        // Create trigger based on reminder date and frequency
        var components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminder.date)
        
        // Create the initial trigger
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        // Create and add the request
        let request = UNNotificationRequest(identifier: "expense-\(expense.id.uuidString)", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
        
        // For repeating reminders, schedule future notifications
        if reminder.frequency != .once {
            scheduleRepeatingNotifications(for: expense, budgetName: budgetName, initialDate: reminder.date, frequency: reminder.frequency)
        }
    }
    
    private func scheduleRepeatingNotifications(for expense: Expense, budgetName: String, initialDate: Date, frequency: Reminder.Frequency) {
        // Schedule up to 10 future notifications
        var nextDate = initialDate
        
        for i in 1...10 {
            // Calculate next date based on frequency
            switch frequency {
            case .daily:
                nextDate = Calendar.current.date(byAdding: .day, value: i, to: initialDate) ?? nextDate
            case .weekly:
                nextDate = Calendar.current.date(byAdding: .weekOfYear, value: i, to: initialDate) ?? nextDate
            case .monthly:
                nextDate = Calendar.current.date(byAdding: .month, value: i, to: initialDate) ?? nextDate
            case .yearly:
                nextDate = Calendar.current.date(byAdding: .year, value: i, to: initialDate) ?? nextDate
            case .once:
                return // Just to be safe, should never happen
            }
            
            // Create notification content
            let content = UNMutableNotificationContent()
            content.title = "Expense Reminder: \(expense.name)"
            content.body = "Budget: \(budgetName) • Amount: \(expense.currency.symbol)\(String(format: "%.2f", expense.amount))"
            content.sound = .default
            
            // Create trigger based on date
            let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: nextDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            
            // Create request with unique identifier for each recurring notification
            let request = UNNotificationRequest(identifier: "expense-\(expense.id.uuidString)-\(i)", content: content, trigger: trigger)
            UNUserNotificationCenter.current().add(request)
        }
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
