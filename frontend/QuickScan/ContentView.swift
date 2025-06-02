import SwiftUI
import VisionKit
import PDFKit

struct ContentView: View {
    @StateObject private var apiService = APIService.shared
    // TEMPORARY: Commenting out AuthService until it's added to the project target
    // @StateObject private var authService = AuthService.shared
    @State private var appState: AppState = .idle
    @State private var documentSource: DocumentSource = .none
    @State private var showingDocumentScanner = false
    @State private var showingFilePicker = false
    @State private var showingUserProfile = false
    @State private var extractedText = ""
    @State private var summaryResult: SummarizationResult?
    @State private var uploadedFile: UploadedFile?
    
    var body: some View {
        // TEMPORARY: Bypassing authentication until AuthService is available
        // Group {
        //     if authService.isAuthenticated {
        //         mainAppView
        //     } else {
        //         AuthView()
        //     }
        // }
        mainAppView
    }
    
    private var mainAppView: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(.systemBackground),
                        Color(.systemBackground).opacity(0.8)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        headerView
                        
                        // Main content based on state
                        switch appState {
                        case .idle:
                            idleStateView
                        case .loading:
                            LoadingView(message: "Processing...")
                        case .fileSelected(_, let filename):
                            fileSelectedView(filename: filename)
                        case .uploadComplete(let file):
                            uploadCompleteView(file: file)
                        case .summarizing:
                            LoadingView(message: "Generating summary...")
                        case .summary(let result):
                            SummaryResultsView(result: result) {
                                resetToIdle()
                            }
                        case .error(let message):
                            ErrorView(message: message) {
                                resetToIdle()
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("QuickScan")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingUserProfile = true
                    }) {
                        Image(systemName: "person.circle")
                            .font(.title3)
                            .foregroundColor(.blue)
                    }
                }
            }
        }
        .sheet(isPresented: $showingDocumentScanner) {
            DocumentScannerView { images in
                handleScannedImages(images)
            }
        }
        .sheet(isPresented: $showingFilePicker) {
            FilePickerView { data, filename in
                handleSelectedFile(data: data, filename: filename)
            }
        }
        // TEMPORARY: Commenting out UserProfileView until it's added to project target
        // .sheet(isPresented: $showingUserProfile) {
        //     UserProfileView()
        // }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 50))
                .foregroundStyle(.blue.gradient)
            
            Text("QuickScan")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Scan documents and get AI-powered summaries")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 20)
    }
    
    // MARK: - Idle State View
    private var idleStateView: some View {
        VStack(spacing: 20) {
            // Action buttons
            VStack(spacing: 16) {
                // Document Scanner Button
                Button(action: {
                    showingDocumentScanner = true
                }) {
                    HStack {
                        Image(systemName: "camera.viewfinder")
                            .font(.title2)
                        Text("Scan Document")
                            .font(.headline)
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
                }
                .buttonStyle(.plain)
                
                // File Picker Button
                Button(action: {
                    showingFilePicker = true
                }) {
                    HStack {
                        Image(systemName: "folder")
                            .font(.title2)
                        Text("Choose File")
                            .font(.headline)
                    }
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color(.systemGray6))
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(.blue, lineWidth: 2)
                    )
                }
                .buttonStyle(.plain)
            }
            
            Divider()
                .padding(.vertical, 8)
            
            // Features list
            VStack(alignment: .leading, spacing: 12) {
                Text("Features")
                    .font(.headline)
                    .padding(.bottom, 4)
                
                FeatureRow(icon: "doc.text.viewfinder", title: "Document Scanning", description: "Use your camera to scan documents")
                FeatureRow(icon: "square.and.arrow.up", title: "File Upload", description: "Choose files from your device")
                FeatureRow(icon: "brain.head.profile", title: "AI Summarization", description: "Get intelligent summaries of your documents")
                FeatureRow(icon: "moon.fill", title: "Dark Mode Support", description: "Looks great in light and dark mode")
            }
            .padding(.horizontal, 4)
        }
    }
    
    // MARK: - File Selected View
    private func fileSelectedView(filename: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.fill")
                .font(.system(size: 60))
                .foregroundStyle(.green.gradient)
            
            Text("File Selected")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text(filename)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            Button("Upload & Process") {
                if case .fileSelected(let data, let filename) = appState {
                    uploadFile(data: data, filename: filename)
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            
            Button("Cancel") {
                resetToIdle()
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }
    
    // MARK: - Upload Complete View
    private func uploadCompleteView(file: UploadedFile) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.green.gradient)
            
            Text("Upload Complete")
                .font(.title2)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("File: \(file.filename)")
                Text("Size: \(file.formattedFileSize)")
                Text("Type: \(file.contentType)")
            }
            .font(.subheadline)
            .foregroundColor(.secondary)
            
            if !extractedText.isEmpty {
                Button("Generate Summary") {
                    generateSummary()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            
            Button("Start Over") {
                resetToIdle()
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }
    
    // MARK: - Helper Functions
    private func handleScannedImages(_ images: [UIImage]) {
        // For now, we'll simulate text extraction
        // In a real app, you'd use Vision framework or other OCR
        extractedText = "This is sample extracted text from the scanned document. In a production app, this would be the actual text extracted from the scanned images using OCR technology."
        
        // Convert first image to data for upload
        if let firstImage = images.first,
           let imageData = firstImage.jpegData(compressionQuality: 0.8) {
            let filename = "scanned_document_\(Date().timeIntervalSince1970).jpg"
            appState = .fileSelected(imageData, filename)
        }
    }
    
    private func handleSelectedFile(data: Data, filename: String) {
        // For text files, extract content directly
        if filename.lowercased().hasSuffix(".txt") {
            extractedText = String(data: data, encoding: .utf8) ?? ""
        } else if filename.lowercased().hasSuffix(".pdf") {
            // Extract text from PDF using PDFKit
            if let pdfDocument = PDFDocument(data: data) {
                var fullText = ""
                let pageCount = pdfDocument.pageCount
                
                for pageIndex in 0..<pageCount {
                    if let page = pdfDocument.page(at: pageIndex) {
                        if let pageText = page.string {
                            fullText += pageText + "\n"
                        }
                    }
                }
                
                extractedText = fullText.trimmingCharacters(in: .whitespacesAndNewlines)
                
                if extractedText.isEmpty {
                    extractedText = "No text could be extracted from this PDF. The document may contain only images or be password protected."
                }
            } else {
                extractedText = "Unable to read PDF file. The file may be corrupted or password protected."
            }
        } else {
            // For other files, we'll need OCR or other processing
            extractedText = "Content extracted from \(filename). In a production app, this would contain the actual extracted text from the file."
        }
        
        appState = .fileSelected(data, filename)
    }
    
    private func uploadFile(data: Data, filename: String) {
        appState = .loading
        
        Task {
            do {
                let mimeType = getMimeType(for: filename)
                let uploadedFile = try await apiService.uploadFile(data: data, filename: filename, mimeType: mimeType)
                self.uploadedFile = uploadedFile
                appState = .uploadComplete(uploadedFile)
            } catch {
                appState = .error(error.localizedDescription)
            }
        }
    }
    
    private func generateSummary() {
        guard !extractedText.isEmpty else {
            appState = .error("No text content to summarize")
            return
        }
        
        appState = .summarizing
        
        Task {
            do {
                let result = try await apiService.summarizeText(extractedText, maxLength: 200)
                summaryResult = result
                appState = .summary(result)
            } catch {
                appState = .error(error.localizedDescription)
            }
        }
    }
    
    private func resetToIdle() {
        appState = .idle
        extractedText = ""
        summaryResult = nil
        uploadedFile = nil
        documentSource = .none
    }
    
    private func getMimeType(for filename: String) -> String {
        let pathExtension = (filename as NSString).pathExtension.lowercased()
        
        switch pathExtension {
        case "jpg", "jpeg":
            return "image/jpeg"
        case "png":
            return "image/png"
        case "pdf":
            return "application/pdf"
        case "txt":
            return "text/plain"
        case "doc":
            return "application/msword"
        case "docx":
            return "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
        default:
            return "application/octet-stream"
        }
    }
}

// MARK: - Feature Row Component
struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.blue.gradient)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

// MARK: - Preview
#Preview {
    ContentView()
} 