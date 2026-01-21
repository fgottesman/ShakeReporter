# ShakeReporter

A reusable Swift Package for shake-to-report bug reporting in iOS apps.

## Features

- Shake device to trigger bug report
- Automatic screenshot capture
- Device info collection (iOS version, device model, app version)
- Multi-tenant support (use across multiple apps)
- Optional authentication support
- Duplicate detection on backend
- Priority levels (low, medium, high)

## Installation

### Swift Package Manager

Add the following to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/freddygottesman/ShakeReporter.git", from: "1.0.0")
]
```

Or in Xcode:
1. File → Add Package Dependencies
2. Enter: `https://github.com/freddygottesman/ShakeReporter`
3. Add to your target

## Usage

### Basic Setup

Add the `.shakeReporter()` modifier to your root view:

```swift
import SwiftUI
import ShakeReporter

@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .shakeReporter(
                    appId: "myapp",
                    apiEndpoint: "https://api.example.com/api/v1"
                )
        }
    }
}
```

### With Authentication

If your app has user authentication, provide a token:

```swift
ContentView()
    .shakeReporter(
        appId: "myapp",
        apiEndpoint: "https://api.example.com/api/v1",
        authToken: {
            // Return your auth token
            try? await AuthManager.shared.getAccessToken()
        }
    )
```

### With Screen Name Tracking

Track which screen the user was on:

```swift
ContentView()
    .shakeReporter(
        appId: "myapp",
        apiEndpoint: "https://api.example.com/api/v1",
        screenName: {
            // Return current screen name
            NavigationManager.shared.currentScreenName
        }
    )
```

### Using Configuration Object

For more control, use the configuration object:

```swift
let config = ShakeReporterConfiguration(
    appId: "myapp",
    apiEndpoint: "https://api.example.com/api/v1",
    authToken: { await getToken() }
)

ContentView()
    .shakeReporter(configuration: config)
```

## Backend API

ShakeReporter expects a backend endpoint at `{apiEndpoint}/bug-reports` that accepts POST requests:

### Request Body

```json
{
    "appId": "myapp",
    "description": "Description of the bug",
    "priority": "low" | "medium" | "high",
    "screenshotBase64": "base64-encoded-image",
    "appVersion": "1.0.0",
    "buildNumber": "42",
    "iosVersion": "17.0",
    "deviceModel": "iPhone15,2",
    "screenName": "HomeScreen"
}
```

### Response

```json
{
    "success": true,
    "bugReport": {
        "id": "uuid",
        "status": "new",
        "isDuplicate": false
    }
}
```

## Requirements

- iOS 16.0+
- Swift 5.9+

## License

MIT License
