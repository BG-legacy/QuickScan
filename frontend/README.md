# QuickScan iOS App

A beautiful, modern iOS application built with SwiftUI that allows users to scan documents and get AI-powered summaries.

## Features

### 📱 **Clean SwiftUI Design**
- Modern, intuitive interface that adapts to both light and dark modes
- Smooth animations and transitions
- Accessibility-focused design

### 📄 **Document Input Methods**
- **Camera Scanner**: Built-in document scanner using VisionKit
- **File Picker**: Select files from device storage (PDF, images, text files)

### 🤖 **AI-Powered Summarization**
- Real-time text summarization using the QuickScan backend API
- Compression statistics and analysis
- Shareable summaries

### 🎨 **Modern UI/UX**
- Gradient backgrounds and button styles
- Loading animations with progress indicators
- Error handling with retry functionality
- Responsive design for iPhone and iPad

### 🌓 **Dark Mode Support**
- Fully compatible with iOS light and dark mode
- Automatic theme switching
- Consistent visual experience across modes

## Screenshots

### Main Interface
- Clean welcome screen with feature highlights
- Prominent action buttons for scanning and file selection
- Beautiful gradient designs and SF Symbols

### Document Processing
- Animated loading states during upload and processing
- Progress feedback for user actions
- Professional error handling with retry options

### Summary Results
- Elegant summary display with statistics
- Expandable original content view
- Share functionality for summaries

## Technical Stack

### **SwiftUI Framework**
- Native iOS development with SwiftUI
- Declarative UI programming
- MVVM architecture pattern

### **Key Dependencies**
- **VisionKit**: Document scanning functionality
- **UniformTypeIdentifiers**: File type handling
- **Foundation**: Core networking and data handling

### **API Integration**
- RESTful API communication with QuickScan backend
- Async/await networking patterns
- Proper error handling and response parsing

## Project Structure

```
QuickScan/
├── QuickScanApp.swift          # App entry point
├── ContentView.swift           # Main app coordinator
├── Models/
│   └── Models.swift           # Data models and API response types
├── Services/
│   └── APIService.swift       # Backend API communication
├── Views/
│   ├── DocumentScannerView.swift    # Camera document scanning
│   ├── FilePickerView.swift         # File selection interface
│   ├── SummaryResultsView.swift     # AI summary display
│   ├── LoadingView.swift            # Animated loading states
│   └── ErrorView.swift              # Error handling UI
└── Assets.xcassets/           # App icons and visual assets
```

## Key Components

### **APIService**
- Singleton service for backend communication
- Handles file uploads, text summarization, and error management
- Built with modern async/await patterns

### **ContentView**
- Main app coordinator managing application state
- Orchestrates navigation between different views
- Handles file processing workflow

### **Document Scanner**
- Native VisionKit integration for document scanning
- Multi-page document support
- Automatic image processing and optimization

### **File Picker**
- Universal document picker supporting multiple file types
- Security-scoped resource access
- Type validation and error handling

### **Summary Display**
- Beautiful results presentation with statistics
- Expandable content sections
- Native sharing capabilities

## Backend Integration

The app communicates with the QuickScan Rust backend API:

### **Endpoints Used**
- `POST /api/upload` - File upload
- `POST /api/summarize` - Text summarization
- `GET /api/health` - Server health check

### **Data Flow**
1. User selects document (camera or file picker)
2. File is uploaded to backend server
3. Text content is extracted and sent for summarization
4. AI-generated summary is displayed with statistics

## Requirements

### **iOS Version**
- iOS 17.0 or later
- iPhone and iPad compatible

### **Xcode**
- Xcode 15.0 or later
- Swift 5.9+

### **Permissions**
- Camera access for document scanning
- Photo library access for file selection

## Setup Instructions

### **1. Open Project**
```bash
open QuickScan.xcodeproj
```

### **2. Configure Backend URL**
Update the `baseURL` in `APIService.swift` to point to your backend:
```swift
private let baseURL = "http://your-backend-url:3000/api"
```

### **3. Build and Run**
- Select your target device or simulator
- Press Cmd+R to build and run

## Features in Detail

### **Document Scanning**
- Uses Apple's VisionKit framework for professional document scanning
- Automatic edge detection and perspective correction
- Multi-page document support
- High-quality image capture

### **File Selection**
- Support for multiple file types: PDF, images, text files, Word documents
- Native iOS document picker integration
- Secure file access with proper permission handling

### **AI Summarization**
- Real-time text summarization via backend API
- Compression statistics showing original vs. summary length
- Percentage reduction calculation
- Professional error handling for API failures

### **User Experience**
- Smooth animations and transitions
- Loading states with progress feedback
- Error recovery with retry functionality
- Share functionality for summaries
- Dark mode compatibility

## Error Handling

The app includes comprehensive error handling:

### **Network Errors**
- Connection timeout handling
- Server error response parsing
- User-friendly error messages

### **File Processing Errors**
- Invalid file type detection
- File size limit validation
- Permission denial handling

### **UI Error States**
- Animated error displays
- Retry functionality
- Graceful degradation

## Accessibility

The app is built with accessibility in mind:

### **VoiceOver Support**
- Proper accessibility labels and hints
- Logical navigation order
- Dynamic type support

### **Visual Accessibility**
- High contrast support
- Respect for user font size preferences
- Clear visual hierarchy

## Performance Optimization

### **Memory Management**
- Efficient image handling and compression
- Proper disposal of large data objects
- Optimized networking with URLSession

### **UI Performance**
- Smooth animations with optimized view updates
- Lazy loading for large content
- Efficient state management

## Future Enhancements

### **Planned Features**
- OCR integration for better text extraction
- Multiple language support
- Document history and storage
- Advanced AI features (Q&A, translation)
- Offline mode capabilities

### **Technical Improvements**
- Unit test coverage
- CI/CD integration
- Performance monitoring
- Crash reporting

## Development Notes

### **Architecture Decisions**
- **MVVM Pattern**: Clear separation of concerns
- **Async/Await**: Modern networking patterns
- **SwiftUI**: Declarative, reactive UI framework
- **Single Responsibility**: Each view has a focused purpose

### **Code Quality**
- Comprehensive documentation
- Consistent naming conventions
- Error handling throughout
- Preview support for all views

This iOS app provides a polished, professional experience for document scanning and AI-powered summarization, showcasing modern iOS development practices and beautiful SwiftUI design. 