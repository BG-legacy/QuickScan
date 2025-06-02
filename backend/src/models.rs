// I am importing serialization, UUID, and validation libraries for my data models
use serde::{Deserialize, Serialize};
use uuid::Uuid;
use validator::{Validate, ValidationError};
use crate::storage::{StoredFile, StorageType};

// I am defining the response for the health check endpoint
#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct HealthResponse {
    pub status: String,
    pub message: String,
    pub timestamp: String,
}

// I am defining the request structure for scanning, with validation
#[derive(Debug, Serialize, Deserialize, Clone, Validate)]
pub struct ScanRequest {
    #[validate(length(min = 1, max = 10000, message = "Data must be between 1 and 10000 characters"))]
    pub data: String,
    
    #[validate(custom(function = "validate_format"))]
    pub format: String,
}

// I am defining the response structure for a scan
#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct ScanResponse {
    pub id: Uuid,
    pub data: String,
    pub format: String,
    pub timestamp: String,
    pub status: String,
}

// I am defining the request structure for creating a scan, with optional format and validation
#[derive(Debug, Serialize, Deserialize, Clone, Validate)]
pub struct CreateScanRequest {
    #[validate(length(min = 1, max = 10000, message = "Data must be between 1 and 10000 characters"))]
    pub data: String,
    
    #[validate(custom(function = "validate_optional_format"))]
    pub format: Option<String>,
}

// I am defining the response structure for a file upload
#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct UploadResponse {
    pub id: Uuid,
    pub filename: String,
    pub file_size: u64,
    pub content_type: Option<String>,
    pub timestamp: String,
    pub status: String,
    pub storage_type: StorageType,
    pub download_url: Option<String>,
}

// I am implementing a conversion from StoredFile to UploadResponse
impl From<StoredFile> for UploadResponse {
    fn from(stored_file: StoredFile) -> Self {
        Self {
            id: stored_file.id,
            filename: stored_file.filename,
            file_size: stored_file.file_size,
            content_type: stored_file.content_type,
            timestamp: stored_file.timestamp,
            status: "uploaded".to_string(),
            storage_type: stored_file.storage_type,
            download_url: stored_file.download_url,
        }
    }
}

// I am defining the response structure for a file download
#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct FileDownloadResponse {
    pub id: Uuid,
    pub filename: String,
    pub download_url: String,
    pub expires_at: String,
}

// I am defining the response structure for listing files
#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct FileListResponse {
    pub files: Vec<UploadResponse>,
    pub total_count: usize,
}

// I am defining the request structure for summarizing a document, with validation
#[derive(Debug, Serialize, Deserialize, Clone, Validate)]
pub struct SummarizeRequest {
    #[validate(length(min = 10, max = 50000, message = "Content must be between 10 and 50000 characters"))]
    pub content: String,
    
    #[validate(range(min = 50, max = 2000, message = "Max length must be between 50 and 2000 characters"))]
    pub max_length: Option<usize>,
}

// I am defining the response structure for a document summary
#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct SummarizeResponse {
    pub id: Uuid,
    pub original_content: String,
    pub summary: String,
    pub original_length: usize,
    pub summary_length: usize,
    pub timestamp: String,
}

// OpenAI API Models
#[derive(Debug, Serialize, Deserialize, Clone, Validate)]
pub struct ChatCompletionRequest {
    #[validate(length(min = 1, max = 50000, message = "Content must be between 1 and 50000 characters"))]
    pub content: String,
    
    #[validate(custom(function = "validate_optional_model"))]
    pub model: Option<String>,
    
    #[validate(range(min = 0.0, max = 2.0, message = "Temperature must be between 0.0 and 2.0"))]
    pub temperature: Option<f64>,
    
    #[validate(range(min = 1, max = 4096, message = "Max tokens must be between 1 and 4096"))]
    pub max_tokens: Option<u32>,
    
