# DevManagement - Comprehensive Implementation Plan

**File:** /Users/liborballaty/LocalProjects/GitHubProjectsDocuments/DevManagement/PLAN.md
**Description:** Complete granular implementation plan with testing phases and validation steps
**Author:** Libor Ballaty <libor@arionetworks.com>
**Created:** 2025-12-13

## Project Overview

**DevManagement** is a macOS MenuBarExtra application for monitoring and managing development services with automatic wake recovery from sleep.

**Goal:** Unified control and visibility over all development infrastructure:
- Real-time status in menu bar (green/orange/red indicators)
- One-click start/stop/restart for each service
- Automatic wake detection and recovery
- Extensible design - easily add new services
- Configurable health checks and recovery behavior

**Scope for MVP:** Handle ArionComply development services
- Colima (Docker runtime)
- Supabase (database, API, Edge Functions)
- Python Backend (FastAPI)
- Customer UI
- Admin UI

## Repository Structure

```
DevManagement/
├── README.md                         # Project overview and quick start
├── PLAN.md                          # This file - implementation plan
├── ARCHITECTURE.md                  # Technical architecture and design decisions
├── gui-macos/                       # Swift MenuBarExtra app
│   ├── Sources/
│   │   ├── App.swift                # Main app + ViewModels (800 lines)
│   │   ├── PowerEventMonitor.swift  # macOS wake detection (60 lines)
│   │   ├── Logger.swift             # Structured logging (50 lines)
│   │   └── Preferences.swift        # User preferences (100 lines)
│   ├── Tests/
│   │   ├── StatusViewModelTests.swift
│   │   ├── PowerEventMonitorTests.swift
│   │   └── ServiceManagerTests.swift
│   ├── Package.swift                # Swift package manifest
│   ├── rebuild-gui.sh               # Development rebuild script
│   └── build_app.sh                 # Production app builder
├── scripts/
│   ├── dev-services.sh              # Service manager CLI (500 lines)
│   ├── health-check.sh              # Individual health checks
│   └── test-services.sh             # Testing harness
├── config/
│   └── services.json                # Service configuration
└── .gitignore
```

## Implementation Plan - Granular Breakdown

### Phase 1: Project Infrastructure (1-2 hours)

#### 1.1 Initialize Repository Structure
- [ ] Create directory structure as above
- [ ] Initialize git with main branch
- [ ] Create .gitignore (Swift, macOS, build artifacts)
- [ ] Create LICENSE file (MIT)
- [ ] Create initial README.md

**Validation:**
```bash
ls -la /Users/liborballaty/LocalProjects/GitHubProjectsDocuments/DevManagement/
# Should show: gui-macos/, scripts/, config/, .git/, PLAN.md, README.md
```

#### 1.2 Create Swift Package Manifest
**File:** `gui-macos/Package.swift`

Create minimal Swift package with dependencies:
- SwiftUI (standard library)
- Foundation (standard library)
- No external dependencies initially

**Validation:**
```bash
cd gui-macos && swift package describe
# Should show: DevManagement package with no external dependencies
```

#### 1.3 Create Configuration File
**File:** `config/services.json`

Define all services to monitor in JSON format:
```json
{
  "services": [
    {
      "name": "colima",
      "type": "command",
      "display_name": "Colima (Docker)",
      "description": "Docker runtime via Colima",
      "commands": {
        "status": "colima status",
        "start": "colima start",
        "stop": "colima stop",
        "restart": "colima stop && colima start"
      },
      "health_check": {
        "type": "command_output",
        "command": "colima status",
        "success_pattern": "colima is running"
      },
      "startup_order": 1,
      "critical": true
    },
    {
      "name": "supabase",
      "type": "http",
      "display_name": "Supabase",
      "description": "Database, API, and Edge Functions",
      "commands": {
        "status": "docker ps --filter 'name=supabase' --format '{{.Status}}'",
        "start": "bash /Users/liborballaty/LocalProjects/GitHubProjectsDocuments/xLLMArionComply/arioncomply-v1/main-startsupabase.sh",
        "stop": "bash /Users/liborballaty/LocalProjects/GitHubProjectsDocuments/xLLMArionComply/arioncomply-v1/main-stopsupabase.sh",
        "restart": "stop && start"
      },
      "health_check": {
        "type": "http",
        "url": "http://127.0.0.1:54321/rest/v1/",
        "timeout_seconds": 5,
        "expected_status_codes": [200, 401]
      },
      "startup_order": 2,
      "critical": true,
      "startup_delay_seconds": 5
    },
    {
      "name": "edge-functions",
      "type": "http",
      "display_name": "Edge Functions",
      "description": "Supabase Edge Functions",
      "health_check": {
        "type": "http",
        "url": "http://127.0.0.1:54321/functions/v1/",
        "timeout_seconds": 5,
        "expected_status_codes": [200, 404]
      },
      "startup_order": 3,
      "critical": false,
      "depends_on": ["supabase"]
    },
    {
      "name": "python-backend",
      "type": "http",
      "display_name": "Python Backend",
      "description": "FastAPI backend on port 8001",
      "health_check": {
        "type": "http",
        "url": "http://127.0.0.1:8001/health",
        "timeout_seconds": 5,
        "expected_status_codes": [200]
      },
      "startup_order": 3,
      "critical": true,
      "depends_on": ["supabase"]
    }
  ]
}
```

