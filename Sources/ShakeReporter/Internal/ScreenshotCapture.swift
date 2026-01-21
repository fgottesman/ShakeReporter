import UIKit

/// Utility for capturing screenshots
enum ScreenshotCapture {
    /// Capture a screenshot of the current screen
    @MainActor
    static func captureScreen() -> UIImage? {
        guard let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }),
              let window = windowScene.windows.first(where: { $0.isKeyWindow })
        else {
            return nil
        }

        // Use drawHierarchy which properly captures SwiftUI content
        let renderer = UIGraphicsImageRenderer(bounds: window.bounds)
        return renderer.image { _ in
            // afterScreenUpdates: true ensures all pending UI updates are rendered
            window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
        }
    }

    /// Convert UIImage to base64 string (PNG format)
    static func imageToBase64(_ image: UIImage, compressionQuality: CGFloat = 0.7) -> String? {
        // Use JPEG for smaller size
        guard let data = image.jpegData(compressionQuality: compressionQuality) else {
            return nil
        }
        return data.base64EncodedString()
    }
}
