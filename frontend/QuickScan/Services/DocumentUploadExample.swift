import Foundation
import SwiftUI
import UIKit

/// Comprehensive examples showing how to use the new uploadDocument functionality
/// This file demonstrates various document upload scenarios using URLSession
class DocumentUploadExample {
    
    private let apiService = APIService.shared
    
    // MARK: - Basic Document Upload Examples
    
    /// Example 1: Upload a document from Data with progress tracking
    func uploadDocumentWithProgress() async {
        // Sample document data (in real app, this would come from file picker or camera)
        guard let documentData = "Sample document content".data(using: .utf8) else {
            print("❌ Failed to create document data")
            return
        }
        
        print("📄 Starting document upload with progress tracking...")
        
        do {
            let uploadedFile = try await apiService.uploadDocument(
                data: documentData,
                filename: "sample_document.txt",
                mimeType: "text/plain"
            ) { progress in
                // Update UI with progress
                DispatchQueue.main.async {
                    print("📊 Upload progress: \(Int(progress * 100))%")
                    // Update your progress bar here
                }
            }
            
            print("✅ Document uploaded successfully!")
            print("   File ID: \(uploadedFile.id)")
            print("   Filename: \(uploadedFile.filename)")
            print("   Size: \(uploadedFile.formattedFileSize)")
            print("   Upload time: \(uploadedFile.formattedTimestamp)")
            
        } catch {
            print("❌ Upload failed: \(error.localizedDescription)")
        }
    }
    
    /// Example 2: Upload an image document from camera/photo library
    func uploadImageDocument(image: UIImage) async {
        print("📷 Uploading image document...")
        
        do {
            let uploadedFile = try await apiService.uploadImageDocument(
                image: image,
                filename: "scanned_document.jpg",
                quality: 0.9
            ) { progress in
                print("📊 Image upload progress: \(Int(progress * 100))%")
            }
            
            print("✅ Image document uploaded successfully!")
            print("   File ID: \(uploadedFile.id)")
            print("   Size: \(uploadedFile.formattedFileSize)")
            
        } catch {
            print("❌ Image upload failed: \(error.localizedDescription)")
        }
    }
    
    /// Example 3: Upload a document from file URL (file picker)
    func uploadDocumentFromFile(fileURL: URL) async {
        print("📂 Uploading document from file URL...")
        
        do {
            let uploadedFile = try await apiService.uploadDocument(from: fileURL) { progress in
                print("📊 File upload progress: \(Int(progress * 100))%")
            }
            
            print("✅ File uploaded successfully!")
            print("   Original filename: \(uploadedFile.filename)")
            print("   Content type: \(uploadedFile.contentType)")
            
        } catch {
            print("❌ File upload failed: \(error.localizedDescription)")
        }
    }
    
