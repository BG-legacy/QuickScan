use axum::{
    http::StatusCode,
    response::{IntoResponse, Response},
    Json,
};
use serde_json::json;
use thiserror::Error;

pub type Result<T> = std::result::Result<T, AppError>;

#[derive(Error, Debug)]
pub enum AppError {
    #[error("Validation error: {0}")]
    ValidationError(String),

    #[error("Internal server error: {0}")]
    InternalError(String),

    #[error("External service error: {0}")]
    ExternalServiceError(String),

    #[error("Configuration error: {0}")]
    ConfigError(String),

    #[error("Not found: {0}")]
    NotFoundError(String),

    #[error("Storage error: {0}")]
    StorageError(String),

    #[error("OpenAI API error: {0}")]
    OpenAIError(String),

    #[error("HTTP client error: {0}")]
    HttpClientError(String),

    #[error("Request timeout")]
    TimeoutError,

    #[error("Rate limit exceeded")]
    RateLimitError,

    #[error("Authentication failed: {0}")]
    AuthError(String),

    #[error("Authorization failed: {0}")]
    AuthzError(String),

    #[error("Bad request: {0}")]
    BadRequestError(String),
}

impl AppError {
    pub fn status_code(&self) -> StatusCode {
        match self {
            AppError::ValidationError(_) => StatusCode::BAD_REQUEST,
            AppError::BadRequestError(_) => StatusCode::BAD_REQUEST,
            AppError::NotFoundError(_) => StatusCode::NOT_FOUND,
            AppError::AuthError(_) => StatusCode::UNAUTHORIZED,
            AppError::AuthzError(_) => StatusCode::FORBIDDEN,
            AppError::TimeoutError => StatusCode::REQUEST_TIMEOUT,
            AppError::RateLimitError => StatusCode::TOO_MANY_REQUESTS,
            AppError::ExternalServiceError(_) => StatusCode::BAD_GATEWAY,
            AppError::OpenAIError(_) => StatusCode::BAD_GATEWAY,
            AppError::HttpClientError(_) => StatusCode::BAD_GATEWAY,
            AppError::ConfigError(_) => StatusCode::INTERNAL_SERVER_ERROR,
            AppError::StorageError(_) => StatusCode::INTERNAL_SERVER_ERROR,
            AppError::InternalError(_) => StatusCode::INTERNAL_SERVER_ERROR,
        }
    }

    pub fn error_type(&self) -> &'static str {
        match self {
            AppError::ValidationError(_) => "validation_error",
            AppError::BadRequestError(_) => "bad_request",
            AppError::NotFoundError(_) => "not_found",
            AppError::AuthError(_) => "authentication_error",
            AppError::AuthzError(_) => "authorization_error",
            AppError::TimeoutError => "timeout_error",
            AppError::RateLimitError => "rate_limit_error",
            AppError::ExternalServiceError(_) => "external_service_error",
            AppError::OpenAIError(_) => "openai_error",
            AppError::HttpClientError(_) => "http_client_error",
            AppError::ConfigError(_) => "configuration_error",
            AppError::StorageError(_) => "storage_error",
            AppError::InternalError(_) => "internal_error",
        }
    }
}

impl IntoResponse for AppError {
    fn into_response(self) -> Response {
        let status = self.status_code();
        let error_type = self.error_type();
        let message = self.to_string();

        let body = Json(json!({
            "success": false,
            "error": {
                "type": error_type,
                "message": message,
                "status": status.as_u16()
            },
            "timestamp": chrono::Utc::now().to_rfc3339()
        }));

        (status, body).into_response()
    }
}

// Conversion implementations for common error types
impl From<reqwest::Error> for AppError {
    fn from(err: reqwest::Error) -> Self {
        if err.is_timeout() {
            AppError::TimeoutError
        } else if err.is_status() {
            AppError::ExternalServiceError(format!("HTTP error: {}", err))
        } else {
            AppError::ExternalServiceError(format!("Request error: {}", err))
        }
    }
}

impl From<serde_json::Error> for AppError {
    fn from(err: serde_json::Error) -> Self {
        AppError::ValidationError(format!("JSON parsing error: {}", err))
    }
}

impl From<std::env::VarError> for AppError {
    fn from(err: std::env::VarError) -> Self {
        AppError::ConfigError(format!("Environment variable error: {}", err))
    }
}

impl From<anyhow::Error> for AppError {
    fn from(err: anyhow::Error) -> Self {
        AppError::InternalError(err.to_string())
    }
}

impl From<validator::ValidationErrors> for AppError {
    fn from(errors: validator::ValidationErrors) -> Self {
        let error_messages: Vec<String> = errors
            .field_errors()
            .iter()
            .flat_map(|(field, errors)| {
                errors.iter().map(move |error| {
                    format!("{}: {}", field, error.message.as_ref().unwrap_or(&std::borrow::Cow::Borrowed("Invalid value")))
                })
            })
            .collect();
        
        AppError::ValidationError(error_messages.join(", "))
    }
} 