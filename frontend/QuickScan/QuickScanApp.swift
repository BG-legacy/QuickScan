import SwiftUI

@main
struct QuickScanApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(nil) // Supports both light and dark mode
        }
    }
}

// QuickScanApp is the main application entry point.
// It sets up the main window and loads ContentView as the root view. 