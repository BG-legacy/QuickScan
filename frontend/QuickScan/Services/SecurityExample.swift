import Foundation

/// Example demonstrating secure JWT token storage using KeychainManager
/// This file shows best practices for secure token management in iOS apps
class SecurityExample {
    
    static func demonstrateSecureTokenStorage() {
        let keychainManager = KeychainManager.shared
        
        // Example JWT token (this would normally come from your authentication API)
        let exampleJWTToken = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c"
        
        print("=== Secure JWT Token Storage Example ===")
        
        // 1. Save token securely to Keychain
        print("\n1. Saving JWT token to Keychain...")
        let saveSuccess = keychainManager.saveJWTToken(exampleJWTToken)
        print("   Save result: \(saveSuccess ? "✅ Success" : "❌ Failed")")
        
        // 2. Retrieve token from Keychain
        print("\n2. Retrieving JWT token from Keychain...")
        if let retrievedToken = keychainManager.getJWTToken() {
            print("   Retrieved token: \(String(retrievedToken.prefix(20)))...")
            print("   Token matches: \(retrievedToken == exampleJWTToken ? "✅ Yes" : "❌ No")")
        } else {
            print("   ❌ Failed to retrieve token")
        }
        
        // 3. Check if token exists
        print("\n3. Checking if token exists...")
        let hasToken = keychainManager.hasJWTToken()
        print("   Token exists: \(hasToken ? "✅ Yes" : "❌ No")")
        
        // 4. Delete token
        print("\n4. Deleting JWT token from Keychain...")
        let deleteSuccess = keychainManager.deleteJWTToken()
        print("   Delete result: \(deleteSuccess ? "✅ Success" : "❌ Failed")")
        
        // 5. Verify token was deleted
        print("\n5. Verifying token was deleted...")
        let tokenExistsAfterDelete = keychainManager.hasJWTToken()
        print("   Token exists after delete: \(tokenExistsAfterDelete ? "❌ Still exists" : "✅ Properly deleted")")
        
        print("\n=== Example Complete ===")
    }
    
    static func demonstrateSecurityBenefits() {
        print("\n=== Security Benefits of Keychain Storage ===")
        print("✅ Data is encrypted using device hardware encryption")
        print("✅ Data persists across app uninstalls/reinstalls")
        print("✅ Data is isolated per app (cannot be accessed by other apps)")
        print("✅ Data is protected by device passcode/biometric authentication")
        print("✅ Data is automatically backed up securely with iCloud Keychain")
        print("✅ Much more secure than UserDefaults (plain text storage)")
        print("✅ Follows iOS security best practices")
        print("========================================\n")
    }
    
    static func demonstrateTokenMigration() {
        print("\n=== Token Migration Example ===")
        
        // Simulate old UserDefaults storage
        let oldTokenKey = "quickscan_jwt_token"
        let exampleToken = "old_token_from_userdefaults"
        
        // Store token in UserDefaults (simulating old implementation)
        UserDefaults.standard.set(exampleToken, forKey: oldTokenKey)
        print("1. Stored token in UserDefaults (old method)")
        
        // Migrate to Keychain
        if let oldToken = UserDefaults.standard.string(forKey: oldTokenKey) {
            let keychainManager = KeychainManager.shared
            let saveSuccess = keychainManager.saveJWTToken(oldToken)
            
            if saveSuccess {
                UserDefaults.standard.removeObject(forKey: oldTokenKey)
                print("2. ✅ Successfully migrated token to Keychain")
                print("3. ✅ Removed token from UserDefaults")
            } else {
                print("2. ❌ Failed to migrate token to Keychain")
            }
        }
        
        // Verify migration
        let keychainManager = KeychainManager.shared
        if let migratedToken = keychainManager.getJWTToken() {
            print("4. ✅ Token successfully retrieved from Keychain: \(migratedToken)")
        } else {
            print("4. ❌ Failed to retrieve migrated token")
        }
        
        // Clean up
        keychainManager.deleteJWTToken()
        print("5. ✅ Cleanup complete")
        print("==============================\n")
    }
}

// MARK: - Security Best Practices Documentation
/*
 
 SECURITY BEST PRACTICES FOR JWT TOKEN STORAGE:
 
 1. NEVER store sensitive data in UserDefaults
    - UserDefaults stores data in plain text
    - Data can be easily accessed by debugging tools
    - Data persists in device backups unencrypted
 
 2. ALWAYS use Keychain for sensitive data
    - Hardware-encrypted storage
    - Automatic encryption/decryption
    - Protected by device security (passcode/biometric)
 
 3. Use appropriate Keychain accessibility levels
    - kSecAttrAccessibleWhenUnlockedThisDeviceOnly: Most secure, requires device unlock
    - kSecAttrAccessibleWhenUnlocked: Secure, syncs with iCloud Keychain
    - Avoid kSecAttrAccessibleAlways: Less secure, accessible even when locked
 
 4. Handle migration properly
    - Check for existing tokens in UserDefaults
    - Migrate to Keychain
    - Remove from UserDefaults after successful migration
 
 5. Implement proper error handling
    - Check return values from Keychain operations
    - Handle edge cases (token not found, save failures)
    - Provide fallback authentication if token is corrupted
 
 6. Regular token validation
    - Verify token validity on app launch
    - Handle expired tokens gracefully
    - Implement token refresh if supported by backend
 
 */ 