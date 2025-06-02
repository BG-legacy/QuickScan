import Foundation
import SwiftUI

@MainActor
class AuthService: ObservableObject {
    static let shared = AuthService()
    
    @Published var authState: AuthState = .unauthenticated
    @Published var currentUser: User?
    
    private let baseURL = "http://127.0.0.1:3000/api"
    private let session = URLSession.shared
    private let keychainManager = KeychainManager.shared
    
    private init() {
        // Migrate token from UserDefaults to Keychain if needed (one-time migration)
        migrateTokenFromUserDefaults()
        
        // Check for stored token on initialization
        loadStoredToken()
    }
    
    // MARK: - Token Management
    
    private func saveToken(_ token: String) {
        let success = keychainManager.saveJWTToken(token)
        if !success {
            print("AuthService: Failed to save JWT token to Keychain")
        }
    }
    
    private func getStoredToken() -> String? {
        return keychainManager.getJWTToken()
    }
    
    private func clearStoredToken() {
        let success = keychainManager.deleteJWTToken()
        if !success {
            print("AuthService: Failed to delete JWT token from Keychain")
        }
    }
    
    private func loadStoredToken() {
        guard let token = getStoredToken() else {
            authState = .unauthenticated
            return
        }
        
        // Verify the stored token
        Task {
            do {
                let user = try await verifyToken(token)
                authState = .authenticated(user)
                currentUser = user
            } catch {
                // Token is invalid, clear it
                clearStoredToken()
                authState = .unauthenticated
            }
        }
    }
    
    // MARK: - Authentication Methods
    
    func register(email: String, password: String, confirmPassword: String) async throws -> User {
        authState = .loading
        
        let url = URL(string: "\(baseURL)/auth/register")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody = RegisterRequest(
            email: email,
            password: password,
            confirmPassword: confirmPassword
        )
        request.httpBody = try JSONEncoder().encode(requestBody)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            authState = .error("Invalid response")
            throw APIServiceError.invalidResponse
        }
        
        if httpResponse.statusCode != 200 {
            let errorMessage = try? JSONDecoder().decode(APIResponse<String>.self, from: data)
            let message = errorMessage?.error?.message ?? "Registration failed"
            authState = .error(message)
            throw APIServiceError.serverError(message)
        }
        
        let authResponse = try JSONDecoder().decode(APIResponse<AuthResponse>.self, from: data)
        
        guard let auth = authResponse.data else {
            authState = .error("No data received")
            throw APIServiceError.noData
        }
        
        // Save token and update state
        saveToken(auth.token)
        authState = .authenticated(auth.user)
        currentUser = auth.user
        
        return auth.user
    }
    
    func login(email: String, password: String) async throws -> User {
        authState = .loading
        
        let url = URL(string: "\(baseURL)/auth/login")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody = LoginRequest(email: email, password: password)
        request.httpBody = try JSONEncoder().encode(requestBody)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            authState = .error("Invalid response")
            throw APIServiceError.invalidResponse
        }
        
        if httpResponse.statusCode != 200 {
            let errorMessage = try? JSONDecoder().decode(APIResponse<String>.self, from: data)
            let message = errorMessage?.error?.message ?? "Login failed"
            authState = .error(message)
            throw APIServiceError.serverError(message)
        }
        
        let authResponse = try JSONDecoder().decode(APIResponse<AuthResponse>.self, from: data)
        
        guard let auth = authResponse.data else {
            authState = .error("No data received")
            throw APIServiceError.noData
        }
        
        // Save token and update state
        saveToken(auth.token)
        authState = .authenticated(auth.user)
        currentUser = auth.user
        
        return auth.user
    }
    
    func loginWithToken(_ token: String) async throws -> User {
        authState = .loading
        
        let url = URL(string: "\(baseURL)/auth/token")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody = TokenLoginRequest(token: token)
        request.httpBody = try JSONEncoder().encode(requestBody)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            authState = .error("Invalid response")
            throw APIServiceError.invalidResponse
        }
        
        if httpResponse.statusCode != 200 {
            let errorMessage = try? JSONDecoder().decode(APIResponse<String>.self, from: data)
            let message = errorMessage?.error?.message ?? "Token authentication failed"
            authState = .error(message)
            throw APIServiceError.serverError(message)
        }
        
        let authResponse = try JSONDecoder().decode(APIResponse<AuthResponse>.self, from: data)
        
        guard let auth = authResponse.data else {
            authState = .error("No data received")
            throw APIServiceError.noData
        }
        
        // Save JWT token and update state
        saveToken(auth.token)
        authState = .authenticated(auth.user)
        currentUser = auth.user
        
        return auth.user
    }
    
    func verifyToken(_ token: String) async throws -> User {
        let url = URL(string: "\(baseURL)/auth/me")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIServiceError.invalidResponse
        }
        
        if httpResponse.statusCode != 200 {
            throw APIServiceError.serverError("Token verification failed")
        }
        
        let userResponse = try JSONDecoder().decode(APIResponse<User>.self, from: data)
        
        guard let user = userResponse.data else {
            throw APIServiceError.noData
        }
        
        return user
    }
    
    func logout() {
        clearStoredToken()
        authState = .unauthenticated
        currentUser = nil
    }
    
    // MARK: - Helper Methods
    
    var isAuthenticated: Bool {
        if case .authenticated = authState {
            return true
        }
        return false
    }
    
    var isLoading: Bool {
        if case .loading = authState {
            return true
        }
        return false
    }
    
    func getAuthToken() -> String? {
        return getStoredToken()
    }
    
    /// Check if there's a stored token in Keychain
    var hasStoredToken: Bool {
        return keychainManager.hasJWTToken()
    }
    
    /// Migrate existing UserDefaults token to Keychain (one-time migration)
    func migrateTokenFromUserDefaults() {
        let userDefaultsKey = "quickscan_jwt_token"
        
        // Check if there's a token in UserDefaults
        if let oldToken = UserDefaults.standard.string(forKey: userDefaultsKey) {
            // Save it to Keychain
            saveToken(oldToken)
            
            // Remove from UserDefaults
            UserDefaults.standard.removeObject(forKey: userDefaultsKey)
            
            print("AuthService: Successfully migrated JWT token from UserDefaults to Keychain")
        }
    }
} 