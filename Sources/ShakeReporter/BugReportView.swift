import SwiftUI

/// SwiftUI view for submitting bug reports with multiple screenshot support
public struct BugReportView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var description: String = ""
    @State private var priority: BugReportPriority = .medium
    @State private var isSubmitting = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showSuccess = false
    
    // Multiple screenshots support
    @State private var screenshots: [UIImage]
    @State private var selectedScreenshotIndex: Int? = nil
    @State private var showAnnotationView = false

    private let appId: String
    private let service: BugReportService
    private let screenName: String?

    public init(
        appId: String,
        service: BugReportService,
        screenshot: UIImage? = nil,
        screenName: String? = nil
    ) {
        self.appId = appId
        self.service = service
        self.screenName = screenName
        // Initialize with the captured screenshot if provided
        _screenshots = State(initialValue: screenshot.map { [$0] } ?? [])
    }

    public var body: some View {
        NavigationStack {
            Form {
                // Screenshots section
                Section {
                    if screenshots.isEmpty {
                        // Empty state with add button
                        Button {
                            captureNewScreenshot()
                        } label: {
                            HStack {
                                Image(systemName: "camera.fill")
                                Text("Capture Screenshot")
                            }
                            .foregroundColor(.accentColor)
                        }
                    } else {
                        // Screenshot grid/list
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(Array(screenshots.enumerated()), id: \.offset) { index, image in
                                    ScreenshotThumbnail(
                                        image: image,
                                        onTap: {
                                            selectedScreenshotIndex = index
                                            showAnnotationView = true
                                        },
                                        onDelete: {
                                            withAnimation {
                                                screenshots.remove(at: index)
                                            }
                                        }
                                    )
                                }
                                
                                // Add more button
                                Button {
                                    captureNewScreenshot()
                                } label: {
                                    VStack {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.system(size: 30))
                                        Text("Add")
                                            .font(.caption)
                                    }
                                    .foregroundColor(.accentColor)
                                    .frame(width: 80, height: 100)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(8)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                } header: {
                    Text("Screenshots")
                } footer: {
                    Text("Tap a screenshot to annotate it")
                }

                // Description
                Section {
                    TextEditor(text: $description)
                        .frame(minHeight: 100)
                } header: {
                    Text("What went wrong?")
                } footer: {
                    Text("Please describe the issue in detail")
                }

                // Priority
                Section {
                    Picker("Priority", selection: $priority) {
                        ForEach(BugReportPriority.allCases, id: \.self) { p in
                            HStack {
                                Circle()
                                    .fill(priorityColor(p))
                                    .frame(width: 8, height: 8)
                                Text(p.displayName)
                            }
                            .tag(p)
                        }
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("Priority")
                }

                // Device info (read-only)
                Section {
                    LabeledContent("App Version", value: DeviceInfo.appVersion ?? "Unknown")
                    LabeledContent("Build", value: DeviceInfo.buildNumber ?? "Unknown")
                    LabeledContent("iOS Version", value: DeviceInfo.iosVersion)
                    LabeledContent("Device", value: DeviceInfo.deviceModel)
                    if let screenName = screenName {
                        LabeledContent("Screen", value: screenName)
                    }
                } header: {
                    Text("Device Info")
                }
            }
            .navigationTitle("Report a Bug")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(content: {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isSubmitting)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Submit") {
                        Task { await submitReport() }
                    }
                    .disabled(description.trimmingCharacters(in: .whitespacesAndNewlines).count < 5 || isSubmitting)
                }
            })
            .overlay {
                if isSubmitting {
                    ProgressView("Submitting...")
                        .padding()
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") {}
            } message: {
                Text(errorMessage)
            }
            .alert("Thank You!", isPresented: $showSuccess) {
                Button("Done") {
                    dismiss()
                }
            } message: {
                Text("Your bug report has been submitted. We'll look into it!")
            }
            .sheet(isPresented: $showAnnotationView) {
                if let index = selectedScreenshotIndex, index < screenshots.count {
                    if #available(iOS 16.0, *) {
                        ScreenshotAnnotationView(image: screenshots[index]) { annotatedImage in
                            screenshots[index] = annotatedImage
                        }
                    }
                }
            }
        }
    }

    private func priorityColor(_ priority: BugReportPriority) -> Color {
        switch priority {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        }
    }
    
    private func captureNewScreenshot() {
        // Capture current screen
        if let newScreenshot = ScreenshotCapture.captureScreen() {
            withAnimation {
                screenshots.append(newScreenshot)
            }
        }
    }

    private func submitReport() async {
        isSubmitting = true

        // Convert all screenshots to base64
        let screenshotBase64s: [String]? = screenshots.isEmpty ? nil :
            screenshots.compactMap { ScreenshotCapture.imageToBase64($0) }

        let request = BugReportRequest(
            appId: appId,
            description: description.trimmingCharacters(in: .whitespacesAndNewlines),
            priority: priority,
            screenshotBase64s: screenshotBase64s,
            appVersion: DeviceInfo.appVersion,
            buildNumber: DeviceInfo.buildNumber,
            iosVersion: DeviceInfo.iosVersion,
            deviceModel: DeviceInfo.deviceModel,
            screenName: screenName
        )

        do {
            let response = try await service.submitReport(request)
            if response.success {
                showSuccess = true
            } else {
                errorMessage = response.error ?? "Unknown error"
                showError = true
            }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }

        isSubmitting = false
    }
}

// MARK: - Screenshot Thumbnail Component

private struct ScreenshotThumbnail: View {
    let image: UIImage
    let onTap: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 80, height: 100)
                .clipped()
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(.systemGray4), lineWidth: 1)
                )
                .onTapGesture {
                    onTap()
                }
            
            // Delete button
            Button {
                onDelete()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(.white, .red)
            }
            .offset(x: 6, y: -6)
        }
    }
}
