// I am importing all the internal modules that make up the backend's core features
mod models;
mod handlers;
mod error;
mod routes;
mod openai;
mod storage;
mod auth;

// I am importing the necessary types and traits from the Axum web framework and related libraries
use axum::{
    http::{
        header::{CONTENT_TYPE, AUTHORIZATION},
        Method,
    },
    Router,
};
use std::net::SocketAddr;
use tower_http::cors::{Any, CorsLayer};
use tracing_subscriber::{layer::SubscriberExt, util::SubscriberInitExt};

// I am bringing in the route creation and application state from my own modules
use crate::{routes::create_routes, handlers::AppState};

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    // I am loading environment variables from a .env file if it exists
    if let Err(e) = dotenvy::dotenv() {
        // If the .env file is missing, I just log a warning and continue
        tracing::warn!("Could not load .env file: {}", e);
    }

    // I am initializing the tracing subscriber for logging and debugging
    tracing_subscriber::registry()
        .with(
            tracing_subscriber::EnvFilter::try_from_default_env()
                .unwrap_or_else(|_| "quickscan_backend=debug,tower_http=debug".into()),
        )
        .with(tracing_subscriber::fmt::layer())
        .init();

    // I am creating the main application state, which holds all shared services
    let app_state = AppState::new().map_err(|e| {
        tracing::error!("Failed to initialize application state: {}", e);
        anyhow::anyhow!("Failed to initialize application state: {}", e)
    })?;

    // I am checking if the OpenAI API key is set, and logging the AI feature status
    if std::env::var("OPENAI_API_KEY").is_ok() {
        tracing::info!("OpenAI API key found - AI features enabled");
    } else {
        tracing::warn!("OpenAI API key not found - AI features will fail. Set OPENAI_API_KEY environment variable.");
    }

    // I am configuring CORS to allow requests from any origin and common HTTP methods
    let cors = CorsLayer::new()
        .allow_methods([Method::GET, Method::POST, Method::PUT, Method::DELETE])
        .allow_headers([CONTENT_TYPE, AUTHORIZATION])
        .allow_origin(Any);

    // I am building the main Axum router, nesting all API routes under /api, and applying middleware
    let app = Router::new()
        .nest("/api", create_routes())
        .layer(cors)
        .layer(tower_http::trace::TraceLayer::new_for_http())
        .with_state(app_state);

    // I am setting the address for the server to listen on (localhost:3000)
    let addr = SocketAddr::from(([127, 0, 0, 1], 3000));
    tracing::info!("QuickScan backend server starting on {} with AI capabilities", addr);
    
    // I am binding a TCP listener and starting the Axum server
    let listener = tokio::net::TcpListener::bind(addr).await?;
    axum::serve(listener, app).await?;

    Ok(())
}