**Validation:**
```bash
jq . /Users/liborballaty/LocalProjects/GitHubProjectsDocuments/DevManagement/config/services.json
# Should parse without errors
```

---

### Phase 2: Service Management CLI (2-3 hours)

#### 2.1 Create dev-services.sh Script
**File:** `scripts/dev-services.sh`

Core script with these capabilities:
- `status [--json]` - Show service status (human or JSON)
- `start <service>` - Start a specific service
- `stop <service>` - Stop a specific service
- `restart <service>` - Restart a service
- `start-all` - Start all services in dependency order
- `stop-all` - Stop all services in reverse order
- `health-check <service>` - Check service health
- `logs <service>` - Show service logs

**Key logic:**
1. Load service definitions from `config/services.json`
2. Parse service configuration
3. Execute commands based on service type
4. Handle HTTP health checks with curl
5. Handle command-based health checks
6. Return JSON for GUI consumption

**Validation Checklist:**
```bash
# Test basic status
./scripts/dev-services.sh status

# Test JSON output
./scripts/dev-services.sh status --json | jq .

# Test individual service status
./scripts/dev-services.sh status colima
./scripts/dev-services.sh status supabase

# Test health check
./scripts/dev-services.sh health-check colima
./scripts/dev-services.sh health-check supabase
```

#### 2.2 Implement HTTP Health Check Logic
```bash
health_check_http() {
    local service_name=$1
    local url=$(jq -r ".services[] | select(.name == \"$service_name\") | .health_check.url" config/services.json)
    local timeout=$(jq -r ".services[] | select(.name == \"$service_name\") | .health_check.timeout_seconds" config/services.json)
    local expected_codes=$(jq -r ".services[] | select(.name == \"$service_name\") | .health_check.expected_status_codes[]" config/services.json | paste -sd "," -)

    start_time=$(date +%s%3N)
    http_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time "$timeout" "$url" 2>/dev/null || echo "000")
    end_time=$(date +%s%3N)
    latency=$((end_time - start_time))

    if echo "$expected_codes" | grep -q "$http_code"; then
        echo "{\"healthy\": true, \"status\": \"ok\", \"http_code\": \"$http_code\", \"latency_ms\": $latency}"
    else
        echo "{\"healthy\": false, \"status\": \"http_$http_code\", \"latency_ms\": $latency}"
    fi
}
```

#### 2.3 Implement Dependency Ordering
```bash
start_all() {
    local services=$(jq -r '.services | sort_by(.startup_order) | .[].name' config/services.json)

    for service in $services; do
        local startup_delay=$(jq -r ".services[] | select(.name == \"$service\") | .startup_delay_seconds // 0" config/services.json)

        echo "Starting $service..."
        start_service "$service"

        if [ "$startup_delay" -gt 0 ]; then
            echo "Waiting ${startup_delay}s for $service to stabilize..."
            sleep "$startup_delay"
        fi
    done
}
```

**Validation:**
```bash
# Test start all with logging
./scripts/dev-services.sh start-all 2>&1 | tee /tmp/start-all.log

# Verify order: colima should start first
grep "Starting" /tmp/start-all.log | head -1
# Should show: Starting colima...

# Test stop all (reverse order)
./scripts/dev-services.sh stop-all
```

---

### Phase 3: Swift GUI Framework (3-4 hours)

#### 3.1 Create Data Models
**File:** `gui-macos/Sources/Models.swift` (new)

```swift
struct Service: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    let displayName: String
    let description: String
    let type: String
    var status: ServiceStatus = .unknown
    var healthy: Bool = false
    var latencyMs: Int? = nil
    var lastChecked: Date? = nil
    var uptime: String? = nil
}

enum ServiceStatus: String, Codable {
    case unknown = "unknown"
    case running = "running"
    case stopped = "stopped"
    case unhealthy = "unhealthy"
    case starting = "starting"
    case stopping = "stopping"
}

struct StatusResponse: Codable {
    let timestamp: String
    let services: [Service]
}
```

