# QuickScan Backend

A Rust-based backend API for QuickScan with AI capabilities and flexible file storage.

## Features

- **File Upload & Storage**: Support for both temporary and Supabase storage
- **AI Integration**: OpenAI-powered document analysis and summarization
- **Scan Management**: Create, retrieve, and manage scans
- **File Management**: Upload, download, list, and delete files
- **RESTful API**: Clean, documented API endpoints
- **Flexible Storage**: Switch between local temporary storage and Supabase Storage

## Quick Start

### Prerequisites

- Rust 1.70+ installed
- OpenAI API key (optional, for AI features)
- Supabase project (optional, for cloud storage)

### Installation

1. Clone the repository and navigate to the backend directory:
```bash
cd backend
```

2. Copy the environment template:
```bash
cp env.example .env
```

3. Configure your environment variables in `.env`:
```bash
# OpenAI Configuration (optional)
OPENAI_API_KEY=your_openai_api_key_here

# Storage Configuration
STORAGE_TYPE=temporary  # or "supabase"

# Supabase Configuration (required if STORAGE_TYPE=supabase)
# SUPABASE_URL=https://your-project.supabase.co
# SUPABASE_ANON_KEY=your-anon-key-here
# SUPABASE_BUCKET=uploads
```

4. Run the server:
```bash
cargo run
```

The server will start on `http://127.0.0.1:3000`

## Storage Configuration

### Temporary Storage (Default)

Files are stored in the system's temporary directory. This is perfect for development and testing.

**Pros:**
- No external dependencies
- Fast local access
- Zero configuration

**Cons:**
- Files may be deleted on system restart
- Not suitable for production
- No persistence across deployments

### Supabase Storage

Files are stored in Supabase Storage buckets with support for signed URLs and public access.

**Pros:**
- Persistent cloud storage
- Scalable and reliable
- Built-in CDN
- Signed URL support

**Cons:**
- Requires Supabase setup
- Network latency for access

To enable Supabase storage:

1. Create a Supabase project at [supabase.com](https://supabase.com)
2. Create a storage bucket (default: "uploads")
3. Get your project URL and anon key
4. Set environment variables:
```bash
STORAGE_TYPE=supabase
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key-here
SUPABASE_BUCKET=uploads
```

## API Endpoints

### Health Check
```
GET /api/health
```

### File Operations
```
POST /api/upload              # Upload a file
GET  /api/files               # List all files
GET  /api/files/:id/download  # Download a file
GET  /api/files/:id/url       # Get signed download URL
DELETE /api/files/:id         # Delete a file
POST /api/files/cleanup       # Clean up expired temp files
```

### Scan Management
```
GET    /api/scans            # List all scans
POST   /api/scans            # Create a new scan
GET    /api/scans/:id        # Get a specific scan
DELETE /api/scans/:id        # Delete a scan
```

### AI Features (requires OpenAI API key)
```
POST /api/summarize          # Summarize document content
POST /api/chat/completion    # AI chat completion
```

## Example Usage

### Upload a File
```bash
curl -X POST http://127.0.0.1:3000/api/upload \
  -F "file=@document.pdf"
```

### List Files
```bash
curl -X GET http://127.0.0.1:3000/api/files
```

### Download a File
```bash
curl -X GET http://127.0.0.1:3000/api/files/{file-id}/download \
  -o downloaded_file.pdf
```

### Summarize Text
```bash
curl -X POST http://127.0.0.1:3000/api/summarize \
  -H "Content-Type: application/json" \
  -d '{
    "content": "Your long document text here...",
    "max_length": 200
  }'
```

## File Upload Limits

- Maximum file size: 10MB
- All file types supported
- Temporary files auto-cleanup after 24 hours

## Development

### Building
```bash
cargo build
```

### Testing
```bash
cargo test
```

### Running in Development
```bash
cargo run
```

### Code Formatting
```bash
cargo fmt
```

### Linting
```bash
cargo clippy
```

## Environment Variables

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `OPENAI_API_KEY` | OpenAI API key for AI features | - | No |
| `STORAGE_TYPE` | Storage backend (`temporary` or `supabase`) | `temporary` | No |
| `SUPABASE_URL` | Supabase project URL | - | If using Supabase |
| `SUPABASE_ANON_KEY` | Supabase anonymous key | - | If using Supabase |
| `SUPABASE_BUCKET` | Supabase storage bucket name | `uploads` | No |
| `RUST_LOG` | Log level configuration | `info` | No |

## Error Handling

The API returns consistent error responses:

```json
{
  "success": false,
  "error": {
    "type": "error_type",
    "message": "Error description",
    "status": 400
  },
  "timestamp": "2024-01-01T12:00:00Z"
}
```

## Project Structure

```
backend/
├── src/
│   ├── main.rs          # Application entry point
│   ├── handlers.rs      # HTTP request handlers
│   ├── routes.rs        # Route definitions
│   ├── models.rs        # Data models and validation
│   ├── storage.rs       # File storage abstraction
│   ├── openai.rs        # OpenAI integration
│   └── error.rs         # Error types and handling
├── Cargo.toml           # Dependencies and metadata
├── env.example          # Environment variables template
└── README.md           # This file
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Run `cargo fmt` and `cargo clippy`
6. Submit a pull request

## License

This project is licensed under the MIT License.

## Troubleshooting

### Common Issues

**Server won't start:**
- Check that port 3000 is available
- Verify environment variables are set correctly
- Check the logs for specific error messages

**File uploads fail:**
- Ensure the file is under 10MB
- Check storage configuration
- Verify Supabase credentials if using cloud storage

**AI features not working:**
- Verify `OPENAI_API_KEY` is set correctly
- Check your OpenAI account has available credits
- Ensure the API key has proper permissions

**Supabase storage issues:**
- Verify the bucket exists in your Supabase project
- Check the bucket permissions (should allow uploads)
- Ensure the anon key has storage permissions 