import SwiftUI
import UIKit

/// Environment key for shake detection
struct ShakeDetectorKey: EnvironmentKey {
    static let defaultValue: ShakeDetector? = nil
}

extension EnvironmentValues {
    var shakeDetector: ShakeDetector? {
        get { self[ShakeDetectorKey.self] }
        set { self[ShakeDetectorKey.self] = newValue }
    }
}

/// Coordinator for detecting device shakes
@MainActor
public class ShakeDetector: ObservableObject {
    @Published public var didShake = false
    @Published public var capturedScreenshot: UIImage?

    private var lastShakeTime: Date = .distantPast
    private let cooldownInterval: TimeInterval = 2.0

    public init() {}

    /// Called when a shake is detected
    func handleShake() {
        let now = Date()
        guard now.timeIntervalSince(lastShakeTime) > cooldownInterval else { return }
        lastShakeTime = now

        // Capture screenshot immediately
        capturedScreenshot = ScreenshotCapture.captureScreen()
        didShake = true
    }

    /// Reset shake state
    func reset() {
        didShake = false
        capturedScreenshot = nil
    }
}

/// UIWindow subclass that detects shake gestures
class ShakeDetectingWindow: UIWindow {
    weak var shakeDetector: ShakeDetector?

    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            Task { @MainActor in
                shakeDetector?.handleShake()
            }
        }
        super.motionEnded(motion, with: event)
    }
}

/// A view that wraps content and detects shake gestures
struct ShakeDetectingView<Content: View>: UIViewControllerRepresentable {
    let content: Content
    let shakeDetector: ShakeDetector

    func makeUIViewController(context: Context) -> ShakeHostingController<Content> {
        let controller = ShakeHostingController(rootView: content)
        controller.shakeDetector = shakeDetector
        return controller
    }

    func updateUIViewController(_ uiViewController: ShakeHostingController<Content>, context: Context) {
        uiViewController.rootView = content
    }
}

/// Hosting controller that can detect shake gestures
class ShakeHostingController<Content: View>: UIHostingController<Content> {
    weak var shakeDetector: ShakeDetector?

    override var canBecomeFirstResponder: Bool { true }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        becomeFirstResponder()
    }

    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            Task { @MainActor in
                shakeDetector?.handleShake()
            }
        }
        super.motionEnded(motion, with: event)
    }
}
