import SwiftUI

/// Configuration for ShakeReporter
public struct ShakeReporterConfiguration {
    public let appId: String
    public let apiEndpoint: String
    public let authTokenProvider: (() async -> String?)?

    /// Create a ShakeReporter configuration
    /// - Parameters:
    ///   - appId: Unique identifier for your app (e.g., "clipcook", "myapp")
    ///   - apiEndpoint: Base URL for the bug report API (e.g., "https://api.example.com/api/v1")
    ///   - authToken: Optional async closure that returns the current auth token
    public init(
        appId: String,
        apiEndpoint: String,
        authToken: (() async -> String?)? = nil
    ) {
        self.appId = appId
        self.apiEndpoint = apiEndpoint
        self.authTokenProvider = authToken
    }
}

/// View modifier that enables shake-to-report functionality
public struct ShakeReporterModifier: ViewModifier {
    @StateObject private var shakeDetector = ShakeDetector()
    @State private var showBugReport = false

    private let configuration: ShakeReporterConfiguration
    private let screenNameProvider: (() -> String?)?

    init(
        configuration: ShakeReporterConfiguration,
        screenName: (() -> String?)? = nil
    ) {
        self.configuration = configuration
        self.screenNameProvider = screenName
    }

    public func body(content: Content) -> some View {
        content
            .onReceive(shakeDetector.$didShake) { shook in
                if shook {
                    showBugReport = true
                }
            }
            .sheet(isPresented: $showBugReport, onDismiss: {
                shakeDetector.reset()
            }) {
                BugReportView(
                    appId: configuration.appId,
                    service: BugReportService(
                        apiEndpoint: configuration.apiEndpoint,
                        authTokenProvider: configuration.authTokenProvider
                    ),
                    screenshot: shakeDetector.capturedScreenshot,
                    screenName: screenNameProvider?()
                )
            }
            .background(
                ShakeDetectingViewRepresentable(shakeDetector: shakeDetector)
                    .frame(width: 0, height: 0)
            )
    }
}

/// UIViewRepresentable for shake detection
struct ShakeDetectingViewRepresentable: UIViewRepresentable {
    let shakeDetector: ShakeDetector

    func makeUIView(context: Context) -> ShakeDetectingUIView {
        let view = ShakeDetectingUIView()
        view.shakeDetector = shakeDetector
        return view
    }

    func updateUIView(_ uiView: ShakeDetectingUIView, context: Context) {}
}

/// UIView that can become first responder to detect shakes
class ShakeDetectingUIView: UIView {
    weak var shakeDetector: ShakeDetector?

    override var canBecomeFirstResponder: Bool { true }

    override func didMoveToWindow() {
        super.didMoveToWindow()
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

// MARK: - View Extension

public extension View {
    /// Enable shake-to-report bug reporting
    /// - Parameters:
    ///   - appId: Unique identifier for your app
    ///   - apiEndpoint: Base URL for the bug report API
    ///   - authToken: Optional async closure that returns the current auth token
    ///   - screenName: Optional closure that returns the current screen name
    /// - Returns: A view with shake-to-report enabled
    func shakeReporter(
        appId: String,
        apiEndpoint: String,
        authToken: (() async -> String?)? = nil,
        screenName: (() -> String?)? = nil
    ) -> some View {
        let config = ShakeReporterConfiguration(
            appId: appId,
            apiEndpoint: apiEndpoint,
            authToken: authToken
        )
        return modifier(ShakeReporterModifier(configuration: config, screenName: screenName))
    }

    /// Enable shake-to-report bug reporting with configuration
    /// - Parameters:
    ///   - configuration: ShakeReporter configuration
    ///   - screenName: Optional closure that returns the current screen name
    /// - Returns: A view with shake-to-report enabled
    func shakeReporter(
        configuration: ShakeReporterConfiguration,
        screenName: (() -> String?)? = nil
    ) -> some View {
        modifier(ShakeReporterModifier(configuration: configuration, screenName: screenName))
    }
}
