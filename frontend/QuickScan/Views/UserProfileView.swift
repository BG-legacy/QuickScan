import SwiftUI

// UserProfileView displays the current user's profile information and provides sign-out functionality.
struct UserProfileView: View {
    @StateObject private var authService = AuthService.shared
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                headerView
                
                // User info card
                userInfoCard
                
                // Actions
                actionButtons
                
                Spacer()
            }
            .padding(20)
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - Header
    private var headerView: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.blue.gradient)
            
            if let user = authService.currentUser {
                Text("Welcome, \(user.email)")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    // MARK: - User Info Card
    private var userInfoCard: some View {
        VStack(spacing: 0) {
            if let user = authService.currentUser {
                userInfoRow(icon: "envelope", title: "Email", value: user.email)
                Divider().padding(.horizontal, 16)
                userInfoRow(icon: "calendar", title: "Member Since", value: formatDate(user.createdAt))
                Divider().padding(.horizontal, 16)
                userInfoRow(icon: "checkmark.shield", title: "Status", value: user.isActive ? "Active" : "Inactive")
            }
        }
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
    
    private func userInfoRow(icon: String, title: String, value: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.body)
                    .fontWeight(.medium)
            }
            
            Spacer()
        }
        .padding(16)
    }
    
    // MARK: - Action Buttons
    private var actionButtons: some View {
        VStack(spacing: 16) {
            // Logout button
            Button(action: {
                authService.logout()
                presentationMode.wrappedValue.dismiss()
            }) {
                HStack {
                    Image(systemName: "arrow.right.square")
                        .font(.title3)
                    Text("Sign Out")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [.red, .red.opacity(0.8)]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(16)
            }
            .buttonStyle(.plain)
            
            // App info
            VStack(spacing: 8) {
                Text("QuickScan v1.0")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text("Secure document scanning and AI analysis")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    // MARK: - Helper Methods
    private func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: dateString) else {
            return dateString
        }
        
        let displayFormatter = DateFormatter()
        displayFormatter.dateStyle = .medium
        return displayFormatter.string(from: date)
    }
}

// MARK: - Preview
struct UserProfileView_Previews: PreviewProvider {
    static var previews: some View {
        UserProfileView()
    }
} 