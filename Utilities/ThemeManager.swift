import SwiftUI

struct ThemeManager {
    enum ColorSchemeSelection: Int {
        case system = 0
        case light = 1
        case dark = 2
        
        var title: String {
            switch self {
            case .system: return "System"
            case .light: return "Light"
            case .dark: return "Dark"
            }
        }
        
        var icon: String {
            switch self {
            case .system: return "iphone"
            case .light: return "sun.max.fill"
            case .dark: return "moon.fill"
            }
        }
    }
    
    // App colors that adapt based on color scheme
    struct Colors {
        // Background colors
        static let primary = Color("PrimaryBackground")
        static let secondary = Color("SecondaryBackground")
        static let tertiary = Color("TertiaryBackground")
        
        // Text colors
        static let primaryText = Color("PrimaryText")
        static let secondaryText = Color("SecondaryText")
        
        // Accent colors
        static let accent = Color("AccentColor")
        static let secondaryAccent = Color("SecondaryAccent")
        
        // Convert hex to Color
        static func fromHex(_ hex: String) -> Color {
            return Color(hex: hex)
        }
    }
}

// Extension to View for easily applying common background colors
extension View {
    func primaryBackground() -> some View {
        self.background(ThemeManager.Colors.primary)
    }
    
    func secondaryBackground() -> some View {
        self.background(ThemeManager.Colors.secondary)
    }
}