**Validation:**
```bash
# Compile check
cd gui-macos && swift build 2>&1 | head -20
# Should show: Building for debugging...
```

#### 3.2 Create Logger Module
**File:** `gui-macos/Sources/Logger.swift`

Structured logging for debugging and user awareness:

```swift
enum LogLevel: String {
    case debug = "DEBUG"
    case info = "INFO"
    case warning = "WARNING"
    case error = "ERROR"
}

class AppLogger {
    static let shared = AppLogger()
    private let dateFormatter = ISO8601DateFormatter()

    func log(_ message: String, level: LogLevel = .info) {
        let timestamp = dateFormatter.string(from: Date())
        let logMessage = "[\(timestamp)] [\(level.rawValue)] \(message)"
        print(logMessage)

        // Also write to file for debugging
        if let logFile = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?
            .appendingPathComponent("DevManagement.log") {
            try? logMessage.appending("\n").append(toFile: logFile.path)
        }
    }
}
```

**Validation:**
```bash
# Check logger compiles
cd gui-macos && swift build
```

#### 3.3 Create PowerEventMonitor
**File:** `gui-macos/Sources/PowerEventMonitor.swift`

Detect macOS wake events:

```swift
import Foundation
import AppKit

class PowerEventMonitor: ObservableObject {
    @Published var lastWakeTime: Date?
    @Published var systemIsAwake = true

    private var wakeObserver: NSObjectProtocol?
    private var sleepObserver: NSObjectProtocol?

    init() {
        setupObservers()
    }

    private func setupObservers() {
        let workspace = NSWorkspace.shared

        // Listen for wake events
        wakeObserver = workspace.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            AppLogger.shared.log("System woke from sleep", level: .info)
            DispatchQueue.main.async {
                self?.lastWakeTime = Date()
                self?.systemIsAwake = true
                NotificationCenter.default.post(name: NSNotification.Name("SystemDidWake"), object: nil)
            }
        }

        // Listen for sleep events
        sleepObserver = workspace.notificationCenter.addObserver(
            forName: NSWorkspace.willSleepNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            AppLogger.shared.log("System going to sleep", level: .info)
            DispatchQueue.main.async {
                self?.systemIsAwake = false
            }
        }
    }

    deinit {
        if let observer = wakeObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
        }
        if let observer = sleepObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
        }
    }
}
```

**Validation:**
- Compile check
- Manual testing: Put Mac to sleep, wake it, check logs for notification

#### 3.4 Create Service Manager ViewModel
**File:** `gui-macos/Sources/ServiceManager.swift`

Orchestrates CLI script and service state:

```swift
class ServiceManager: ObservableObject {
    @Published var services: [Service] = []
    @Published var isLoading = false
    @Published var lastError: String? = nil

    private var statusTimer: Timer?
    private let cliPath: String
    private let refreshInterval: TimeInterval = 3.0 // seconds

    init(cliPath: String = "/Users/liborballaty/LocalProjects/GitHubProjectsDocuments/DevManagement/scripts/dev-services.sh") {
        self.cliPath = cliPath
        setupPeriodicRefresh()
    }

    func refreshStatus() {
        isLoading = true

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }

            do {
                let process = Process()
                process.executableURL = URL(fileURLWithPath: self.cliPath)
                process.arguments = ["status", "--json"]

                let pipe = Pipe()
                process.standardOutput = pipe
                process.standardError = Pipe()

                try process.run()
                process.waitUntilExit()

                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                let statusResponse = try JSONDecoder().decode(StatusResponse.self, from: data)

                DispatchQueue.main.async {
                    self.services = statusResponse.services
                    self.isLoading = false
                    self.lastError = nil
                }
            } catch {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.lastError = error.localizedDescription
                    AppLogger.shared.log("Failed to refresh status: \(error)", level: .error)
                }
            }
        }
    }

    func start(service: String) {
        executeCommand("start", service: service)
    }

    func stop(service: String) {
        executeCommand("stop", service: service)
    }

    func restart(service: String) {
        executeCommand("restart", service: service)
    }

    private func executeCommand(_ command: String, service: String) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }

            let process = Process()
            process.executableURL = URL(fileURLWithPath: self.cliPath)
            process.arguments = [command, service]

            do {
                try process.run()
                process.waitUntilExit()

                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    self.refreshStatus()
                }
            } catch {
                AppLogger.shared.log("Failed to execute \(command) on \(service): \(error)", level: .error)
            }
        }
    }

    private func setupPeriodicRefresh() {
        statusTimer = Timer.scheduledTimer(withTimeInterval: refreshInterval, repeats: true) { [weak self] _ in
            self?.refreshStatus()
        }
    }
}
```

