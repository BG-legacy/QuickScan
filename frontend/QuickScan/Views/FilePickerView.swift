import SwiftUI
import UniformTypeIdentifiers

struct FilePickerView: UIViewControllerRepresentable {
    let onFileSelected: (Data, String) -> Void
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [
            .pdf,
            .plainText,
            .rtf,
            .image,
            .jpeg,
            .png,
            UTType(filenameExtension: "doc") ?? .data,
            UTType(filenameExtension: "docx") ?? .data
        ])
        
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        picker.shouldShowFileExtensions = true
        
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {
        // No updates needed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: FilePickerView
        
        init(_ parent: FilePickerView) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else {
                parent.dismiss()
                return
            }
            
            // Start accessing the security-scoped resource
            guard url.startAccessingSecurityScopedResource() else {
                print("Failed to access security-scoped resource")
                parent.dismiss()
                return
            }
            
            defer {
                url.stopAccessingSecurityScopedResource()
            }
            
            do {
                let data = try Data(contentsOf: url)
                let filename = url.lastPathComponent
                parent.onFileSelected(data, filename)
            } catch {
                print("Failed to read file: \(error.localizedDescription)")
            }
            
            parent.dismiss()
        }
        
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            parent.dismiss()
        }
    }
}

// MARK: - Preview
#Preview {
    FilePickerView { data, filename in
        print("Selected file: \(filename) with \(data.count) bytes")
    }
} 