use axum::{extract::{Path, Multipart, State}, Json, response::Response, body::Body, http::{StatusCode, HeaderMap, header}};
use chrono::Utc;
use uuid::Uuid;
use validator::Validate;
use std::sync::Arc;
use std::collections::HashMap;
use tokio::sync::RwLock;

use crate::{
    auth::AuthService,
    error::{AppError, Result},
    models::{
        ApiResponse, CreateScanRequest, HealthResponse, ScanResponse, UploadResponse, 
        SummarizeRequest, SummarizeResponse, ChatCompletionRequest, ChatCompletionResponse,
        OpenAIConfig, FileDownloadResponse, FileListResponse,
        // Authentication models
        RegisterRequest, LoginRequest, TokenLoginRequest, AuthResponse, TokenResponse, UserResponse
    },
    openai::OpenAIService,
    storage::{StorageService, StorageConfig, StoredFile},
};

// Application state to hold shared services
#[derive(Clone)]
pub struct AppState {
    pub openai_service: Arc<OpenAIService>,
    pub storage_service: Arc<StorageService>,
    pub file_registry: Arc<RwLock<HashMap<Uuid, StoredFile>>>,
    pub auth_service: Arc<AuthService>,
}

impl AppState {
    pub fn new() -> Result<Self> {
        let openai_config = OpenAIConfig::default();
        let openai_service = Arc::new(OpenAIService::new(openai_config)?);
        
        let storage_config = StorageConfig::default();
        let storage_service = Arc::new(StorageService::new(storage_config)
            .map_err(|e| AppError::StorageError(e.to_string()))?);
        
        let auth_service = Arc::new(AuthService::new());
        
        Ok(Self {
            openai_service,
            storage_service,
            file_registry: Arc::new(RwLock::new(HashMap::new())),
            auth_service,
        })
    }
}

pub async fn health_check() -> Result<Json<HealthResponse>> {
    let response = HealthResponse {
        status: "healthy".to_string(),
        message: "QuickScan backend is running with AI capabilities".to_string(),
        timestamp: Utc::now().to_rfc3339(),
    };
    
    Ok(Json(response))
}

pub async fn create_scan(
    State(state): State<AppState>,
    Json(payload): Json<CreateScanRequest>
) -> Result<Json<ApiResponse<ScanResponse>>> {
    // Validate the request
    if let Err(validation_errors) = payload.validate() {
        return Ok(Json(ApiResponse::validation_error(
            "Validation failed",
            validation_errors
                .field_errors()
                .iter()
                .flat_map(|(field, errors)| {
                    errors.iter().map(move |error| {
                        format!("{}: {}", field, error.message.as_ref().unwrap_or(&std::borrow::Cow::Borrowed("Invalid value")))
                    })
                })
                .collect(),
        )));
    }

    tracing::info!("Creating new scan with data: {}", payload.data);

    let format = payload.format.unwrap_or_else(|| "text".to_string());
    
    // Use OpenAI to analyze the scan data
    let analysis = match state.openai_service.analyze_scan_data(&payload.data, &format).await {
        Ok(analysis) => Some(analysis),
        Err(e) => {
            tracing::warn!("Failed to analyze scan data with AI: {}", e);
            None
        }
    };

    let scan = ScanResponse {
        id: Uuid::new_v4(),
        data: payload.data,
        format,
        timestamp: Utc::now().to_rfc3339(),
        status: if analysis.is_some() { "analyzed" } else { "processed" }.to_string(),
    };

    if let Some(analysis) = analysis {
        tracing::info!("AI Analysis: {}", analysis);
    }

    let response = ApiResponse::success(scan, "Scan created and analyzed successfully");
    Ok(Json(response))
}

pub async fn get_scan(Path(id): Path<Uuid>) -> Result<Json<ApiResponse<ScanResponse>>> {
    tracing::info!("Retrieving scan with id: {}", id);

    // For now, return a mock scan. In a real application, you'd fetch this from a database.
    let scan = ScanResponse {
        id,
        data: "Sample scan data".to_string(),
        format: "text".to_string(),
        timestamp: Utc::now().to_rfc3339(),
        status: "processed".to_string(),
    };

    let response = ApiResponse::success(scan, "Scan retrieved successfully");
    Ok(Json(response))
}