**Validation:**
```bash
# Test CLI integration
./scripts/dev-services.sh status --json
# Should return valid JSON
```

#### 3.5 Create SwiftUI Views
**File:** `gui-macos/Sources/App.swift`

Main MenuBarExtra UI:

```swift
import SwiftUI
import AppKit

@main
struct DevManagementApp: App {
    @StateObject private var serviceManager = ServiceManager()
    @StateObject private var powerMonitor = PowerEventMonitor()
    @StateObject private var preferences = PreferencesManager()

    var body: some Scene {
        MenuBarExtra("DevManagement", systemImage: "hammer.fill") {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Development Services")
                        .font(.headline)
                    Spacer()
                    Button(action: { serviceManager.refreshStatus() }) {
                        Image(systemName: "arrow.clockwise")
                    }
                    .buttonStyle(.plain)
                }
                .padding()

                Divider()

                // Services List
                List(serviceManager.services) { service in
                    ServiceRowView(service: service, manager: serviceManager)
                }
                .listStyle(.plain)

                Divider()

                // Action Buttons
                HStack(spacing: 10) {
                    Button("Start All") {
                        serviceManager.startAll()
                    }
                    .buttonStyle(.bordered)

                    Button("Stop All") {
                        serviceManager.stopAll()
                    }
                    .buttonStyle(.bordered)
                }
                .padding()

                Divider()

                // Footer
                HStack {
                    Text("Last updated: \(formattedTime(serviceManager.lastUpdate))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Link("Settings", destination: URL(fileURLWithPath: "/Applications/System Preferences.app"))
                        .buttonStyle(.plain)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
            .frame(width: 400)
            .onAppear {
                serviceManager.refreshStatus()
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("SystemDidWake"))) { _ in
                handleWakeEvent()
            }
        }
    }

    private func handleWakeEvent() {
        AppLogger.shared.log("Handling wake event", level: .info)

        // Immediate refresh
        serviceManager.refreshStatus()

        // Check for unhealthy services after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            let unhealthyServices = serviceManager.services.filter { !$0.healthy && $0.name != "colima" }

            if !unhealthyServices.isEmpty && preferences.autoRecoverOnWake {
                AppLogger.shared.log("Auto-recovering \(unhealthyServices.count) services", level: .info)
                for service in unhealthyServices {
                    serviceManager.restart(service: service.name)
                    Thread.sleep(forTimeInterval: 2) // Space out restarts
                }
            }
        }
    }

    private func formattedTime(_ date: Date?) -> String {
        guard let date = date else { return "Never" }
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        return formatter.string(from: date)
    }
}

struct ServiceRowView: View {
    let service: Service
    let manager: ServiceManager

    var statusColor: Color {
        switch service.status {
        case .running where service.healthy:
            return .green
        case .running where !service.healthy:
            return .orange
        case .stopped:
            return .gray
        default:
            return .yellow
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            // Status indicator
            Circle()
                .fill(statusColor)
                .frame(width: 12, height: 12)

            // Service info
            VStack(alignment: .leading, spacing: 4) {
                Text(service.displayName)
                    .font(.headline)
                HStack(spacing: 8) {
                    Text(service.status.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    if let latency = service.latencyMs {
                        Text("(\(latency)ms)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()

            // Control buttons
            HStack(spacing: 6) {
                if service.status == .running {
                    Button(action: { manager.stop(service: service.name) }) {
                        Image(systemName: "stop.circle")
                    }
                    .buttonStyle(.plain)
                    .help("Stop \(service.displayName)")
                } else {
                    Button(action: { manager.start(service: service.name) }) {
                        Image(systemName: "play.circle")
                    }
                    .buttonStyle(.plain)
                    .help("Start \(service.displayName)")
                }

                Button(action: { manager.restart(service: service.name) }) {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.plain)
                .help("Restart \(service.displayName)")
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
    }
}
```

**Validation:**
```bash
# Build and run
cd gui-macos && swift build

# Check for compilation errors
# Expected: Building for debugging...
# Then: Build complete!
```

---

### Phase 4: Wake Recovery Logic (1 hour)

#### 4.1 Integrate PowerEventMonitor with StatusViewModel

Already included in App.swift `handleWakeEvent()` function:
- Detects wake notification
- Triggers immediate status refresh
- Waits 3 seconds for services to respond
- Identifies unhealthy services
- Optionally auto-restarts if preference enabled

