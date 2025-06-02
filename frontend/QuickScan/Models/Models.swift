import Foundation

// MARK: - API Response Models
struct APIResponse<T: Codable>: Codable {
    let success: Bool
    let data: T?
    let message: String?
    let error: APIError?
    let timestamp: String?
}

struct APIError: Codable {
    let type: String
    let message: String
    let status: Int
}

// MARK: - File Models
struct UploadedFile: Codable, Identifiable {
    let id: String
    let filename: String
    let fileSize: Int
    let contentType: String
    let timestamp: String
    let status: String
    let storageType: String
    let downloadUrl: String?
    
    private enum CodingKeys: String, CodingKey {
        case id, filename, timestamp, status
        case fileSize = "file_size"
        case contentType = "content_type"
        case storageType = "storage_type"
        case downloadUrl = "download_url"
    }
}

struct FileList: Codable {
    let files: [UploadedFile]
    let totalCount: Int
    
    private enum CodingKeys: String, CodingKey {
        case files
        case totalCount = "total_count"
    }
}

// MARK: - Summarization Models
struct SummarizationRequest: Codable {
    let content: String
    let maxLength: Int?
    
    private enum CodingKeys: String, CodingKey {
        case content
        case maxLength = "max_length"
    }
}

struct SummarizationResult: Codable, Identifiable {
    let id: String
    let originalContent: String
    let summary: String
    let originalLength: Int
    let summaryLength: Int
    let timestamp: String
    
    private enum CodingKeys: String, CodingKey {
        case id, summary, timestamp
        case originalContent = "original_content"
        case originalLength = "original_length"
        case summaryLength = "summary_length"
    }
}

// MARK: - Chat Models
struct ChatRequest: Codable {
    let content: String
    let model: String?
    let temperature: Double?
    let maxTokens: Int?
    let systemPrompt: String?
    
    private enum CodingKeys: String, CodingKey {
        case content, model, temperature
        case maxTokens = "max_tokens"
        case systemPrompt = "system_prompt"
    }
}

struct ChatResponse: Codable, Identifiable {
    let id: String
    let content: String
    let model: String
    let usage: TokenUsage
    let timestamp: String
}

struct TokenUsage: Codable {
    let promptTokens: Int
    let completionTokens: Int
    let totalTokens: Int
    
    private enum CodingKeys: String, CodingKey {
        case promptTokens = "prompt_tokens"
        case completionTokens = "completion_tokens"
        case totalTokens = "total_tokens"
    }
}

// MARK: - UI State Models
enum AppState {
    case idle
    case loading
    case fileSelected(Data, String)
    case uploadComplete(UploadedFile)
    case summarizing
    case summary(SummarizationResult)
    case error(String)
}

enum DocumentSource {
    case camera
    case files
    case none
}

// MARK: - Extensions
extension UploadedFile {
    var formattedFileSize: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(fileSize))
    }
    
    var formattedTimestamp: String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: timestamp) else {
            return timestamp
        }
        
        let displayFormatter = DateFormatter()
        displayFormatter.dateStyle = .medium
        displayFormatter.timeStyle = .short
        return displayFormatter.string(from: date)
    }
}

// MARK: - Authentication Models
struct User: Codable, Identifiable {
    let id: String
    let email: String
    let createdAt: String
    let isActive: Bool
    
    private enum CodingKeys: String, CodingKey {
        case id, email
        case createdAt = "created_at"
        case isActive = "is_active"
    }
}

struct AuthResponse: Codable {
    let user: User
    let token: String
    let expiresAt: String
    
    private enum CodingKeys: String, CodingKey {
        case user, token
        case expiresAt = "expires_at"
    }
}

struct LoginRequest: Codable {
    let email: String
    let password: String
}

struct RegisterRequest: Codable {
    let email: String
    let password: String
    let confirmPassword: String
    
    private enum CodingKeys: String, CodingKey {
        case email, password
        case confirmPassword = "confirm_password"
    }
}

struct TokenLoginRequest: Codable {
    let token: String
}

// MARK: - Authentication State
enum AuthState {
    case unauthenticated
    case loading
    case authenticated(User)
    case error(String)
}

// MARK: - API Service Errors
enum APIServiceError: LocalizedError {
    case invalidURL
    case invalidResponse
    case noData
    case serverError(String)
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .noData:
            return "No data received from server"
        case .serverError(let message):
            return message
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}

enum LoginMode {
    case emailPassword
    case token
} 