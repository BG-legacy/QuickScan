# QuickScan

A modern document scanning and AI-powered analysis app with secure user authentication.

## ✨ Features

### 🔐 Authentication System
- **Email & Password Authentication** - Secure user registration and login
- **API Token Authentication** - Quick access with pre-configured demo tokens
- **JWT Security** - Industry-standard token-based authentication
- **Modern UI** - Beautiful login/register screens with dual authentication modes

### 📱 Document Processing
- **Camera Scanning** - Use your device camera to scan documents
- **File Upload** - Choose files from your device storage
- **AI Analysis** - OpenAI-powered document analysis and summarization
- **Cloud Storage** - Secure file storage with download capabilities

### 🎨 User Experience
- **Responsive Design** - Works beautifully on all screen sizes
- **Smooth Animations** - Polished transitions and loading states
- **Accessibility** - Screen reader compatible with proper semantic labels

## 🚀 Quick Start

### Prerequisites
- **Backend**: Rust 1.70+ and Cargo
- **Frontend**: Xcode 15+ and iOS 16+
- **Optional**: OpenAI API key for AI features

### Backend Setup
```bash
cd backend
cargo run
```

### Frontend Setup
1. Open `frontend/QuickScan.xcodeproj` in Xcode
2. Run the app on simulator or device

### Authentication Demo
1. Launch the app
2. Choose "API Token" authentication mode
3. Use one of these demo tokens:
   - `quickscan-api-token-2024`
   - `demo-token-12345`
   - `test-api-key-abcdef`
4. Or register with email/password for full functionality

## 📚 Documentation

- [**Authentication Guide**](AUTHENTICATION.md) - Complete authentication system documentation
- [**API Reference**](docs/api.md) - Backend API endpoints and examples
- [**Frontend Architecture**](docs/frontend.md) - iOS app structure and components

## 🛠️ Technology Stack

### Backend (Rust)
- **Axum** - Modern async web framework
- **JWT** - JSON Web Token authentication
- **bcrypt** - Secure password hashing
- **OpenAI API** - AI-powered document analysis
- **Serde** - JSON serialization/deserialization

### Frontend (Swift/SwiftUI)
- **SwiftUI** - Declarative UI framework
- **Vision Kit** - Document scanning capabilities
- **Combine** - Reactive programming for data flow
- **URLSession** - Network communication

## 🔒 Security Features

- **Password Hashing** - bcrypt with configurable cost
- **JWT Tokens** - Secure token-based authentication
- **Input Validation** - Server-side validation with detailed error messages
- **CORS Protection** - Configured for secure cross-origin requests
- **Token Expiration** - Automatic token refresh and re-authentication

## 🎯 API Endpoints

### Authentication
- `POST /api/auth/register` - Register new user
- `POST /api/auth/login` - Login with credentials
- `POST /api/auth/token` - Authenticate with API token
- `GET /api/auth/me` - Get current user info

### Document Processing
- `POST /api/upload` - Upload and process documents
- `POST /api/summarize` - AI-powered document summarization
- `GET /api/files` - List uploaded files
- `DELETE /api/files/:id` - Delete files

### Health & Monitoring
- `GET /api/health` - Service health check

## 🌟 Demo Credentials

For quick testing, use these pre-configured tokens:
- `quickscan-api-token-2024` - Full access demo token
- `demo-token-12345` - Standard demo token  
- `test-api-key-abcdef` - Testing token

## 📱 Screenshots

*Coming soon - Login screen, main interface, and document scanning views*

## 🔄 Development Workflow

1. **Start Backend**: `cd backend && cargo run`
2. **Open Frontend**: Launch Xcode project
3. **Test Authentication**: Use demo tokens or register new user
4. **Scan Documents**: Test camera scanning and file upload
5. **AI Analysis**: Verify summarization with OpenAI integration

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙋‍♂️ Support

For questions, issues, or feature requests, please open an issue on GitHub or contact the development team.

---

**QuickScan** - Secure document scanning with AI-powered analysis 🚀