pub async fn list_scans() -> Result<Json<ApiResponse<Vec<ScanResponse>>>> {
    tracing::info!("Listing all scans");

    // For now, return mock data. In a real application, you'd fetch this from a database.
    let scans = vec![
        ScanResponse {
            id: Uuid::new_v4(),
            data: "Sample scan 1".to_string(),
            format: "text".to_string(),
            timestamp: Utc::now().to_rfc3339(),
            status: "processed".to_string(),
        },
        ScanResponse {
            id: Uuid::new_v4(),
            data: "Sample scan 2".to_string(),
            format: "qr".to_string(),
            timestamp: Utc::now().to_rfc3339(),
            status: "analyzed".to_string(),
        },
    ];

    let response = ApiResponse::success(scans, "Scans retrieved successfully");
    Ok(Json(response))
}

pub async fn delete_scan(Path(id): Path<Uuid>) -> Result<Json<ApiResponse<String>>> {
    tracing::info!("Deleting scan with id: {}", id);

    // In a real application, you'd delete the scan from the database here
    // For now, we'll just simulate a successful deletion

    let response = ApiResponse::success(format!("Scan {} deleted", id), "Scan deleted successfully");
    Ok(Json(response))
}

pub async fn upload_file(
    State(state): State<AppState>,
    mut multipart: Multipart
) -> Result<Json<ApiResponse<UploadResponse>>> {
    tracing::info!("Processing file upload");

    let mut filename = String::new();
    let mut file_data: Option<Vec<u8>> = None;
    let mut content_type: Option<String> = None;

    while let Some(field) = multipart.next_field().await.map_err(|e| {
        AppError::ValidationError(format!("Error reading multipart field: {}", e))
    })? {
        let field_name = field.name().unwrap_or("unknown").to_string();
        
        if field_name == "file" {
            filename = field.file_name().unwrap_or("unknown").to_string();
            content_type = field.content_type().map(|ct| ct.to_string());
            
            let data = field.bytes().await.map_err(|e| {
                AppError::ValidationError(format!("Error reading file data: {}", e))
            })?;
            
            // Validate file size (10MB limit)
            if data.len() > 10 * 1024 * 1024 {
                return Err(AppError::ValidationError("File size exceeds 10MB limit".to_string()));
            }
            
            file_data = Some(data.to_vec());
            tracing::info!("Uploaded file: {} ({} bytes)", filename, data.len());
        }
    }

    if filename.is_empty() || file_data.is_none() {
        return Err(AppError::ValidationError("No file found in upload".to_string()));
    }

    let data = file_data.unwrap();
    
    // Store the file using the storage service
    let stored_file = state.storage_service
        .store_file(&filename, content_type, &data)
        .await
        .map_err(|e| AppError::StorageError(e.to_string()))?;

    // Add to file registry
    state.file_registry.write().await.insert(stored_file.id, stored_file.clone());

    let upload_response = UploadResponse::from(stored_file);
    let response = ApiResponse::success(upload_response, "File uploaded successfully");
    Ok(Json(response))
}

pub async fn download_file(
    State(state): State<AppState>,
    Path(file_id): Path<Uuid>,
) -> Result<Response<Body>> {
    tracing::info!("Downloading file with id: {}", file_id);

    let file_registry = state.file_registry.read().await;
    let stored_file = file_registry.get(&file_id)
        .ok_or_else(|| AppError::NotFoundError("File not found".to_string()))?;

    let file_data = state.storage_service
        .get_file(stored_file)
        .await
        .map_err(|e| AppError::StorageError(e.to_string()))?;

    let mut headers = HeaderMap::new();
    headers.insert(
        header::CONTENT_DISPOSITION,
        format!("attachment; filename=\"{}\"", stored_file.filename)
            .parse()
            .unwrap(),
    );

    if let Some(content_type) = &stored_file.content_type {
        headers.insert(header::CONTENT_TYPE, content_type.parse().unwrap());
    }

    Ok(Response::builder()
        .status(StatusCode::OK)
        .body(Body::from(file_data))
        .unwrap())
}

pub async fn get_file_download_url(
    State(state): State<AppState>,
    Path(file_id): Path<Uuid>,
) -> Result<Json<ApiResponse<FileDownloadResponse>>> {
    tracing::info!("Getting download URL for file: {}", file_id);

    let file_registry = state.file_registry.read().await;
    let stored_file = file_registry.get(&file_id)
        .ok_or_else(|| AppError::NotFoundError("File not found".to_string()))?;

    let download_url = state.storage_service
        .get_download_url(stored_file, 3600) // 1 hour expiry
        .await
        .map_err(|e| AppError::StorageError(e.to_string()))?;

    let expires_at = (Utc::now() + chrono::Duration::hours(1)).to_rfc3339();

    let response_data = FileDownloadResponse {
        id: file_id,
        filename: stored_file.filename.clone(),
        download_url,
        expires_at,
    };

    let response = ApiResponse::success(response_data, "Download URL generated successfully");
    Ok(Json(response))
}