**Validation:**
- [ ] Manual test: Start all services
- [ ] Put Mac to sleep (Cmd+Opt+Power)
- [ ] Manually kill a service while asleep
- [ ] Wake Mac
- [ ] Verify notification or log shows wake event detected
- [ ] Verify auto-restart attempted (if enabled)

#### 4.2 Add Preferences for Wake Recovery

**File:** `gui-macos/Sources/Preferences.swift`

```swift
class PreferencesManager: ObservableObject {
    @Published var autoRecoverOnWake = true
    @Published var refreshIntervalSeconds: Double = 3.0
    @Published var notifyOnWake = true
    @Published var autoStartOnLaunch = false

    init() {
        loadPreferences()
    }

    private func loadPreferences() {
        let defaults = UserDefaults.standard
        autoRecoverOnWake = defaults.bool(forKey: "autoRecoverOnWake")
        refreshIntervalSeconds = defaults.double(forKey: "refreshIntervalSeconds") > 0
            ? defaults.double(forKey: "refreshIntervalSeconds")
            : 3.0
        notifyOnWake = defaults.bool(forKey: "notifyOnWake")
        autoStartOnLaunch = defaults.bool(forKey: "autoStartOnLaunch")
    }

    func savePreferences() {
        let defaults = UserDefaults.standard
        defaults.set(autoRecoverOnWake, forKey: "autoRecoverOnWake")
        defaults.set(refreshIntervalSeconds, forKey: "refreshIntervalSeconds")
        defaults.set(notifyOnWake, forKey: "notifyOnWake")
        defaults.set(autoStartOnLaunch, forKey: "autoStartOnLaunch")
    }
}
```

---

### Phase 5: Build Script & Distribution (1 hour)

#### 5.1 Create Development Rebuild Script
**File:** `gui-macos/rebuild-gui.sh`

```bash
#!/bin/bash
set -e

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$PROJECT_ROOT/.build/x86_64-apple-macosx/debug"
APP_NAME="DevManagement"

echo "🔨 DevManagement GUI Rebuild"
echo "================================"

# Kill existing instances
echo "Killing existing instances..."
killall "$APP_NAME" 2>/dev/null || true
pkill -9 swift 2>/dev/null || true
sleep 1

# Clean build
echo "Building..."
cd "$PROJECT_ROOT/gui-macos"
swift build 2>&1

# Launch
echo "Launching..."
if [ -f "$BUILD_DIR/$APP_NAME" ]; then
    open "$BUILD_DIR/$APP_NAME"
    echo "✅ DevManagement launched"
else
    echo "❌ Build failed - executable not found at $BUILD_DIR/$APP_NAME"
    exit 1
fi
```

#### 5.2 Create Production App Builder
**File:** `gui-macos/build_app.sh`

Build standalone .app bundle for distribution:

```bash
#!/bin/bash
set -e

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="DevManagement"
BUILD_DIR="$PROJECT_ROOT/.build/x86_64-apple-macosx/release"

echo "🏗️ Building production app..."
cd "$PROJECT_ROOT/gui-macos"
swift build -c release

# Create .app bundle
APPS_DIR="$PROJECT_ROOT/release"
mkdir -p "$APPS_DIR"

# Copy executable to .app
APP_PATH="$APPS_DIR/$APP_NAME.app/Contents/MacOS"
mkdir -p "$APP_PATH"
cp "$BUILD_DIR/$APP_NAME" "$APP_PATH/$APP_NAME"

# Create Info.plist
PLIST_PATH="$APPS_DIR/$APP_NAME.app/Contents/Info.plist"
mkdir -p "$(dirname "$PLIST_PATH")"
cat > "$PLIST_PATH" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundleIdentifier</key>
    <string>com.arionnetworks.devmanagement</string>
    <key>CFBundleVersion</key>
    <string>1.0.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
</dict>
</plist>
EOF

echo "✅ Production app built: $APPS_DIR/$APP_NAME.app"
```

---

## Testing Strategy

### Phase 6A: Unit Testing (2 hours)

#### 6A.1 ServiceManager Tests
**File:** `gui-macos/Tests/ServiceManagerTests.swift`

```swift
import XCTest
@testable import DevManagement

class ServiceManagerTests: XCTestCase {
    var manager: ServiceManager!

    override func setUp() {
        super.setUp()
        manager = ServiceManager()
    }

    func testRefreshStatus() throws {
        let expectation = XCTestExpectation(description: "Status refreshed")

        manager.refreshStatus()

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            XCTAssertFalse(self.manager.isLoading)
            XCTAssertNotNil(self.manager.services)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 5)
    }

    func testStartService() throws {
        let expectation = XCTestExpectation(description: "Service started")

        manager.start(service: "colima")

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 5)
    }

    func testErrorHandling() throws {
        // Test with invalid CLI path
        let invalidManager = ServiceManager(cliPath: "/nonexistent/path")
        invalidManager.refreshStatus()

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            XCTAssertNotNil(invalidManager.lastError)
        }
    }
}
```

