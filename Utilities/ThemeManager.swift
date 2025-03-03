// Utilities/ThemeManager.swift

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
        
        // Accent colors - these could be static but are made adaptive for future flexibility
        static let accent = Color("AccentColor")
        static let secondaryAccent = Color("SecondaryAccent")
        
        // Alternative to using hex colors directly
        static func fromHex(_ hex: String, darkMode: Bool = false) -> Color {
            // Use the existing hex extension but adjust for dark mode if needed
            if darkMode {
                return Color(hex: adjustHexForDarkMode(hex))
            } else {
                return Color(hex: hex)
            }
        }
        
        // Helper to adjust hex colors for dark mode
        private static func adjustHexForDarkMode(_ hex: String) -> String {
            // This is a simple example - you might want to use a more sophisticated algorithm
            // For now, we're just returning the original hex
            return hex
        }
    }
    
    // Function to get adaptive colors based on a base color/hex
    static func adaptiveColor(hex: String, for colorScheme: ColorScheme) -> Color {
        let baseColor = Color(hex: hex)
        
        // For dark mode, we could brighten or adjust colors
        // This is a simple implementation that just returns the same color
        // You could implement more sophisticated transformations
        return baseColor
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
