import SwiftUI

struct LoadingView: View {
    let message: String
    @State private var isAnimating = false
    @State private var dotCount = 0
    
    let timer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack(spacing: 24) {
            // Animated loading indicator
            ZStack {
                Circle()
                    .stroke(Color(.systemGray5), lineWidth: 8)
                    .frame(width: 80, height: 80)
                
                Circle()
                    .trim(from: 0, to: 0.3)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [.blue, .purple]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(isAnimating ? 360 : 0))
                    .animation(
                        .linear(duration: 1.5).repeatForever(autoreverses: false),
                        value: isAnimating
                    )
            }
            
            // Loading message with animated dots
            VStack(spacing: 8) {
                Text(message)
                    .font(.headline)
                    .fontWeight(.medium)
                
                Text(String(repeating: ".", count: dotCount))
                    .font(.title2)
                    .foregroundStyle(.blue.gradient)
                    .frame(height: 20)
            }
            
            // Pulsing background effect
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemGray6))
                .frame(height: 4)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(LinearGradient(
                            gradient: Gradient(colors: [.blue.opacity(0.3), .purple.opacity(0.3)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                        .scaleEffect(x: isAnimating ? 1 : 0.1, anchor: .leading)
                        .animation(
                            .easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                            value: isAnimating
                        )
                )
                .padding(.horizontal, 40)
        }
        .padding(40)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
        .onAppear {
            isAnimating = true
        }
        .onReceive(timer) { _ in
            dotCount = (dotCount + 1) % 4
        }
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 40) {
        LoadingView(message: "Processing...")
        LoadingView(message: "Generating summary...")
        LoadingView(message: "Uploading file...")
    }
    .padding()
    .background(Color(.systemGroupedBackground))
} 