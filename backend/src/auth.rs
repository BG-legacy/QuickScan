// I am importing the necessary crates for password hashing, time handling, JWT, and concurrency
use bcrypt::{hash, verify, DEFAULT_COST};
use chrono::{Duration, Utc};
use dashmap::DashMap;
use jsonwebtoken::{decode, encode, Algorithm, DecodingKey, EncodingKey, Header, Validation};
use std::sync::Arc;
use uuid::Uuid;

// I am importing my own error and model types
use crate::{
    error::{AppError, Result},
    models::{Claims, User, UserResponse},
};

// I am defining the authentication service, which manages users and JWTs
#[derive(Clone)]
pub struct AuthService {
    // In production, this would be a proper database
    users: Arc<DashMap<String, User>>, // email -> User
    jwt_secret: String,
    jwt_expiration_hours: i64,
}

impl AuthService {
    // I am creating a new AuthService, loading the JWT secret from the environment or using a default
    pub fn new() -> Self {
        // In production, load this from environment variables
        let jwt_secret = std::env::var("JWT_SECRET")
            .unwrap_or_else(|_| "your-secret-key-change-this-in-production".to_string());

        Self {
            users: Arc::new(DashMap::new()),
            jwt_secret,
            jwt_expiration_hours: 24, // 24 hours
        }
    }

    // I am registering a new user, hashing their password and storing them in memory
    pub async fn register_user(&self, email: String, password: String) -> Result<UserResponse> {
        // Check if user already exists
        if self.users.contains_key(&email) {
            return Err(AppError::ValidationError("User already exists".to_string()));
        }

        // Hash password
        let password_hash = hash(password, DEFAULT_COST)
            .map_err(|e| AppError::InternalError(format!("Failed to hash password: {}", e)))?;

        // Create user
        let user = User {
            id: Uuid::new_v4(),
            email: email.clone(),
            password_hash,
            created_at: Utc::now().to_rfc3339(),
            updated_at: Utc::now().to_rfc3339(),
            is_active: true,
        };

        let user_response = UserResponse::from(user.clone());
        
        // Store user
        self.users.insert(email, user);

        Ok(user_response)
    }

    // I am authenticating a user by verifying their password
    pub async fn authenticate_user(&self, email: String, password: String) -> Result<UserResponse> {
        // Find user
        let user = self
            .users
            .get(&email)
            .ok_or_else(|| AppError::AuthError("Invalid credentials".to_string()))?;

        // Verify password
        let password_valid = verify(password, &user.password_hash)
            .map_err(|e| AppError::InternalError(format!("Failed to verify password: {}", e)))?;

        if !password_valid {
            return Err(AppError::AuthError("Invalid credentials".to_string()));
        }

        if !user.is_active {
            return Err(AppError::AuthError("Account is inactive".to_string()));
        }

        Ok(UserResponse::from(user.clone()))
    }

    // I am generating a JWT token for a user
    pub fn generate_token(&self, user: &UserResponse) -> Result<(String, String)> {
        let expiration = Utc::now() + Duration::hours(self.jwt_expiration_hours);
        let exp = expiration.timestamp() as usize;
        let iat = Utc::now().timestamp() as usize;

        let claims = Claims {
            sub: user.id.to_string(),
            email: user.email.clone(),
            exp,
            iat,
        };

        let token = encode(
            &Header::default(),
            &claims,
            &EncodingKey::from_secret(self.jwt_secret.as_ref()),
        )
        .map_err(|e| AppError::InternalError(format!("Failed to generate token: {}", e)))?;

        Ok((token, expiration.to_rfc3339()))
    }

    // I am validating a JWT token and extracting its claims
    pub fn validate_token(&self, token: &str) -> Result<Claims> {
        let token_data = decode::<Claims>(
            token,
            &DecodingKey::from_secret(self.jwt_secret.as_ref()),
            &Validation::new(Algorithm::HS256),
        )
        .map_err(|e| AppError::AuthError(format!("Invalid token: {}", e)))?;

        Ok(token_data.claims)
    }

    // I am retrieving a user by their UUID
    pub async fn get_user_by_id(&self, user_id: &str) -> Result<UserResponse> {
        let uuid = Uuid::parse_str(user_id)
            .map_err(|_| AppError::ValidationError("Invalid user ID".to_string()))?;

        // Find user by ID (iterate through all users)
        for entry in self.users.iter() {
            if entry.value().id == uuid {
                return Ok(UserResponse::from(entry.value().clone()));
            }
        }

        Err(AppError::NotFoundError("User not found".to_string()))
    }

    // I am retrieving a user by their email address
    pub async fn get_user_by_email(&self, email: &str) -> Result<UserResponse> {
        let user = self
            .users
            .get(email)
            .ok_or_else(|| AppError::NotFoundError("User not found".to_string()))?;

        Ok(UserResponse::from(user.clone()))
    }

    // I am authenticating using a static API token (for demo or service use)
    pub async fn authenticate_with_token(&self, token: &str) -> Result<UserResponse> {
        // For simplicity, we'll use a predefined token
        // In production, you'd store these in a database with expiration dates
        let valid_tokens = [
            "quickscan-api-token-2024",
            "demo-token-12345",
            "test-api-key-abcdef",
        ];

        if !valid_tokens.contains(&token) {
            return Err(AppError::AuthError("Invalid API token".to_string()));
        }

        // Create a dummy user for token-based auth
        // In production, tokens would be associated with real users
        Ok(UserResponse {
            id: Uuid::new_v4(),
            email: "token-user@quickscan.app".to_string(),
            created_at: Utc::now().to_rfc3339(),
            is_active: true,
        })
    }
}

// I am providing a default implementation for AuthService
impl Default for AuthService {
    fn default() -> Self {
        Self::new()
    }
} 