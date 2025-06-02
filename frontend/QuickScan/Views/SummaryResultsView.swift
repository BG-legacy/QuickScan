import SwiftUI

// SummaryResultsView displays the AI-generated summary, statistics, and sharing options for a processed document.
struct SummaryResultsView: View {
    let result: SummarizationResult
    let onDone: () -> Void
    @State private var isExpanded = false
    @State private var showingShareSheet = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                headerView
                
                // Summary Card
                summaryCard
                
                // Statistics
                statisticsView
                
                // Original Content (Expandable)
                originalContentView
                
                // Action Buttons
                actionButtons
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .background(Color(.systemGroupedBackground))
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(items: [result.summary])
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [.green, .blue]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 35))
                    .foregroundColor(.white)
            }
            
            VStack(spacing: 8) {
                Text("Summary Complete")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("AI-powered document summary")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.top, 20)
    }
    
    // MARK: - Summary Card
    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "doc.text")
                    .font(.title2)
                    .foregroundStyle(.blue.gradient)
                
                Text("Summary")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button(action: {
                    showingShareSheet = true
                }) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.title3)
                        .foregroundColor(.blue)
                }
            }
            
            Text(result.summary)
                .font(.body)
                .lineSpacing(6)
                .padding(.leading, 8)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    // MARK: - Statistics View
    private var statisticsView: some View {
        HStack(spacing: 16) {
            StatisticCard(
                title: "Original",
                value: "\(result.originalLength)",
                subtitle: "characters",
                color: .orange
            )
            
            StatisticCard(
                title: "Summary",
                value: "\(result.summaryLength)",
                subtitle: "characters",
                color: .green
            )
            
            StatisticCard(
                title: "Reduction",
                value: "\(Int((1.0 - Double(result.summaryLength) / Double(result.originalLength)) * 100))%",
                subtitle: "compressed",
                color: .blue
            )
        }
    }
    
    // MARK: - Original Content View
    private var originalContentView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Button(action: {
                withAnimation(.spring()) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Image(systemName: "doc.plaintext")
                        .font(.title2)
                        .foregroundStyle(.gray.gradient)
                    
                    Text("Original Content")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.title3)
                        .foregroundColor(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                        .animation(.spring(), value: isExpanded)
                }
            }
            .buttonStyle(.plain)
            
            if isExpanded {
                ScrollView {
                    Text(result.originalContent)
                        .font(.body)
                        .lineSpacing(4)
                        .padding(.leading, 8)
                }
                .frame(maxHeight: 200)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    // MARK: - Action Buttons
    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button(action: {
                showingShareSheet = true
            }) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                        .font(.headline)
                    Text("Share Summary")
                        .font(.headline)
                        .fontWeight(.medium)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [.blue, .blue.opacity(0.8)]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
            }
            .buttonStyle(.plain)
            
            Button("Done") {
                onDone()
            }
            .font(.subheadline)
            .foregroundColor(.secondary)
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Statistic Card Component
struct StatisticCard: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .fontWeight(.medium)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(color.gradient)
            
            Text(subtitle)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 1)
        )
    }
}

// MARK: - Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Preview
#Preview {
    SummaryResultsView(
        result: SummarizationResult(
            id: "preview-id",
            originalContent: "This is a very long document with lots of details about various topics that need to be summarized for easier reading and understanding. It contains multiple paragraphs and detailed explanations.",
            summary: "This document contains details about various topics that need summarization for easier reading.",
            originalLength: 150,
            summaryLength: 85,
            timestamp: "2024-01-01T12:00:00Z"
        )
    ) {
        print("Done tapped")
    }
} 