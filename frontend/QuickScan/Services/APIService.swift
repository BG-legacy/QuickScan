import Foundation
import SwiftUI
import UIKit

// APIService handles all network communication with the backend API, including file upload, authentication, and AI features.
@MainActor
class APIService: ObservableObject {
    static let shared = APIService()
    
    private let baseURL = "http://127.0.0.1:3000/api"
    private let session = URLSession.shared
    // TEMPORARY: Commenting out AuthService until it's added to the project target
    // private let authService = AuthService.shared
    
    private init() {}
    
    // MARK: - Helper Methods
    
    private func addAuthorizationHeader(to request: inout URLRequest) {
        // TEMPORARY: Fallback implementation until AuthService is available
        // if let token = authService.getAuthToken() {
        //     request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        // }
    }
    
    // MARK: - Health Check
    func checkHealth() async throws -> Bool {
        let url = URL(string: "\(baseURL)/health")!
        let (_, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIServiceError.invalidResponse
        }
        
        return httpResponse.statusCode == 200
    }
    
    // MARK: - File Upload
    func uploadFile(data: Data, filename: String, mimeType: String) async throws -> UploadedFile {
        let url = URL(string: "\(baseURL)/upload")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // Add authorization header for authenticated upload
        addAuthorizationHeader(to: &request)
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // Add file field
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(data)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        let (responseData, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIServiceError.invalidResponse
        }
        
        if httpResponse.statusCode != 200 {
            if let errorResponse = try? JSONDecoder().decode(APIResponse<String>.self, from: responseData) {
                throw APIServiceError.serverError(errorResponse.error?.message ?? "Upload failed")
            }
            throw APIServiceError.serverError("Upload failed with status \(httpResponse.statusCode)")
        }
        
        let apiResponse = try JSONDecoder().decode(APIResponse<UploadedFile>.self, from: responseData)
        
        guard let uploadedFile = apiResponse.data else {
            throw APIServiceError.noData
        }
        
        return uploadedFile
    }
    
    // MARK: - File Operations
    func getFiles() async throws -> [UploadedFile] {
        let url = URL(string: "\(baseURL)/files")!
        var request = URLRequest(url: url)
        
        // Add authorization header for authenticated request
        addAuthorizationHeader(to: &request)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIServiceError.invalidResponse
        }
        
        if httpResponse.statusCode != 200 {
            throw APIServiceError.serverError("Failed to fetch files")
        }
        
        let apiResponse = try JSONDecoder().decode(APIResponse<FileList>.self, from: data)
        
        guard let fileList = apiResponse.data else {
            throw APIServiceError.noData
        }
        