pub async fn list_files(
    State(state): State<AppState>,
) -> Result<Json<ApiResponse<FileListResponse>>> {
    tracing::info!("Listing all uploaded files");

    let file_registry = state.file_registry.read().await;
    let files: Vec<UploadResponse> = file_registry
        .values()
        .map(|stored_file| UploadResponse::from(stored_file.clone()))
        .collect();

    let response_data = FileListResponse {
        total_count: files.len(),
        files,
    };

    let response = ApiResponse::success(response_data, "Files retrieved successfully");
    Ok(Json(response))
}

pub async fn delete_file(
    State(state): State<AppState>,
    Path(file_id): Path<Uuid>,
) -> Result<Json<ApiResponse<String>>> {
    tracing::info!("Deleting file with id: {}", file_id);

    let mut file_registry = state.file_registry.write().await;
    let stored_file = file_registry.get(&file_id)
        .ok_or_else(|| AppError::NotFoundError("File not found".to_string()))?
        .clone();

    // Delete from storage
    state.storage_service
        .delete_file(&stored_file)
        .await
        .map_err(|e| AppError::StorageError(e.to_string()))?;

    // Remove from registry
    file_registry.remove(&file_id);

    let response = ApiResponse::success(
        format!("File {} deleted", file_id),
        "File deleted successfully"
    );
    Ok(Json(response))
}

pub async fn cleanup_temp_files(
    State(state): State<AppState>,
) -> Result<Json<ApiResponse<String>>> {
    tracing::info!("Cleaning up expired temporary files");

    let deleted_count = state.storage_service
        .cleanup_expired_temp_files(24) // 24 hours
        .await
        .map_err(|e| AppError::StorageError(e.to_string()))?;

    let response = ApiResponse::success(
        format!("Cleaned up {} expired files", deleted_count),
        "Cleanup completed successfully"
    );
    Ok(Json(response))
}

pub async fn summarize_document(
    State(state): State<AppState>,
    Json(payload): Json<SummarizeRequest>
) -> Result<Json<ApiResponse<SummarizeResponse>>> {
    // Validate the request
    if let Err(validation_errors) = payload.validate() {
        return Ok(Json(ApiResponse::validation_error(
            "Validation failed",
            validation_errors
                .field_errors()
                .iter()
                .flat_map(|(field, errors)| {
                    errors.iter().map(move |error| {
                        format!("{}: {}", field, error.message.as_ref().unwrap_or(&std::borrow::Cow::Borrowed("Invalid value")))
                    })
                })
                .collect(),
        )));
    }

    tracing::info!("Summarizing document content (length: {} chars)", payload.content.len());

    let original_length = payload.content.len();
    let max_length = payload.max_length.unwrap_or(200);
    
    // Use OpenAI to generate a proper summary
    let summary = state
        .openai_service
        .summarize_text(&payload.content, max_length)
        .await?;

    let summary_length = summary.len();

    let summarize_response = SummarizeResponse {
        id: Uuid::new_v4(),
        original_content: payload.content,
        summary,
        original_length,
        summary_length,
        timestamp: Utc::now().to_rfc3339(),
    };

    let response = ApiResponse::success(summarize_response, "Document summarized successfully using AI");
    Ok(Json(response))
}

// New OpenAI-specific handlers
pub async fn chat_completion(
    State(state): State<AppState>,
    Json(payload): Json<ChatCompletionRequest>
) -> Result<Json<ApiResponse<ChatCompletionResponse>>> {
    // Validate the request
    if let Err(validation_errors) = payload.validate() {
        return Ok(Json(ApiResponse::validation_error(
            "Validation failed",
            validation_errors
                .field_errors()
                .iter()
                .flat_map(|(field, errors)| {
                    errors.iter().map(move |error| {
                        format!("{}: {}", field, error.message.as_ref().unwrap_or(&std::borrow::Cow::Borrowed("Invalid value")))
                    })
                })
                .collect(),
        )));
    }

    tracing::info!("Processing chat completion request");

    let completion_response = state
        .openai_service
        .chat_completion(payload)
        .await?;

    let response = ApiResponse::success(completion_response, "Chat completion generated successfully");
    Ok(Json(response))
}

// MARK: - Authentication Handlers

