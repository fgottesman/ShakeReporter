import Foundation

/// Service for submitting bug reports to the API
public actor BugReportService {
    private let apiEndpoint: String
    private let authTokenProvider: (() async -> String?)?

    public init(
        apiEndpoint: String,
        authTokenProvider: (() async -> String?)? = nil
    ) {
        self.apiEndpoint = apiEndpoint.hasSuffix("/") ? String(apiEndpoint.dropLast()) : apiEndpoint
        self.authTokenProvider = authTokenProvider
    }

    /// Submit a bug report to the API
    public func submitReport(_ report: BugReportRequest) async throws -> BugReportResponse {
        let url = URL(string: "\(apiEndpoint)/bug-reports")!

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Add auth token if available
        if let tokenProvider = authTokenProvider,
           let token = await tokenProvider() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        // Encode request body
        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(report)

        // Make request
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw BugReportError.invalidResponse
        }

        // Parse response
        let decoder = JSONDecoder()

        if httpResponse.statusCode == 201 || httpResponse.statusCode == 200 {
            return try decoder.decode(BugReportResponse.self, from: data)
        } else {
            // Try to parse error response
            if let errorResponse = try? decoder.decode(BugReportResponse.self, from: data),
               let errorMessage = errorResponse.error {
                throw BugReportError.serverError(errorMessage)
            }
            throw BugReportError.httpError(httpResponse.statusCode)
        }
    }
}

/// Errors that can occur during bug report submission
public enum BugReportError: LocalizedError {
    case invalidResponse
    case httpError(Int)
    case serverError(String)
    case encodingError

    public var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let code):
            return "Server returned error code \(code)"
        case .serverError(let message):
            return message
        case .encodingError:
            return "Failed to encode bug report"
        }
    }
}
