import Foundation
import Security

/// KeychainManager provides secure storage and retrieval of sensitive data (like JWT tokens) using the iOS Keychain.
class KeychainManager {
    static let shared = KeychainManager()
    
    private init() {}
    
    // MARK: - Constants
    private let serviceName = "com.quickscan.app"
    private let jwtTokenAccount = "jwt_token"
    
    // MARK: - Public Methods
    
    /// Save JWT token to Keychain
    /// - Parameter token: The JWT token to save
    /// - Returns: True if successful, false otherwise
    @discardableResult
    func saveJWTToken(_ token: String) -> Bool {
        return save(token, account: jwtTokenAccount)
    }
    
    /// Retrieve JWT token from Keychain
    /// - Returns: The stored JWT token or nil if not found
    func getJWTToken() -> String? {
        return retrieve(account: jwtTokenAccount)
    }
    
    /// Delete JWT token from Keychain
    /// - Returns: True if successful, false otherwise
    @discardableResult
    func deleteJWTToken() -> Bool {
        return delete(account: jwtTokenAccount)
    }
    
    // MARK: - Private Methods
    
    /// Save a string value to Keychain
    /// - Parameters:
    ///   - value: The string value to save
    ///   - account: The account identifier
    /// - Returns: True if successful, false otherwise
    private func save(_ value: String, account: String) -> Bool {
        guard let data = value.data(using: .utf8) else {
            print("KeychainManager: Failed to convert string to data")
            return false
        }
        
        // Delete any existing item first
        delete(account: account)
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status == errSecSuccess {
            print("KeychainManager: Successfully saved item for account: \(account)")
            return true
        } else {
            print("KeychainManager: Failed to save item for account: \(account), status: \(status)")
            return false
        }
    }
    
    /// Retrieve a string value from Keychain
    /// - Parameter account: The account identifier
    /// - Returns: The stored string value or nil if not found
    private func retrieve(account: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecSuccess {
            if let data = result as? Data,
               let string = String(data: data, encoding: .utf8) {
                print("KeychainManager: Successfully retrieved item for account: \(account)")
                return string
            } else {
                print("KeychainManager: Failed to convert data to string for account: \(account)")
                return nil
            }
        } else if status == errSecItemNotFound {
            print("KeychainManager: Item not found for account: \(account)")
            return nil
        } else {
            print("KeychainManager: Failed to retrieve item for account: \(account), status: \(status)")
            return nil
        }
    }
    
    /// Delete an item from Keychain
    /// - Parameter account: The account identifier
    /// - Returns: True if successful, false otherwise
    private func delete(account: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: account
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        if status == errSecSuccess || status == errSecItemNotFound {
            print("KeychainManager: Successfully deleted item for account: \(account)")
            return true
        } else {
            print("KeychainManager: Failed to delete item for account: \(account), status: \(status)")
            return false
        }
    }
    
    /// Check if a JWT token exists in Keychain
    /// - Returns: True if token exists, false otherwise
    func hasJWTToken() -> Bool {
        return getJWTToken() != nil
    }
    
    /// Clear all stored data for this app
    /// - Returns: True if successful, false otherwise
    @discardableResult
    func clearAll() -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        if status == errSecSuccess || status == errSecItemNotFound {
            print("KeychainManager: Successfully cleared all items")
            return true
        } else {
            print("KeychainManager: Failed to clear all items, status: \(status)")
            return false
        }
    }
}

// MARK: - Keychain Error Handling
extension KeychainManager {
    enum KeychainError: Error, LocalizedError {
        case conversionError
        case saveError(OSStatus)
        case retrieveError(OSStatus)
        case deleteError(OSStatus)
        
        var errorDescription: String? {
            switch self {
            case .conversionError:
                return "Failed to convert data"
            case .saveError(let status):
                return "Failed to save to Keychain: \(status)"
            case .retrieveError(let status):
                return "Failed to retrieve from Keychain: \(status)"
            case .deleteError(let status):
                return "Failed to delete from Keychain: \(status)"
            }
        }
    }
} 