    /// Example 4: Upload text content as document
    func uploadTextAsDocument(text: String) async {
        print("📝 Uploading text as document...")
        
        do {
            let uploadedFile = try await apiService.uploadTextDocument(
                text: text,
                filename: "extracted_text.txt"
            ) { progress in
                print("📊 Text upload progress: \(Int(progress * 100))%")
            }
            
            print("✅ Text document uploaded successfully!")
            print("   File ID: \(uploadedFile.id)")
            
        } catch {
            print("❌ Text upload failed: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Batch Upload Examples
    
    /// Example 5: Upload multiple documents at once
    func uploadMultipleDocuments() async {
        print("📚 Starting batch document upload...")
        
        // Prepare multiple documents
        let documents: [(data: Data, filename: String, mimeType: String)] = [
            ("Document 1 content".data(using: .utf8)!, "doc1.txt", "text/plain"),
            ("Document 2 content".data(using: .utf8)!, "doc2.txt", "text/plain"),
            ("Document 3 content".data(using: .utf8)!, "doc3.txt", "text/plain")
        ]
        
        do {
            let uploadedFiles = try await apiService.uploadDocuments(
                documents: documents
            ) { currentFile, totalFiles, overallProgress in
                print("📊 Uploading file \(currentFile)/\(totalFiles) - Overall progress: \(Int(overallProgress * 100))%")
            }
            
            print("✅ Batch upload completed!")
            print("   Uploaded \(uploadedFiles.count) documents successfully")
            
            for file in uploadedFiles {
                print("   - \(file.filename) (\(file.formattedFileSize))")
            }
            
        } catch {
            print("❌ Batch upload failed: \(error.localizedDescription)")
        }
    }
    
    // MARK: - SwiftUI Integration Examples
    
    /// Example 6: SwiftUI ViewModel integration
    @MainActor
    class DocumentUploadViewModel: ObservableObject {
        @Published var uploadProgress: Double = 0.0
        @Published var isUploading: Bool = false
        @Published var uploadedFiles: [UploadedFile] = []
        @Published var errorMessage: String?
        
        private let apiService = APIService.shared
        
        func uploadDocument(data: Data, filename: String, mimeType: String) async {
            isUploading = true
            uploadProgress = 0.0
            errorMessage = nil
            
            do {
                let uploadedFile = try await apiService.uploadDocument(
                    data: data,
                    filename: filename,
                    mimeType: mimeType
                ) { [weak self] progress in
                    self?.uploadProgress = progress
                }
                
                uploadedFiles.append(uploadedFile)
                
            } catch {
                errorMessage = error.localizedDescription
            }
            
            isUploading = false
        }
        
        func uploadImage(_ image: UIImage, filename: String) async {
            isUploading = true
            uploadProgress = 0.0
            errorMessage = nil
            
            do {
                let uploadedFile = try await apiService.uploadImageDocument(
                    image: image,
                    filename: filename
                ) { [weak self] progress in
                    self?.uploadProgress = progress
                }
                
                uploadedFiles.append(uploadedFile)
                
            } catch {
                errorMessage = error.localizedDescription
            }
            
            isUploading = false
        }
    }
    
    // MARK: - Error Handling Examples
    
    /// Example 7: Comprehensive error handling
    func uploadWithErrorHandling(data: Data, filename: String, mimeType: String) async -> Bool {
        do {
            let uploadedFile = try await apiService.uploadDocument(
                data: data,
                filename: filename,
                mimeType: mimeType
            )
            
            print("✅ Upload successful: \(uploadedFile.filename)")
            return true
            
        } catch APIServiceError.serverError(let message) {
            print("❌ Server error: \(message)")
            
            // Handle specific server errors
            if message.contains("size exceeds") {
                print("💡 Suggestion: Try compressing the document or splitting it into smaller parts")
            } else if message.contains("Unsupported") {
                print("💡 Suggestion: Convert the document to a supported format (PDF, DOCX, TXT, JPG, PNG)")
            } else if message.contains("Authentication required") {
                print("💡 Suggestion: Please log in again")
                // Trigger re-authentication
            }
            
        } catch APIServiceError.networkError(let error) {
            print("❌ Network error: \(error.localizedDescription)")
            print("💡 Suggestion: Check your internet connection and try again")
            
        } catch APIServiceError.invalidResponse {
            print("❌ Invalid response from server")
            print("💡 Suggestion: The server might be temporarily unavailable")
            
        } catch APIServiceError.noData {
            print("❌ No data received from server")
            print("💡 Suggestion: Try uploading again")
            
        } catch {
            print("❌ Unexpected error: \(error.localizedDescription)")
        }
        
        return false
    }
}

// MARK: - Usage Documentation
/*
 
 COMPREHENSIVE UPLOAD DOCUMENT USAGE GUIDE:
 
 The uploadDocument function provides a robust, feature-rich way to upload documents
 using URLSession with the following capabilities:
 
 ✅ FEATURES:
 - Progress tracking for real-time upload updates
 - Document type validation (PDF, DOCX, TXT, JPG, PNG, HEIC)
 - File size validation (10MB limit)
 - Comprehensive error handling with specific HTTP status codes
 - Batch upload support for multiple documents
 - Convenience methods for common scenarios
 - SwiftUI integration ready
 - Secure authentication via JWT tokens
 
 📝 BASIC USAGE:
 
 ```swift
 let apiService = APIService.shared
 
 // Upload with progress tracking
 let uploadedFile = try await apiService.uploadDocument(
     data: documentData,
     filename: "my_document.pdf",
     mimeType: "application/pdf"
 ) { progress in
     print("Upload progress: \(Int(progress * 100))%")
 }
 ```
 
 🖼️ IMAGE UPLOAD:
 
 ```swift
 let uploadedFile = try await apiService.uploadImageDocument(
     image: capturedImage,
     filename: "scanned_page.jpg",
     quality: 0.9
 ) { progress in
     // Update progress bar
 }
 ```
 
 📂 FILE URL UPLOAD:
 
 ```swift
 let uploadedFile = try await apiService.uploadDocument(from: fileURL) { progress in
     // Track progress
 }
 ```
 
 📚 BATCH UPLOAD:
 
 ```swift
 let documents = [(data1, "file1.pdf", "application/pdf"), ...]
 let uploadedFiles = try await apiService.uploadDocuments(documents: documents) 
 { currentFile, totalFiles, overallProgress in
     // Track overall progress
 }
 ```
 
 🚨 ERROR HANDLING:
 
 The function throws specific APIServiceError types for different scenarios:
 - .serverError("Document size exceeds 10MB limit")
 - .serverError("Unsupported document type")
 - .serverError("Authentication required")
 - .networkError(underlying network error)
 - .invalidResponse (malformed server response)
 - .noData (empty response)
 
 💡 BEST PRACTICES:
 
 1. Always handle errors appropriately
 2. Use progress handlers for better UX
 3. Validate documents on client side before upload
 4. Consider compression for large images
 5. Implement retry logic for network failures
 6. Cache uploaded file references for offline access
 7. Use batch upload for multiple files to improve performance
 
 */ 