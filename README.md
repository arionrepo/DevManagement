# DevManagement

**File:** /Users/liborballaty/LocalProjects/GitHubProjectsDocuments/DevManagement/README.md
**Description:** Unified control and monitoring for development services with automatic wake recovery
**Author:** Libor Ballaty <libor@arionetworks.com>
**Created:** 2025-12-13

A macOS MenuBarExtra application for monitoring and managing development services with automatic wake recovery from system sleep.

## Features

- **Real-time Status Monitoring** - See the health of all dev services at a glance
- **One-Click Control** - Start, stop, or restart services from the menu bar
- **Automatic Wake Recovery** - Services automatically check and recover when Mac wakes from sleep
- **Dependency Management** - Services start in correct dependency order
- **Health Checks** - Automatic latency monitoring and health verification
- **Extensible Configuration** - Easily add new services via JSON config

## Quick Start

### Installation

1. Clone this repository:
```bash
git clone https://github.com/your-org/DevManagement.git
cd DevManagement
```

2. Build and run:
```bash
./gui-macos/rebuild-gui.sh
```

3. The app will launch in your menu bar

### First Use

1. Click the DevManagement icon in menu bar
2. Check service statuses
3. Click "Start All" to boot your dev environment
4. Services will start in dependency order with appropriate delays

### Configuration

Edit `config/services.json` to customize which services to monitor:

```json
{
  "services": [
    {
      "name": "my-service",
      "display_name": "My Service",
      "type": "http",
      "commands": {
        "start": "my-service-start-command",
        "stop": "my-service-stop-command"
      },
      "health_check": {
        "type": "http",
        "url": "http://localhost:8000/health",
        "timeout_seconds": 5
      }
    }
  ]
}
```

## Usage

### Menu Bar Commands

- **Refresh** - Update service statuses (also automatic every 3 seconds)
- **Start All** - Boot all services in dependency order
- **Stop All** - Shutdown all services in reverse order
- **Service Controls** - Individual start/stop/restart buttons for each service

### CLI Commands

```bash
# Show service status (human-readable)
./scripts/dev-services.sh status

# Show service status (JSON for GUI)
./scripts/dev-services.sh status --json

# Check health of specific service
./scripts/dev-services.sh health-check supabase

# Start/stop/restart individual services
./scripts/dev-services.sh start colima
./scripts/dev-services.sh stop colima
./scripts/dev-services.sh restart colima

# Start/stop all services
./scripts/dev-services.sh start-all
./scripts/dev-services.sh stop-all
```

## Architecture

### Components

1. **GUI (Swift MenuBarExtra)** - User interface for monitoring and control
   - Real-time status display
   - Service control buttons
   - Preference management
   - Wake event detection

2. **Service Manager CLI** - Backend service orchestration
   - Config-driven service management
   - Health check execution
   - Command execution with error handling
   - JSON status output for GUI

3. **Configuration** - JSON-based service definitions
   - Service metadata (name, description, type)
   - Startup commands and health checks
   - Dependency declarations
   - Startup order and delays

4. **Power Monitor** - macOS system integration
   - Detects wake from sleep events
   - Triggers recovery checks
   - Automatic service restart (optional)

### Service Types

- **HTTP** - Services with HTTP health check endpoints
- **Command** - Services managed via shell commands
- **Integrated** - Services that depend on other services

## Wake Recovery

When your Mac wakes from sleep:

1. **Immediate detection** - System notification triggers status refresh
2. **Health check** - Services are checked for health within 3 seconds
3. **Issue detection** - Unhealthy services are identified
4. **User notification** - Optional notification if services need recovery
5. **Auto-recovery** - Services automatically restart (if enabled in preferences)

Services restart in correct dependency order with appropriate delays between starts.

### Disable Auto-Recovery

If you prefer manual control:
1. Click DevManagement menu bar icon
2. Go to Settings
3. Toggle off "Auto-recover on wake"
4. Services will still be checked, but won't auto-restart

## Troubleshooting

### Services won't start
- Check that prerequisite services started first (e.g., Colima before Supabase)
- Check logs in `~/Documents/DevManagement.log`
- Verify service commands in `config/services.json` are correct

### GUI not showing updated status
- Click the refresh button
- Try closing and reopening the menu
- If persistent, restart the app: kill the process and relaunch

### Wake recovery not working
- Verify "Auto-recover on wake" is enabled in Settings
- Check `~/Documents/DevManagement.log` for wake event logs
- Ensure services.json has proper health_check configuration

### Service health shows timeout
- Check that service is actually running
- Verify health check URL is correct in config
- Check network connectivity
- Increase timeout_seconds in config if service is slow to respond

## Development

### Project Structure

```
DevManagement/
├── gui-macos/              # Swift MenuBarExtra app
│   ├── Sources/
│   ├── Tests/
│   ├── Package.swift
│   └── rebuild-gui.sh
├── scripts/
│   └── dev-services.sh     # Service manager CLI
├── config/
│   └── services.json       # Service definitions
├── README.md               # This file
└── PLAN.md                 # Implementation plan
```

### Building

**Development build:**
```bash
./gui-macos/rebuild-gui.sh
```

**Production build:**
```bash
./gui-macos/build_app.sh
# Creates: release/DevManagement.app
```

### Testing

**CLI tests:**
```bash
./scripts/test-services.sh
```

**Swift tests:**
```bash
cd gui-macos && swift test
```

## Platform Support

- macOS 12.0+
- Apple Silicon and Intel Macs
- Tested on macOS 14.x (Sonoma) and later

## Requirements

- Swift 5.8+
- Xcode 14.0+ (for building from source)
- Colima/Docker (if monitoring Docker services)
- Supabase CLI (if monitoring Supabase)

## License

MIT License - See LICENSE file for details

## Contributing

Contributions welcome! Please:
1. Create feature branch from main
2. Make your changes
3. Run tests: `./scripts/test-services.sh && cd gui-macos && swift test`
4. Submit pull request

## Questions?

Open an issue on GitHub or contact: libor@arionetworks.com

---

## Status

**Current Version:** 0.1.0 (In Development)

**Completed:**
- Project setup and planning

**In Progress:**
- Phase 1: Project infrastructure
- Phase 2: Service manager CLI
- Phase 3: Swift GUI framework
- Phase 4: Wake recovery logic
- Phase 5: Build scripts
- Phase 6: Testing

**Roadmap:**
- v1.0 - Initial release with ArionComply service support
- v1.1 - Service templates library
- v2.0 - Remote service management, dashboard, advanced monitoring