**Validation:**
```bash
cd gui-macos
swift test --filter ServiceManagerTests
# Expected: All tests pass
```

#### 6A.2 PowerEventMonitor Tests
**File:** `gui-macos/Tests/PowerEventMonitorTests.swift`

```swift
import XCTest
@testable import DevManagement

class PowerEventMonitorTests: XCTestCase {
    var monitor: PowerEventMonitor!

    override func setUp() {
        super.setUp()
        monitor = PowerEventMonitor()
    }

    func testWakeNotificationObserver() throws {
        let expectation = XCTestExpectation(description: "Wake event detected")

        // Simulate wake notification
        NotificationCenter.default.post(name: NSWorkspace.didWakeNotification)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            XCTAssertNotNil(self.monitor.lastWakeTime)
            XCTAssertTrue(self.monitor.systemIsAwake)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 5)
    }
}
```

**Validation:**
```bash
cd gui-macos
swift test --filter PowerEventMonitorTests
```

#### 6A.3 CLI Script Tests
**File:** `scripts/test-services.sh`

```bash
#!/bin/bash
set -e

PROJECT_ROOT="$(dirname "$0")/.."
SCRIPT="$PROJECT_ROOT/scripts/dev-services.sh"

echo "🧪 DevManagement CLI Tests"
echo "============================"

# Test 1: Status command
echo "Test 1: Status command..."
$SCRIPT status > /dev/null && echo "✅ Status command works" || echo "❌ Status command failed"

# Test 2: JSON status
echo "Test 2: JSON status..."
json=$($SCRIPT status --json)
echo "$json" | jq . > /dev/null && echo "✅ JSON output valid" || echo "❌ JSON parsing failed"

# Test 3: Individual service status
echo "Test 3: Individual service status..."
$SCRIPT status colima > /dev/null && echo "✅ Individual service status works" || echo "❌ Failed"

# Test 4: Health check format
echo "Test 4: Health check format..."
health=$($SCRIPT health-check colima)
echo "$health" | jq . > /dev/null && echo "✅ Health check JSON valid" || echo "❌ Health check JSON invalid"

echo ""
echo "✅ All CLI tests passed"
```

**Validation:**
```bash
chmod +x /Users/liborballaty/LocalProjects/GitHubProjectsDocuments/DevManagement/scripts/test-services.sh
./scripts/test-services.sh
```

---

### Phase 6B: Integration Testing (3 hours)

#### 6B.1 CLI + Config Integration
**Checklist:**
- [ ] Load services.json without errors
- [ ] All services in config have valid commands
- [ ] Health check endpoints are reachable (or report timeout correctly)
- [ ] Start/stop commands are formatted correctly
- [ ] JSON output schema matches App.swift expectations

**Test Script:**
```bash
# Validate config
jq . config/services.json > /dev/null

# Test each service individually
for service in $(jq -r '.services[].name' config/services.json); do
    echo "Testing $service..."
    ./scripts/dev-services.sh status $service
    ./scripts/dev-services.sh health-check $service
done
```

#### 6B.2 GUI + CLI Integration
**Checklist:**
- [ ] GUI loads without crashes
- [ ] ServiceManager reads CLI output correctly
- [ ] Service list populates from CLI
- [ ] Status indicators show correct colors
- [ ] Start/stop buttons execute CLI commands
- [ ] Refresh button updates all services

**Manual Test Steps:**
1. Launch app: `./gui-macos/rebuild-gui.sh`
2. Verify menu bar icon appears
3. Click menu bar icon to open
4. Verify service list shows
5. Click refresh button
6. Verify services update
7. Click start button on a stopped service
8. Watch status change in real-time

#### 6B.3 Wake Recovery Integration
**Checklist:**
- [ ] Wake notification triggers handler
- [ ] Handler calls refreshStatus()
- [ ] Unhealthy services identified after wake
- [ ] Notification sent to user (if enabled)
- [ ] Auto-recovery restarts failed services
- [ ] Restart happens in correct dependency order

**Manual Test Steps:**
1. Start all services: Click "Start All" button
2. Verify all show green (healthy)
3. Put Mac to sleep: Cmd+Opt+Power
4. Wait 30 seconds
5. Manually kill a service: `killall uvicorn` (for Python backend)
6. Wake Mac: Press any key or click trackpad
7. Watch menu bar - icon should refresh
8. Open menu - should show service as unhealthy
9. If auto-recovery enabled, should see restart attempt
10. Verify service recovers

