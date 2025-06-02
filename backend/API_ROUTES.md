# QuickScan Backend API Routes

## Base URL
All routes are prefixed with `/api`

## Health Check
- **GET** `/api/health` - Check server health status

## Scan Management
- **GET** `/api/scans` - List all scans
- **POST** `/api/scans` - Create a new scan
- **GET** `/api/scans/:id` - Get a specific scan by ID
- **DELETE** `/api/scans/:id` - Delete a specific scan by ID

## File Operations

### File Upload
- **POST** `/api/upload`
- **Content-Type:** `multipart/form-data`
- **Body:** File field named `file`

**Example using curl:**
```bash
curl -X POST http://127.0.0.1:3000/api/upload \
  -F "file=@/path/to/your/document.pdf"
```

**Response:**
```json
{
  "success": true,
  "data": {
    "id": "123e4567-e89b-12d3-a456-426614174000",
    "filename": "document.pdf",
    "file_size": 1024,
    "content_type": "application/pdf",
    "timestamp": "2024-01-01T12:00:00Z",
    "status": "uploaded",
    "storage_type": "Temporary",
    "download_url": null
  },
  "message": "File uploaded successfully"
}
```

### List Uploaded Files
- **GET** `/api/files` - Get list of all uploaded files

**Response:**
```json
{
  "success": true,
  "data": {
    "files": [
      {
        "id": "123e4567-e89b-12d3-a456-426614174000",
        "filename": "document.pdf",
        "file_size": 1024,
        "content_type": "application/pdf",
        "timestamp": "2024-01-01T12:00:00Z",
        "status": "uploaded",
        "storage_type": "Temporary",
        "download_url": null
      }
    ],
    "total_count": 1
  },
  "message": "Files retrieved successfully"
}
```

### Download File
- **GET** `/api/files/:id/download` - Download a file by its ID

**Response:** Binary file data with appropriate headers

### Get Download URL
- **GET** `/api/files/:id/url` - Get a signed download URL for a file

**Response:**
```json
{
  "success": true,
  "data": {
    "id": "123e4567-e89b-12d3-a456-426614174000",
    "filename": "document.pdf",
    "download_url": "https://storage.example.com/signed-url",
    "expires_at": "2024-01-01T13:00:00Z"
  },
  "message": "Download URL generated successfully"
}
```

### Delete File
- **DELETE** `/api/files/:id` - Delete a file by its ID

**Response:**
```json
{
  "success": true,
  "data": "File 123e4567-e89b-12d3-a456-426614174000 deleted",
  "message": "File deleted successfully"
}
```

### Cleanup Temporary Files
- **POST** `/api/files/cleanup` - Clean up expired temporary files (24+ hours old)

**Response:**
```json
{
  "success": true,
  "data": "Cleaned up 5 expired files",
  "message": "Cleanup completed successfully"
}
```

## AI Features

### Document Summarization
- **POST** `/api/summarize`
- **Content-Type:** `application/json`

**Request Body:**
```json
{
  "content": "Your document content here...",
  "max_length": 200  // Optional, defaults to 200 characters
}
```

**Example using curl:**
```bash
curl -X POST http://127.0.0.1:3000/api/summarize \
  -H "Content-Type: application/json" \
  -d '{
    "content": "This is a long document that needs to be summarized. It contains many paragraphs and detailed information about various topics...",
    "max_length": 100
  }'
```

**Response:**
```json
{
  "success": true,
  "data": {
    "id": "123e4567-e89b-12d3-a456-426614174000",
    "original_content": "This is a long document...",
    "summary": "This is a long document that needs to be summarized...",
    "original_length": 150,
    "summary_length": 100,
    "timestamp": "2024-01-01T12:00:00Z"
  },
  "message": "Document summarized successfully"
}
```

### Chat Completion
- **POST** `/api/chat/completion`
- **Content-Type:** `application/json`

**Request Body:**
```json
{
  "content": "What is the capital of France?",
  "model": "gpt-4o-mini",  // Optional
  "temperature": 0.7,      // Optional, 0.0-2.0
  "max_tokens": 1000,      // Optional
  "system_prompt": "You are a helpful assistant."  // Optional
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "id": "123e4567-e89b-12d3-a456-426614174000",
    "content": "The capital of France is Paris.",
    "model": "gpt-4o-mini",
    "usage": {
      "prompt_tokens": 15,
      "completion_tokens": 8,
      "total_tokens": 23
    },
    "timestamp": "2024-01-01T12:00:00Z"
  },
  "message": "Chat completion generated successfully"
}
```

## Storage Configuration

The backend supports two storage types:

### Temporary Storage (Default)
Files are stored in the local filesystem temp directory. Suitable for development and testing.

### Supabase Storage
Files are stored in Supabase Storage buckets. Recommended for production.

To configure Supabase storage, set these environment variables:
```bash
STORAGE_TYPE=supabase
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key-here
SUPABASE_BUCKET=uploads
```

## Error Responses

All endpoints return error responses in the following format:

```json
{
  "success": false,
  "error": {
    "type": "validation_error",
    "message": "Error description",
    "status": 400
  },
  "timestamp": "2024-01-01T12:00:00Z"
}
```

### Common Error Types
- `validation_error` - Invalid request data
- `not_found` - Resource not found
- `storage_error` - File storage operation failed
- `external_service_error` - AI service unavailable
- `internal_error` - Server error

## Development

To start the development server:
```bash
cd backend
cargo run
```

The server will be available at `http://127.0.0.1:3000`

## File Upload Limits
- Maximum file size: 10MB
- Supported formats: All file types
- Temporary files are automatically cleaned up after 24 hours 