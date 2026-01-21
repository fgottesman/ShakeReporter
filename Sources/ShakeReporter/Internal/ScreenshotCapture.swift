import UIKit

/// Utility for capturing screenshots
enum ScreenshotCapture {
    /// Capture a screenshot of the current screen (all windows composited)
    @MainActor
    static func captureScreen() -> UIImage? {
        guard let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive })
        else {
            return nil
        }

        // Get all visible windows sorted by window level (back to front)
        let windows = windowScene.windows
            .filter { !$0.isHidden && $0.alpha > 0 }
            .sorted { $0.windowLevel.rawValue < $1.windowLevel.rawValue }

        guard let firstWindow = windows.first else { return nil }

        // Use the screen bounds to capture everything
        let bounds = firstWindow.bounds

        let renderer = UIGraphicsImageRenderer(bounds: bounds)
        return renderer.image { _ in
            // Draw each window in order (back to front) to composite them
            for window in windows {
                window.drawHierarchy(in: window.frame, afterScreenUpdates: true)
            }
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