---

### Phase 6C: System Testing (2 hours)

#### 6C.1 Service Startup Order Test
**Test Scenario:** Start all services and verify they start in correct order

**Expected Order:**
1. Colima (Docker runtime)
2. Supabase (depends on Colima)
3. Edge Functions (depends on Supabase)
4. Python Backend (depends on Supabase)
5. (Customer UI and Admin UI are optional)

**Test Steps:**
```bash
# Clear any running services
./scripts/dev-services.sh stop-all

# Wait for cleanup
sleep 10

# Start all and capture output
./scripts/dev-services.sh start-all 2>&1 | tee /tmp/startup.log

# Verify order in logs
grep "Starting" /tmp/startup.log
# Expected output:
# Starting colima...
# Starting supabase...
# Starting edge-functions...
# Starting python-backend...
```

**Validation Checklist:**
- [ ] Colima starts first
- [ ] Supabase waits 5 seconds before starting dependent services
- [ ] All services eventually reach healthy state
- [ ] No services fail to start
- [ ] No error messages in logs

#### 6C.2 Service Stop Order Test
**Test Scenario:** Stop all services in reverse dependency order

**Expected Reverse Order:**
1. Python Backend
2. Edge Functions
3. Supabase
4. Colima

**Test Steps:**
```bash
# Stop all
./scripts/dev-services.sh stop-all 2>&1 | tee /tmp/stopdown.log

# Verify reverse order
grep "Stopping" /tmp/stopdown.log
```

#### 6C.3 Sleep/Wake Stress Test
**Test Scenario:** Cycle sleep/wake 5 times, verify recovery each time

**Test Steps:**
```bash
# 1. Start all services
./scripts/dev-services.sh start-all
sleep 10

# 2. Verify all healthy
./scripts/dev-services.sh status --json | jq '.services | map(select(.healthy == false))'
# Should be empty

# 3. Sleep/wake cycle x5
for i in {1..5}; do
    echo "=== Sleep/Wake Cycle $i ==="

    # Sleep
    caffeinate -u -t 1 & # Use on another terminal or schedule
    sleep 2

    # (Manually wake the Mac)
    sleep 10

    # Check status
    ./scripts/dev-services.sh status --json | jq '.services | map({name, healthy})'

    sleep 5
done
```

**Validation:**
- [ ] All services recover after each wake cycle
- [ ] No manual intervention needed
- [ ] No crashes or hangs

#### 6C.4 Network Failure Handling
**Test Scenario:** Verify app handles network errors gracefully

**Test Steps:**
1. Disconnect from network (or throttle connection)
2. Click refresh in GUI
3. Observe timeout handling
4. Verify error message shown (not crash)
5. Reconnect to network
6. Click refresh again
7. Verify recovery

**Validation Checklist:**
- [ ] App doesn't crash on network timeout
- [ ] Error message displayed to user
- [ ] Retry button available
- [ ] App recovers when network restored

---

### Phase 6D: User Acceptance Testing (1.5 hours)

#### 6D.1 Real-World Scenario Testing

**Scenario 1: Morning Startup**
- [ ] Open laptop from sleep
- [ ] Launch DevManagement app
- [ ] All services show correct status
- [ ] Can click "Start All" to boot dev environment
- [ ] Takes ~30 seconds for full startup
- [ ] No manual intervention needed

**Scenario 2: Service Failure Recovery**
- [ ] Start all services
- [ ] Manually kill Python backend: `lsof -ti:8001 | xargs kill -9`
- [ ] GUI shows service as red/unhealthy within 3 seconds
- [ ] Click restart button
- [ ] Service automatically recovers
- [ ] Verify API is responsive again

**Scenario 3: Mac Sleep During Development**
- [ ] All services running
- [ ] Close laptop (triggers sleep)
- [ ] Manually kill Supabase container while asleep (simulating issue)
- [ ] Open laptop
- [ ] DevManagement detects Supabase unhealthy
- [ ] Auto-recovery restarts Supabase (if enabled)
- [ ] Developer can resume work without intervention

**Scenario 4: Multiple Service Failures**
- [ ] Start all services
- [ ] Manually kill Supabase and Python backend
- [ ] Trigger wake event or click refresh
- [ ] GUI shows both services red
- [ ] Click "Start All"
- [ ] Services restart in correct order
- [ ] Dependencies properly honored (Supabase starts before Python backend)

#### 6D.2 Preferences Testing

