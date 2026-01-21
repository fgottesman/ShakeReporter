import Foundation
import UIKit

/// Priority levels for bug reports
public enum BugReportPriority: String, Codable, CaseIterable {
    case low
    case medium
    case high

    public var displayName: String {
        rawValue.capitalized
    }

    public var color: String {
        switch self {
        case .low: return "green"
        case .medium: return "orange"
        case .high: return "red"
        }
    }
}

/// Bug report model sent to the API
public struct BugReportRequest: Codable {
    public let appId: String
    public let description: String
    public let priority: BugReportPriority
    public let screenshotBase64: String?
    public let appVersion: String?
    public let buildNumber: String?
    public let iosVersion: String?
    public let deviceModel: String?
    public let screenName: String?

    public init(
        appId: String,
        description: String,
        priority: BugReportPriority,
        screenshotBase64: String? = nil,
        appVersion: String? = nil,
        buildNumber: String? = nil,
        iosVersion: String? = nil,
        deviceModel: String? = nil,
        screenName: String? = nil
    ) {
        self.appId = appId
        self.description = description
        self.priority = priority
        self.screenshotBase64 = screenshotBase64
        self.appVersion = appVersion
        self.buildNumber = buildNumber
        self.iosVersion = iosVersion
        self.deviceModel = deviceModel
        self.screenName = screenName
    }
}

/// Response from the bug report API
public struct BugReportResponse: Codable {
    public let success: Bool
    public let bugReport: BugReportInfo?
    public let error: String?

    public struct BugReportInfo: Codable {
        public let id: String
        public let status: String
        public let isDuplicate: Bool?
        public let canonicalId: String?
    }
}

/// Device information helper
public struct DeviceInfo {
    public static var iosVersion: String {
        UIDevice.current.systemVersion
    }

    public static var deviceModel: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return identifier
    }

    public static var appVersion: String? {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
    }

    public static var buildNumber: String? {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String
    }
}
