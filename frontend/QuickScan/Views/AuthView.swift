import SwiftUI

// AuthView provides the user interface for login, registration, and API token authentication.
struct AuthView: View {
    @StateObject private var authService = AuthService.shared
    @State private var loginMode: LoginMode = .emailPassword
    @State private var isLoginView = true
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var token = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(.systemBlue).opacity(0.1),
                        Color(.systemBackground)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Header
                        headerView
                        
                        // Mode selector
                        modeSelector
                        
                        // Auth form
                        authForm
                        
                        // Action button
                        actionButton
                        
                        // Toggle between login/register
                        if loginMode == .emailPassword {
                            toggleView
                        }
                        
                        Spacer(minLength: 50)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                }
            }
            .navigationBarHidden(true)
        }
        .alert("Authentication", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
        .onChange(of: authService.authState) { state in
            if case .error(let message) = state {
                alertMessage = message
                showingAlert = true
                isLoading = false
            } else if case .loading = state {
                isLoading = true
            } else {
                isLoading = false
            }
        }
    }
    
    // MARK: - Header
    private var headerView: some View {
        VStack(spacing: 16) {
            Image(systemName: "lock.shield")
                .font(.system(size: 60))
                .foregroundStyle(.blue.gradient)
            
            Text("Welcome to QuickScan")
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            Text(isLoginView ? "Sign in to continue" : "Create your account")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Mode Selector
    private var modeSelector: some View {
        VStack(spacing: 16) {
            Text("Authentication Method")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 0) {
                Button(action: {
                    loginMode = .emailPassword
                }) {
                    HStack {
                        Image(systemName: "envelope")
                        Text("Email & Password")
                    }
                    .font(.subheadline)
                    .foregroundColor(loginMode == .emailPassword ? .white : .blue)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(loginMode == .emailPassword ? Color.blue : Color.clear)
                }
                .buttonStyle(.plain)
                
                Button(action: {
                    loginMode = .token
                }) {
                    HStack {
                        Image(systemName: "key")
                        Text("API Token")
                    }
                    .font(.subheadline)
                    .foregroundColor(loginMode == .token ? .white : .blue)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(loginMode == .token ? Color.blue : Color.clear)
                }
                .buttonStyle(.plain)
            }
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(.blue, lineWidth: 2)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    // MARK: - Auth Form
    private var authForm: some View {
        VStack(spacing: 20) {
            if loginMode == .emailPassword {
                emailPasswordForm
            } else {
                tokenForm
            }
        }
    }
    
    private var emailPasswordForm: some View {
        VStack(spacing: 16) {
            // Email field
            VStack(alignment: .leading, spacing: 8) {
                Text("Email")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                TextField("Enter your email", text: $email)
                    .textFieldStyle(CustomTextFieldStyle())
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
            }
            
            // Password field
            VStack(alignment: .leading, spacing: 8) {
                Text("Password")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                SecureField("Enter your password", text: $password)
                    .textFieldStyle(CustomTextFieldStyle())
            }
            
            // Confirm password (only for registration)
            if !isLoginView {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Confirm Password")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    SecureField("Confirm your password", text: $confirmPassword)
                        .textFieldStyle(CustomTextFieldStyle())
                }
            }
        }
    }
    
    private var tokenForm: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("API Token")
                .font(.subheadline)
                .fontWeight(.medium)
            
            TextField("Enter your API token", text: $token)
                .textFieldStyle(CustomTextFieldStyle())
                .autocapitalization(.none)
                .autocorrectionDisabled()
            
            Text("Use one of these demo tokens:")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 8)
            
            VStack(alignment: .leading, spacing: 4) {
                tokenOption("quickscan-api-token-2024")
                tokenOption("demo-token-12345")
                tokenOption("test-api-key-abcdef")
            }
            .padding(.leading, 8)
        }
    }
    
    private func tokenOption(_ tokenValue: String) -> some View {
        Button(action: {
            token = tokenValue
        }) {
            Text("• \(tokenValue)")
                .font(.caption)
                .foregroundColor(.blue)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Action Button
    private var actionButton: some View {
        Button(action: {
            performAuth()
        }) {
            HStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: getActionIcon())
                        .font(.title3)
                }
                
                Text(getActionTitle())
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [.blue, .blue.opacity(0.8)]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(16)
            .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .disabled(isLoading || !isFormValid())
        .opacity(isLoading || !isFormValid() ? 0.6 : 1.0)
        .buttonStyle(.plain)
    }
    
    // MARK: - Toggle View
    private var toggleView: some View {
        HStack {
            Text(isLoginView ? "Don't have an account?" : "Already have an account?")
                .foregroundColor(.secondary)
            
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isLoginView.toggle()
                    clearForm()
                }
            }) {
                Text(isLoginView ? "Sign Up" : "Sign In")
                    .foregroundColor(.blue)
                    .fontWeight(.semibold)
            }
        }
        .font(.subheadline)
    }
    
    // MARK: - Helper Methods
    
    private func getActionTitle() -> String {
        switch loginMode {
        case .emailPassword:
            return isLoginView ? "Sign In" : "Create Account"
        case .token:
            return "Authenticate with Token"
        }
    }
    
    private func getActionIcon() -> String {
        switch loginMode {
        case .emailPassword:
            return isLoginView ? "arrow.right.circle" : "person.badge.plus"
        case .token:
            return "key.fill"
        }
    }
    
    private func isFormValid() -> Bool {
        switch loginMode {
        case .emailPassword:
            if isLoginView {
                return !email.isEmpty && !password.isEmpty
            } else {
                return !email.isEmpty && !password.isEmpty && !confirmPassword.isEmpty && password == confirmPassword
            }
        case .token:
            return !token.isEmpty
        }
    }
    
    private func clearForm() {
        email = ""
        password = ""
        confirmPassword = ""
        token = ""
    }
    
    private func performAuth() {
        Task {
            do {
                switch loginMode {
                case .emailPassword:
                    if isLoginView {
                        _ = try await authService.login(email: email, password: password)
                    } else {
                        _ = try await authService.register(email: email, password: password, confirmPassword: confirmPassword)
                    }
                case .token:
                    _ = try await authService.loginWithToken(token)
                }
            } catch {
                // Error handled by authService state change
            }
        }
    }
}

// MARK: - Custom Text Field Style
struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(.systemGray4), lineWidth: 1)
            )
    }
}

// MARK: - Preview
struct AuthView_Previews: PreviewProvider {
    static var previews: some View {
        AuthView()
    }
} 