**Test Steps:**
1. Open DevManagement menu
2. Access settings/preferences
3. Toggle "Auto-recover on wake" OFF
4. Save preferences
5. Put Mac to sleep, wake it
6. Verify: No auto-recovery happens
7. Toggle setting back ON
8. Repeat - verify auto-recovery occurs
9. Change refresh interval
10. Verify: Status updates at new interval

**Validation:**
- [ ] All preferences save correctly
- [ ] Preferences persist across app restarts
- [ ] Settings take effect immediately
- [ ] No error messages

---

## Deliverables & Validation Criteria

### Code Quality Standards

#### Swift Code
- [ ] No compiler warnings
- [ ] Follows Swift naming conventions
- [ ] All functions documented with docstrings
- [ ] Error handling for all network operations
- [ ] No force unwraps (use optional binding)
- [ ] Proper memory management (no retain cycles)

#### Bash Script
- [ ] No shellcheck errors: `shellcheck scripts/dev-services.sh`
- [ ] Proper error handling (set -e)
- [ ] Input validation for service names
- [ ] Comments explaining complex logic

#### Configuration
- [ ] Valid JSON that parses without errors
- [ ] All required fields present for each service
- [ ] Commands are valid and tested
- [ ] Health check URLs are correct and reachable

### Documentation Requirements

Files to create/update:
- [ ] `README.md` - Quick start and usage guide
- [ ] `ARCHITECTURE.md` - Technical design decisions
- [ ] `INSTALL.md` - Installation instructions
- [ ] `TROUBLESHOOTING.md` - Common issues and solutions
- [ ] Inline code comments for complex logic

### Testing Completion Checklist

#### Phase 6A: Unit Tests
- [ ] All ServiceManager tests pass
- [ ] All PowerEventMonitor tests pass
- [ ] CLI tests pass with 100% success rate
- [ ] Test coverage > 80% for critical paths

#### Phase 6B: Integration Tests
- [ ] Config + CLI integration verified
- [ ] GUI + CLI integration verified
- [ ] Wake recovery integration tested
- [ ] All data flows work correctly

#### Phase 6C: System Tests
- [ ] Service startup order correct
- [ ] Service stop order correct
- [ ] Sleep/wake cycle tested 5+ times
- [ ] Network failure handling works
- [ ] No crashes or hangs observed

#### Phase 6D: UAT
- [ ] All 4 real-world scenarios completed successfully
- [ ] Preferences working correctly
- [ ] User can accomplish all tasks without issues
- [ ] Performance acceptable (no lag, instant feedback)

### Performance Benchmarks

| Metric | Target | Acceptance |
|--------|--------|-----------|
| App launch time | < 1 second | < 2 seconds |
| Menu open/close | < 100ms | < 500ms |
| Status refresh | < 2 seconds | < 5 seconds |
| CLI execution | < 1 second | < 3 seconds |
| Memory usage | < 30MB | < 50MB |
| CPU (idle) | < 0.1% | < 1% |
| Background polling | < 0.5% | < 2% |

---

## Known Limitations & Future Enhancements

### Current Limitations
1. **Single device only** - Not designed for multi-machine management
2. **Local scripts only** - Cannot manage services on remote machines
3. **Manual configuration** - Must manually update services.json for new services
4. **No logging history** - Logs only stored in app memory/Documents folder

### Future Enhancements (v2.0+)
1. **Service templates** - Pre-configured templates for common dev stacks
2. **Custom health checks** - Allow users to define custom health check scripts
3. **Notifications** - Desktop notifications for service failures/recoveries
4. **Dashboard view** - Historical graphs of service uptime/latency
5. **Log viewer** - Integrated log viewer for each service
6. **Remote management** - SSH support for managing remote machines
7. **Export/Import** - Share service configurations between developers

---

## Next Steps

Once you approve this plan:

1. **Phase 1 Start:** Create directory structure, Swift package manifest, config file
2. **Phase 2 Start:** Build dev-services.sh CLI script
3. **Phase 3 Start:** Build Swift GUI and integrate with CLI
4. **Phase 4 Start:** Add wake recovery logic
5. **Phase 5 Start:** Create build scripts
6. **Phase 6 Start:** Comprehensive testing

Each phase will be completed, tested, and committed before moving to the next.

---

## Questions for Clarification

Before we start, please confirm:

1. **Service Configuration:** Does the service list in services.json match your actual setup? Any services missing or incorrect paths?
2. **Health Check Endpoints:** Are the HTTP endpoints and timeouts correct?
3. **Preferences:** Do you want all the preferences listed (auto-recover, refresh interval, notifications, auto-start)?
4. **GitHub:** What's your GitHub org/username for the public repo?
5. **Team Usage:** Will other developers use this, or just you locally?

