// I am importing the necessary routing macros and types from Axum
use axum::{
    routing::{get, post, delete},
    Router,
};

// I am importing all the handler functions and the application state from my handlers module
use crate::handlers::{
    health_check, create_scan, get_scan, list_scans, delete_scan, upload_file,
    download_file, get_file_download_url, list_files, delete_file, cleanup_temp_files,
    summarize_document, chat_completion, AppState,
    // Authentication handlers
    register, login, token_login, verify_token, get_current_user,
};

// I am defining a function to create all the API routes for my application
pub fn create_routes() -> Router<AppState> {
    // I am building the router and mapping each endpoint to its handler
    Router::new()
        .route("/health", get(health_check))
        // Authentication routes
        .route("/auth/register", post(register))
        .route("/auth/login", post(login))
        .route("/auth/token", post(token_login))
        .route("/auth/verify", post(verify_token))
        .route("/auth/me", get(get_current_user))
        // Existing routes
        .route("/scans", post(create_scan))
        .route("/scans", get(list_scans))
        .route("/scans/:id", get(get_scan))
        .route("/scans/:id", delete(delete_scan))
        .route("/upload", post(upload_file))
        .route("/files", get(list_files))
        .route("/files/:id/download", get(download_file))
        .route("/files/:id/url", get(get_file_download_url))
        .route("/files/:id", delete(delete_file))
        .route("/files/cleanup", post(cleanup_temp_files))
        .route("/summarize", post(summarize_document))
        .route("/chat/completion", post(chat_completion))
} 