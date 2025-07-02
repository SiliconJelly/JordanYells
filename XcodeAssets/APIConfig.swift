import Foundation
import Security

class APIConfig {
    static let shared = APIConfig()
    private let keychainService = "com.jordanyells.gemini"
    private let keychainAccount = "gemini-api-key"
    
    private init() {}
    
    var geminiAPIKey: String? {
        get {
            // First try to get from keychain
            if let key = getFromKeychain() {
                return key
            }
            
            // Fallback to environment variable (for development)
            return ProcessInfo.processInfo.environment["GEMINI_API_KEY"]
        }
        set {
            if let newValue = newValue {
                saveToKeychain(newValue)
            } else {
                deleteFromKeychain()
            }
        }
    }
    
    private func getFromKeychain() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let key = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return key
    }
    
    private func saveToKeychain(_ key: String) {
        guard let data = key.data(using: .utf8) else { return }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecValueData as String: data
        ]
        
        // Delete existing item first
        SecItemDelete(query as CFDictionary)
        
        // Add new item
        SecItemAdd(query as CFDictionary, nil)
    }
    
    private func deleteFromKeychain() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount
        ]
        
        SecItemDelete(query as CFDictionary)
    }
} 