    pub system_prompt: Option<String>,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct ChatCompletionResponse {
    pub id: Uuid,
    pub content: String,
    pub model: String,
    pub usage: TokenUsage,
    pub timestamp: String,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct TokenUsage {
    pub prompt_tokens: u32,
    pub completion_tokens: u32,
    pub total_tokens: u32,
}

// OpenAI API Internal Models (for API communication)
#[derive(Debug, Serialize, Deserialize)]
pub struct OpenAIMessage {
    pub role: String,
    pub content: String,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct OpenAIChatRequest {
    pub model: String,
    pub messages: Vec<OpenAIMessage>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub temperature: Option<f64>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub max_tokens: Option<u32>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct OpenAIChoice {
    pub message: OpenAIMessage,
    pub finish_reason: Option<String>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct OpenAIUsage {
    pub prompt_tokens: u32,
    pub completion_tokens: u32,
    pub total_tokens: u32,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct OpenAIChatResponse {
    pub id: String,
    pub object: String,
    pub created: u64,
    pub model: String,
    pub choices: Vec<OpenAIChoice>,
    pub usage: OpenAIUsage,
}

// Enhanced API Response with validation metadata
#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct ApiResponse<T> {
    pub success: bool,
    pub data: Option<T>,
    pub message: String,
    pub validation_errors: Option<Vec<String>>,
}

impl<T> ApiResponse<T> {
    pub fn success(data: T, message: &str) -> Self {
        Self {
            success: true,
            data: Some(data),
            message: message.to_string(),
            validation_errors: None,
        }
    }

    pub fn error(message: &str) -> Self {
        Self {
            success: false,
            data: None,
            message: message.to_string(),
            validation_errors: None,
        }
    }
    
    pub fn validation_error(message: &str, errors: Vec<String>) -> Self {
        Self {
            success: false,
            data: None,
            message: message.to_string(),
            validation_errors: Some(errors),
        }
    }
}

// Configuration model for OpenAI
#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct OpenAIConfig {
    pub api_key: String,
    pub base_url: Option<String>,
    pub default_model: String,
    pub timeout_seconds: u64,
}

impl Default for OpenAIConfig {
    fn default() -> Self {
        Self {
            api_key: std::env::var("OPENAI_API_KEY").unwrap_or_default(),
            base_url: None,
            default_model: "gpt-4o-mini".to_string(),
            timeout_seconds: 30,
        }
    }
}

// Custom validation functions
fn validate_format(format: &str) -> Result<(), ValidationError> {
    let valid_formats = ["text", "qr", "barcode", "ocr"];
    if valid_formats.contains(&format) {
        Ok(())
    } else {
        Err(ValidationError::new("Format must be one of: text, qr, barcode, ocr"))
    }
}

fn validate_optional_format(format: &str) -> Result<(), ValidationError> {
    validate_format(format)
}

fn validate_optional_model(model: &str) -> Result<(), ValidationError> {
    let valid_models = ["gpt-3.5-turbo", "gpt-4", "gpt-4-turbo", "gpt-4o", "gpt-4o-mini"];
    if valid_models.contains(&model) {
        Ok(())
    } else {
        Err(ValidationError::new("Invalid model specified"))
    }
}

// User Authentication Models
#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct User {
    pub id: Uuid,
    pub email: String,
    pub password_hash: String,
    pub created_at: String,
    pub updated_at: String,
    pub is_active: bool,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct UserResponse {
    pub id: Uuid,
    pub email: String,
    pub created_at: String,
    pub is_active: bool,
}

impl From<User> for UserResponse {
    fn from(user: User) -> Self {
        Self {
            id: user.id,
            email: user.email,
            created_at: user.created_at,
            is_active: user.is_active,
        }
    }
}

#[derive(Debug, Serialize, Deserialize, Clone, Validate)]
pub struct RegisterRequest {
    #[validate(email(message = "Must be a valid email address"))]
    pub email: String,
    
    #[validate(length(min = 8, max = 128, message = "Password must be between 8 and 128 characters"))]
    pub password: String,
    
    #[validate(must_match(other = "password", message = "Passwords do not match"))]
    pub confirm_password: String,
}

#[derive(Debug, Serialize, Deserialize, Clone, Validate)]
pub struct LoginRequest {
    #[validate(email(message = "Must be a valid email address"))]
    pub email: String,
    
    #[validate(length(min = 1, message = "Password is required"))]
    pub password: String,
}

#[derive(Debug, Serialize, Deserialize, Clone, Validate)]
pub struct TokenLoginRequest {
    #[validate(length(min = 1, message = "Token is required"))]
    pub token: String,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct AuthResponse {
    pub user: UserResponse,
    pub token: String,
    pub expires_at: String,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct TokenResponse {
    pub token: String,
    pub expires_at: String,
}

// JWT Claims
#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct Claims {
    pub sub: String, // Subject (user ID)
    pub email: String,
    pub exp: usize, // Expiration time
    pub iat: usize, // Issued at
} 