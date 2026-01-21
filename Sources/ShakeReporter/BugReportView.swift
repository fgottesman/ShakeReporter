import SwiftUI

/// SwiftUI view for submitting bug reports
public struct BugReportView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var description: String = ""
    @State private var priority: BugReportPriority = .medium
    @State private var isSubmitting = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showSuccess = false

    private let appId: String
    private let service: BugReportService
    private let screenshot: UIImage?
    private let screenName: String?

    public init(
        appId: String,
        service: BugReportService,
        screenshot: UIImage? = nil,
        screenName: String? = nil
    ) {
        self.appId = appId
        self.service = service
        self.screenshot = screenshot
        self.screenName = screenName
    }

    public var body: some View {
        NavigationStack {
            Form {
                // Screenshot preview (if available)
                if let screenshot = screenshot {
                    Section {
                        Image(uiImage: screenshot)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: 200)
                            .cornerRadius(8)
                    } header: {
                        Text("Screenshot")
                    }
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
            .toolbar {
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
            }
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
        }
    }

    private func priorityColor(_ priority: BugReportPriority) -> Color {
        switch priority {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        }
    }

    private func submitReport() async {
        isSubmitting = true

        // Prepare screenshot
        let screenshotBase64: String?
        if let screenshot = screenshot {
            screenshotBase64 = ScreenshotCapture.imageToBase64(screenshot)
        } else {
            screenshotBase64 = nil
        }

        let request = BugReportRequest(
            appId: appId,
            description: description.trimmingCharacters(in: .whitespacesAndNewlines),
            priority: priority,
            screenshotBase64: screenshotBase64,
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
