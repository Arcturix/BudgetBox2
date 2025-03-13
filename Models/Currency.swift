import Foundation

enum Currency: String, Codable, Hashable, CaseIterable {
    case usd = "USD"
    case eur = "EUR"
    case gbp = "GBP"
    case jpy = "JPY"
    
    var symbol: String {
        switch self {
        case .usd: return "$"
        case .eur: return "€"
        case .gbp: return "£"
        case .jpy: return "¥"
        }
    }
    
    // Conversion rates dictionary (centralized conversion logic)
    static let conversionRates: [Currency: [Currency: Double]] = [
        .usd: [.eur: 0.85, .gbp: 0.75, .jpy: 110.0],
        .eur: [.usd: 1.18, .gbp: 0.88, .jpy: 129.5],
        .gbp: [.usd: 1.33, .eur: 1.14, .jpy: 147.0],
        .jpy: [.usd: 0.009, .eur: 0.0077, .gbp: 0.0068]
    ]
    
    // Helper method to convert between currencies
    static func convert(amount: Double, from: Currency, to: Currency) -> Double {
        if from == to { return amount }
        
        if let rate = conversionRates[from]?[to] {
            return amount * rate
        }
        return amount // Default fallback
    }
}
