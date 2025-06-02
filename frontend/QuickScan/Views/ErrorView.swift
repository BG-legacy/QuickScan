import SwiftUI

// ErrorView displays an error message and provides retry and dismiss actions for error handling in the app.
struct ErrorView: View {
    let message: String
    let onRetry: () -> Void
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 24) {
            // Error icon with animation
            ZStack {
                Circle()
                    .fill(Color.red.opacity(0.1))
                    .frame(width: 100, height: 100)
                    .scaleEffect(isAnimating ? 1.2 : 1.0)
                    .animation(
                        .easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                        value: isAnimating
                    )
                
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(.red.gradient)
            }
            
            // Error message
            VStack(spacing: 12) {
                Text("Something went wrong")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(message)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            // Action buttons
            VStack(spacing: 12) {
                Button(action: onRetry) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                            .font(.headline)
                        Text("Try Again")
                            .font(.headline)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [.red, .red.opacity(0.8)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                }
                .buttonStyle(.plain)
                
                Button("Dismiss") {
                    onRetry()
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
            }
            .padding(.horizontal, 20)
        }
        .padding(30)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 40) {
        ErrorView(message: "Failed to upload file. Please check your internet connection and try again.") {
            print("Retry tapped")
        }
        
        ErrorView(message: "Network timeout. Please try again.") {
            print("Retry tapped")
        }
        
        ErrorView(message: "Invalid file format. Please select a supported document type.") {
            print("Retry tapped")
        }
    }
    .padding()
    .background(Color(.systemGroupedBackground))
} 