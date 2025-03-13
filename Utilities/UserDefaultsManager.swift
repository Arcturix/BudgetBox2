import Foundation

class UserDefaultsManager {
    // Generic save method for any Codable type
    func save<T: Encodable>(_ data: T, key: String) {
        if let encoded = try? JSONEncoder().encode(data) {
            UserDefaults.standard.set(encoded, forKey: key)
        }
    }
    
    // Generic load method for any Codable type
    func load<T: Decodable>(key: String) -> T? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }
    
    // Convenience method for simple types
    func saveValue<T>(_ value: T, key: String) {
        UserDefaults.standard.set(value, forKey: key)
    }
    
    // Convenience method for simple types
    func loadValue<T>(key: String, defaultValue: T) -> T {
        return UserDefaults.standard.object(forKey: key) as? T ?? defaultValue
    }
}
