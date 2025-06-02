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