pub async fn register(
    State(state): State<AppState>,
    Json(payload): Json<RegisterRequest>
) -> Result<Json<ApiResponse<AuthResponse>>> {
    // Validate the request
    if let Err(validation_errors) = payload.validate() {
        return Ok(Json(ApiResponse::validation_error(
            "Validation failed",
            validation_errors
                .field_errors()
                .iter()
                .flat_map(|(field, errors)| {
                    errors.iter().map(move |error| {
                        format!("{}: {}", field, error.message.as_ref().unwrap_or(&std::borrow::Cow::Borrowed("Invalid value")))
                    })
                })
                .collect(),
        )));
    }

    tracing::info!("Registering new user: {}", payload.email);

    // Register the user
    let user = state
        .auth_service
        .register_user(payload.email, payload.password)
        .await?;

    // Generate JWT token
    let (token, expires_at) = state.auth_service.generate_token(&user)?;

    let auth_response = AuthResponse {
        user,
        token,
        expires_at,
    };

    let response = ApiResponse::success(auth_response, "User registered successfully");
    Ok(Json(response))
}

pub async fn login(
    State(state): State<AppState>,
    Json(payload): Json<LoginRequest>
) -> Result<Json<ApiResponse<AuthResponse>>> {
    // Validate the request
    if let Err(validation_errors) = payload.validate() {
        return Ok(Json(ApiResponse::validation_error(
            "Validation failed",
            validation_errors
                .field_errors()
                .iter()
                .flat_map(|(field, errors)| {
                    errors.iter().map(move |error| {
                        format!("{}: {}", field, error.message.as_ref().unwrap_or(&std::borrow::Cow::Borrowed("Invalid value")))
                    })
                })
                .collect(),
        )));
    }

    tracing::info!("User login attempt: {}", payload.email);

    // Authenticate the user
    let user = state
        .auth_service
        .authenticate_user(payload.email, payload.password)
        .await?;

    // Generate JWT token
    let (token, expires_at) = state.auth_service.generate_token(&user)?;

    let auth_response = AuthResponse {
        user,
        token,
        expires_at,
    };

    let response = ApiResponse::success(auth_response, "Login successful");
    Ok(Json(response))
}

pub async fn token_login(
    State(state): State<AppState>,
    Json(payload): Json<TokenLoginRequest>
) -> Result<Json<ApiResponse<AuthResponse>>> {
    // Validate the request
    if let Err(validation_errors) = payload.validate() {
        return Ok(Json(ApiResponse::validation_error(
            "Validation failed",
            validation_errors
                .field_errors()
                .iter()
                .flat_map(|(field, errors)| {
                    errors.iter().map(move |error| {
                        format!("{}: {}", field, error.message.as_ref().unwrap_or(&std::borrow::Cow::Borrowed("Invalid value")))
                    })
                })
                .collect(),
        )));
    }

    tracing::info!("Token-based authentication attempt");

    // Authenticate with token
    let user = state
        .auth_service
        .authenticate_with_token(&payload.token)
        .await?;

    // Generate JWT token for consistent response format
    let (token, expires_at) = state.auth_service.generate_token(&user)?;

    let auth_response = AuthResponse {
        user,
        token,
        expires_at,
    };

    let response = ApiResponse::success(auth_response, "Token authentication successful");
    Ok(Json(response))
}

pub async fn verify_token(
    State(state): State<AppState>,
    Json(token_request): Json<TokenResponse>
) -> Result<Json<ApiResponse<UserResponse>>> {
    tracing::info!("Verifying JWT token");

    // Validate the token
    let claims = state.auth_service.validate_token(&token_request.token)?;

    // Get user information
    let user = state
        .auth_service
        .get_user_by_id(&claims.sub)
        .await?;

    let response = ApiResponse::success(user, "Token is valid");
    Ok(Json(response))
}

pub async fn get_current_user(
    State(state): State<AppState>,
    headers: HeaderMap,
) -> Result<Json<ApiResponse<UserResponse>>> {
    tracing::info!("Getting current user information");

    // Extract token from Authorization header
    let auth_header = headers
        .get("Authorization")
        .and_then(|h| h.to_str().ok())
        .ok_or_else(|| AppError::AuthError("Missing Authorization header".to_string()))?;

    let token = auth_header
        .strip_prefix("Bearer ")
        .ok_or_else(|| AppError::AuthError("Invalid Authorization header format".to_string()))?;

    // Validate the token
    let claims = state.auth_service.validate_token(token)?;

    // Get user information
    let user = state
        .auth_service
        .get_user_by_id(&claims.sub)
        .await?;

    let response = ApiResponse::success(user, "User information retrieved successfully");
    Ok(Json(response))
} 