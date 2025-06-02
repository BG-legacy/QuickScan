# QuickScan Authentication System

QuickScan now includes a complete authentication system with both email/password and token-based authentication methods.

## Features

### Authentication Methods
1. **Email & Password Authentication**
   - User registration with email validation
   - Secure password hashing using bcrypt
   - JWT token generation for session management

2. **API Token Authentication**
   - Pre-configured demo tokens for quick testing
   - Service-to-service authentication support
   - Bypass traditional login for development/testing

### Security Features
- Password hashing with bcrypt (default cost: 12)
- JWT tokens with configurable expiration (default: 24 hours)
- Token validation and automatic refresh
- Secure token storage in iOS KeyChain-equivalent (UserDefaults for demo)

## Backend API Endpoints

### Authentication Routes
- `POST /api/auth/register` - Register new user
- `POST /api/auth/login` - Login with email/password
- `POST /api/auth/token` - Login with API token
- `GET /api/auth/me` - Get current user info (requires Bearer token)
- `POST /api/auth/verify` - Verify JWT token

### Example Requests

#### Register User
```bash
curl -X POST http://127.0.0.1:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@example.com",
    "password": "securepassword123",
    "confirm_password": "securepassword123"
  }'
```

#### Login User
```bash
curl -X POST http://127.0.0.1:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@example.com",
    "password": "securepassword123"
  }'
```

#### Token Authentication
```bash
curl -X POST http://127.0.0.1:3000/api/auth/token \
  -H "Content-Type: application/json" \
  -d '{
    "token": "quickscan-api-token-2024"
  }'
```

#### Get Current User
```bash
curl -X GET http://127.0.0.1:3000/api/auth/me \
  -H "Authorization: Bearer YOUR_JWT_TOKEN_HERE"
```

## Demo Tokens

For testing and development, the following tokens are pre-configured:
- `quickscan-api-token-2024`
- `demo-token-12345`
- `test-api-key-abcdef`

## Frontend Integration

### Authentication Flow
1. App launches and checks for stored JWT token
2. If token exists, validates it with the backend
3. If no token or invalid token, shows authentication screen
4. User can choose email/password or token authentication
5. Successful authentication stores JWT token locally
6. App shows main interface with user profile access

### Key Components
- `AuthService`: Handles all authentication logic
- `AuthView`: Login/register screen with dual authentication modes
- `UserProfileView`: User information and logout functionality
- `ContentView`: Main app that conditionally shows auth or main interface

### Authentication States
```swift
enum AuthState {
    case unauthenticated
    case loading
    case authenticated(User)
    case error(String)
}
```

## Configuration

### Backend Environment Variables
Create a `.env` file in the backend directory:

```env
# OpenAI Configuration
OPENAI_API_KEY=your_openai_api_key_here

# JWT Configuration (change in production!)
JWT_SECRET=your-super-secret-jwt-key-change-this-in-production

# Server Configuration
RUST_LOG=debug

# Storage Configuration
STORAGE_PATH=./temp_storage
```

### Security Considerations

#### Development vs Production
- Current implementation uses in-memory storage (DashMap) for users
- In production, replace with proper database (PostgreSQL, MySQL, etc.)
- Change JWT secret to a cryptographically secure random string
- Implement proper session management and token blacklisting

#### Password Requirements
- Minimum 8 characters
- Maximum 128 characters
- Uses bcrypt with default cost (currently 12)

#### Token Expiration
- JWT tokens expire after 24 hours by default
- Frontend automatically handles token refresh
- Invalid tokens trigger re-authentication

## UI Features

### Modern Design
- Beautiful gradient backgrounds
- Smooth animations and transitions
- Dark mode support
- Responsive layout for different screen sizes

### User Experience
- Clear validation messages
- Loading states with progress indicators
- Easy switching between authentication modes
- One-tap demo token selection

### Accessibility
- Proper semantic labels
- Keyboard navigation support
- Screen reader compatible
- High contrast support

## Development Setup

### Backend
```bash
cd backend
cargo run
```

### Frontend
Open `frontend/QuickScan.xcodeproj` in Xcode and run the app.

### Testing Authentication
1. Start the backend server
2. Launch the iOS app
3. Try registering a new user or using demo tokens
4. Test login/logout functionality
5. Verify JWT token handling

## Future Enhancements

### Planned Features
- Password reset functionality
- Email verification
- Multi-factor authentication (MFA)
- Social login (Google, Apple, etc.)
- Role-based access control
- Session management dashboard

### Database Integration
- User persistence with PostgreSQL/MySQL
- Migration scripts
- User profile management
- Audit logging

### Advanced Security
- Rate limiting for authentication endpoints
- Account lockout after failed attempts
- Security headers and CORS policies
- Token blacklisting and refresh tokens 