        return fileList.files
    }
    
    func deleteFile(id: String) async throws {
        let url = URL(string: "\(baseURL)/files/\(id)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        
        // Add authorization header for authenticated request
        addAuthorizationHeader(to: &request)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIServiceError.invalidResponse
        }
        
        if httpResponse.statusCode != 200 {
            if let errorResponse = try? JSONDecoder().decode(APIResponse<String>.self, from: data) {
                throw APIServiceError.serverError(errorResponse.error?.message ?? "Delete failed")
            }
            throw APIServiceError.serverError("Delete failed with status \(httpResponse.statusCode)")
        }
    }
    
    // MARK: - Document Summarization
    func summarizeText(_ text: String, maxLength: Int = 200) async throws -> SummarizationResult {
        let url = URL(string: "\(baseURL)/summarize")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add authorization header for authenticated request
        addAuthorizationHeader(to: &request)
        
        let requestBody = SummarizationRequest(content: text, maxLength: maxLength)
        request.httpBody = try JSONEncoder().encode(requestBody)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIServiceError.invalidResponse
        }
        
        if httpResponse.statusCode != 200 {
            if let errorResponse = try? JSONDecoder().decode(APIResponse<String>.self, from: data) {
                throw APIServiceError.serverError(errorResponse.error?.message ?? "Summarization failed")
            }
            throw APIServiceError.serverError("Summarization failed with status \(httpResponse.statusCode)")
        }
        
        let apiResponse = try JSONDecoder().decode(APIResponse<SummarizationResult>.self, from: data)
        
        guard let result = apiResponse.data else {
            throw APIServiceError.noData
        }
        
        return result
    }
    
    // MARK: - Chat Completion
    func chatCompletion(content: String, model: String? = nil, temperature: Double? = nil, maxTokens: Int? = nil, systemPrompt: String? = nil) async throws -> ChatResponse {
        let url = URL(string: "\(baseURL)/chat/completion")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add authorization header for authenticated request
        addAuthorizationHeader(to: &request)
        
        let requestBody = ChatRequest(
            content: content,
            model: model,
            temperature: temperature,
            maxTokens: maxTokens,
            systemPrompt: systemPrompt
        )
        request.httpBody = try JSONEncoder().encode(requestBody)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIServiceError.invalidResponse
        }
        
        if httpResponse.statusCode != 200 {
            if let errorResponse = try? JSONDecoder().decode(APIResponse<String>.self, from: data) {
                throw APIServiceError.serverError(errorResponse.error?.message ?? "Chat completion failed")
            }
            throw APIServiceError.serverError("Chat completion failed with status \(httpResponse.statusCode)")
        }
        
        let apiResponse = try JSONDecoder().decode(APIResponse<ChatResponse>.self, from: data)
        
        guard let result = apiResponse.data else {
            throw APIServiceError.noData
        }
        
        return result
    }
    
    // MARK: - Document Upload with Enhanced Features
    func uploadDocument(
        data: Data,
        filename: String,
        mimeType: String,
        progressHandler: ((Double) -> Void)? = nil
    ) async throws -> UploadedFile {
        // Validate document size (10MB limit to match backend)
        let maxSize = 10 * 1024 * 1024 // 10MB
        guard data.count <= maxSize else {
            throw APIServiceError.serverError("Document size exceeds 10MB limit")
        }
        
        // Validate document type (common document formats)
        let allowedMimeTypes = [
            "application/pdf",
            "application/msword",
            "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
            "text/plain",
            "image/jpeg",
            "image/png",
            "image/heic",
            "image/heif"
        ]
        
        guard allowedMimeTypes.contains(mimeType) else {
            throw APIServiceError.serverError("Unsupported document type: \(mimeType)")
        }
        
        let url = URL(string: "\(baseURL)/upload")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 60.0 // 60 seconds for large documents
        
        // Add authorization header for authenticated upload
        addAuthorizationHeader(to: &request)
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        // Build multipart body
        var body = Data()
        
        // Add file field with enhanced metadata
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\r\n".data(using: .utf8)!)
        body.append("Content-Length: \(data.count)\r\n\r\n".data(using: .utf8)!)
        body.append(data)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        // Create upload task with progress tracking
        return try await withCheckedThrowingContinuation { continuation in
            let task = session.uploadTask(with: request, from: body) { [weak self] data, response, error in
                Task { @MainActor in
                    do {
                        if let error = error {
                            throw APIServiceError.networkError(error)
                        }
                        
                        guard let data = data,
                              let httpResponse = response as? HTTPURLResponse else {
                            throw APIServiceError.invalidResponse
                        }
                        
                        // Handle different HTTP status codes
                        switch httpResponse.statusCode {
                        case 200...299:
                            // Success - parse response
                            let apiResponse = try JSONDecoder().decode(APIResponse<UploadedFile>.self, from: data)
                            
                            guard let uploadedFile = apiResponse.data else {
                                throw APIServiceError.noData
                            }
                            
                            continuation.resume(returning: uploadedFile)
                            
                        case 400:
                            // Bad Request - validation error
                            if let errorResponse = try? JSONDecoder().decode(APIResponse<String>.self, from: data) {
                                throw APIServiceError.serverError(errorResponse.error?.message ?? "Invalid document format")
                            }
                            throw APIServiceError.serverError("Invalid document format")
                            
                        case 401:
                            // Unauthorized
                            throw APIServiceError.serverError("Authentication required. Please log in again.")
                            
                        case 413:
                            // Payload too large
                            throw APIServiceError.serverError("Document size exceeds server limit")
                            
                        case 415:
                            // Unsupported media type
                            throw APIServiceError.serverError("Unsupported document format")
                            
                        case 429:
                            // Too many requests
                            throw APIServiceError.serverError("Upload rate limit exceeded. Please try again later.")
                            
                        case 500...599:
                            // Server error
                            throw APIServiceError.serverError("Server error. Please try again later.")
                            
                        default:
                            // Other errors
                            if let errorResponse = try? JSONDecoder().decode(APIResponse<String>.self, from: data) {
                                throw APIServiceError.serverError(errorResponse.error?.message ?? "Upload failed")
                            }
                            throw APIServiceError.serverError("Upload failed with status \(httpResponse.statusCode)")
                        }
                        
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
            }
            
            // Set up progress observation
            if let progressHandler = progressHandler {
                let observation = task.progress.observe(\.fractionCompleted) { progress, _ in
                    DispatchQueue.main.async {
                        progressHandler(progress.fractionCompleted)
                    }
                }
                
                // Store observation to prevent deallocation
                task.taskDescription = "\(observation)"
            }
            
            task.resume()
        }
    }
    
    // MARK: - Batch Document Upload
    func uploadDocuments(
        documents: [(data: Data, filename: String, mimeType: String)],
        progressHandler: ((Int, Int, Double) -> Void)? = nil
    ) async throws -> [UploadedFile] {
        var uploadedFiles: [UploadedFile] = []
        
        for (index, document) in documents.enumerated() {
            do {
                let uploadedFile = try await uploadDocument(
                    data: document.data,
                    filename: document.filename,
                    mimeType: document.mimeType
                ) { progress in
                    // Calculate overall progress
                    let fileProgress = Double(index) + progress
                    let totalProgress = fileProgress / Double(documents.count)
                    progressHandler?(index + 1, documents.count, totalProgress)
                }
                
                uploadedFiles.append(uploadedFile)
                
            } catch {
                // Continue with other uploads even if one fails
                print("Failed to upload \(document.filename): \(error)")
                // You might want to collect failed uploads and return them separately
            }
        }
        
        return uploadedFiles
    }
    
    // MARK: - Convenience Upload Methods
    
    /// Upload a document from a local file URL
    func uploadDocument(from fileURL: URL, progressHandler: ((Double) -> Void)? = nil) async throws -> UploadedFile {
        guard fileURL.startAccessingSecurityScopedResource() else {
            throw APIServiceError.serverError("Unable to access file")
        }
        defer { fileURL.stopAccessingSecurityScopedResource() }
        
        let data = try Data(contentsOf: fileURL)
        let filename = fileURL.lastPathComponent
        let mimeType = mimeTypeForExtension(fileURL.pathExtension)
        
        return try await uploadDocument(
            data: data,
            filename: filename,
            mimeType: mimeType,
            progressHandler: progressHandler
        )
    }
    
    /// Upload an image as a document (converts UIImage to JPEG)
    func uploadImageDocument(
        image: UIImage,
        filename: String? = nil,
        quality: CGFloat = 0.8,
        progressHandler: ((Double) -> Void)? = nil
    ) async throws -> UploadedFile {
        guard let imageData = image.jpegData(compressionQuality: quality) else {
            throw APIServiceError.serverError("Failed to convert image to JPEG")
        }
        
        let finalFilename = filename ?? "document_\(Date().timeIntervalSince1970).jpg"
        
        return try await uploadDocument(
            data: imageData,
            filename: finalFilename,
            mimeType: "image/jpeg",
            progressHandler: progressHandler
        )
    }
    
    /// Upload text content as a document
    func uploadTextDocument(
        text: String,
        filename: String? = nil,
        progressHandler: ((Double) -> Void)? = nil
    ) async throws -> UploadedFile {
        guard let textData = text.data(using: .utf8) else {
            throw APIServiceError.serverError("Failed to convert text to data")
        }
        
        let finalFilename = filename ?? "document_\(Date().timeIntervalSince1970).txt"
        
        return try await uploadDocument(
            data: textData,
            filename: finalFilename,
            mimeType: "text/plain",
            progressHandler: progressHandler
        )
    }
    
    /// Helper method to determine MIME type from file extension
    private func mimeTypeForExtension(_ pathExtension: String) -> String {
        let ext = pathExtension.lowercased()
        
        switch ext {
        case "pdf":
            return "application/pdf"
        case "doc":
            return "application/msword"
        case "docx":
            return "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
        case "txt":
            return "text/plain"
        case "jpg", "jpeg":
            return "image/jpeg"
        case "png":
            return "image/png"
        case "heic":
            return "image/heic"
        case "heif":
            return "image/heif"
        default:
            return "application/octet-stream"
        }
    }
} 