# DevManagement macOS Menu Bar Application - User Manual

**File:** /Users/liborballaty/LocalProjects/GitHubProjectsDocuments/DevManagement/MANUAL.md
**Description:** Complete user guide and feature documentation for DevManagement service lifecycle management tool
**Author:** Libor Ballaty <libor@arionetworks.com>
**Created:** 2025-12-15

## Table of Contents

1. [Overview](#overview)
2. [Installation & Setup](#installation--setup)
3. [User Interface](#user-interface)
4. [Features](#features)
5. [Service Management](#service-management)
6. [Advanced Features](#advanced-features)
7. [Troubleshooting](#troubleshooting)

---

## Overview

DevManagement is a lightweight macOS menu bar application that provides centralized control over development services and Docker runtime profiles. It monitors service health, displays resource usage, and allows quick start/stop/restart operations from the menu bar.

**Key Capabilities:**
- Real-time service monitoring (3-second refresh interval)
- Per-colima profile Docker runtime management
- Resource usage display (CPU, memory, network latency)
- Script visibility and execution tracking
- One-click service control (Start, Stop, Restart)
- Overall health status monitoring
- Log file access

---

## Installation & Setup

### Building from Source

```bash
cd /Users/liborballaty/LocalProjects/GitHubProjectsDocuments/DevManagement
swift build -c debug
open ./.build/arm64-apple-macosx/debug/dev-manager
```

### Configuration

Services are configured in `config/services.json`. Each service entry includes:

```json
{
  "id": "service-name",
  "name": "service-name",
  "display_name": "Service Display Name",
  "type": "http" or "process",
  "icon": "emoji-icon",
  "description": "Service description",
  "startup_order": 1,
  "critical": true,
  "startup_delay_seconds": 0,
  "commands": {
    "start": "bash /path/to/start.sh",
    "stop": "bash /path/to/stop.sh",
    "restart": "bash /path/to/restart.sh",
    "status": "optional-status-command"
  },
  "health_check": {
    "type": "http" or "command",
    "endpoints": [{"url": "http://localhost:8000", "expected_status_codes": [200]}],
    "command": "optional-command",
    "timeout_seconds": 5,
    "interval_seconds": 3
  }
}
```

---

## User Interface

### Menu Bar Icon

The menu bar displays a gear icon labeled **"Dev"** that changes color based on overall system health:

- 🟢 **Green** - All critical services healthy
- 🟠 **Orange** - Some critical services degraded
- 🔴 **Red** - Critical services failed
- ⚪ **Gray** - Unknown status

Click the icon to open the service management popover.

### Popover Layout

```
┌─────────────────────────────────────┐
│ ⚙️ Dev Services         🔄 Refresh  │
├─────────────────────────────────────┤
│                                     │
│  Service Row 1 (Colima Profile)    │
│  [Start] [Stop] [Restart] [Logs] [Scripts] │
│                                     │
│  Service Row 2 (HTTP Service)      │
│  [Start] [Stop] [Restart] [Logs] [Scripts] │
│                                     │
│  ... (more services) ...            │
│                                     │
├─────────────────────────────────────┤
│ [Start All]  [Stop All]             │
├─────────────────────────────────────┤
│ Overall Status:  🟢 Healthy         │
│ Updated:         Last: 12:34 PM     │
│                         [Quit]      │
└─────────────────────────────────────┘
```

---

## Features

### 1. Service Monitoring

Each service row displays:

**Status Indicator** (colored circle)
- 🟢 Green - Service running and healthy
- 🟠 Orange - Service degraded or partial health
- 🔴 Red - Service stopped or unhealthy
- ❓ Gray - Status unknown or check failed

**Service Name & Status Description**
- Left side: Service display name
- Below: Current status ("Running", "Stopped", "Health check timeout", etc.)

**Resource Display** (right side)
- **For Colima Profiles:**
  - CPU count (e.g., "4 CPU")
  - Memory allocation (e.g., "8 GB")

- **For HTTP Services:**
  - Endpoint URL (if health check configured)
  - Latency in milliseconds (e.g., "45 ms")

### 2. Service Control Buttons

Each service row has four action buttons:

| Button | Color | Function | Enabled When |
|--------|-------|----------|--------------|
| **Start** | Green | Start the service | Service is stopped |
| **Stop** | Red | Stop the service | Service is running |
| **Restart** | Blue | Restart the service | Always enabled |
| **Logs** | Gray | Open log directory | Always enabled |

### 3. Scripts Menu

The purple **"Scripts"** button reveals the exact commands being executed:

**Features:**
- View actual command text in monospaced font
- **Copy** button - Copies command to clipboard for manual execution
- **Open** button - Opens script files in your default editor (for .sh files only)

**Example Menu Structure:**
```
Start Command
  "colima start app"
  [Copy]

Stop Command
  "colima stop app"
  [Copy]

Restart Command
  "colima stop app && colima start app"
  [Copy]

Status Command
  "colima status app"
  [Copy]
```

### 4. Colima Profile Monitoring

DevManagement automatically detects Docker runtime profiles in `~/.colima/` and creates monitored services for each:

**Profile Detection:**
- Scans `~/.colima/` directory
- Filters out system files (starting with `.` or `_`, and `ssh_config`)
- Sorts alphabetically
- Creates synthetic services with proper commands

**Profile Services Display Order:**
- All detected colima profiles appear at the top
- Listed alphabetically
- Each shows CPU count and memory allocation
- Commands: `colima start/stop/restart/status [profile-name]`

**Example Profiles:**
- Colima: app
- Colima: backup
- Colima: default
- Colima: observability

### 5. Overall System Status

Footer section displays:

**Overall Status**
- Summary health indicator for all critical services
- 🟢 Healthy: All critical services running
- 🟠 Degraded: Some critical services down
- 🔴 Failed: All critical services down

**Last Update Time**
- Displays last refresh time (e.g., "Last: 12:34 PM")
- Automatic refresh every 3 seconds

---

## Service Management

### Starting Services

1. Click the **"Dev"** icon in menu bar
2. Find the service you want to start
3. Click the green **"Start"** button
4. Monitor the status indicator for confirmation

The Start button is disabled when the service is already running.

### Stopping Services

1. Click the **"Dev"** icon in menu bar
2. Find the service you want to stop
3. Click the red **"Stop"** button
4. Status will change to 🔴 when stopped

The Stop button is disabled when the service is already stopped.

### Restarting Services

1. Click the **"Dev"** icon in menu bar
2. Click the blue **"Restart"** button
3. Service will briefly show as stopped, then restart

The Restart button is always enabled.

### Bulk Operations

**Start All Services**
- Click **[Start All]** button at bottom
- Starts all services in order (respects startup order from config)
- Useful for bringing entire development environment online

**Stop All Services**
- Click **[Stop All]** button at bottom
- Stops all running services
- Useful for clean shutdown

---

## Advanced Features

### Script Inspection

The Scripts menu lets you see exactly what DevManagement runs:

**Copy Command to Clipboard:**
1. Click the purple **"Scripts"** button
2. Find the command section (Start, Stop, Restart, Status)
3. Click **"Copy"** to copy the command text
4. Paste in terminal to run manually

**Open Script Files:**
1. Click the purple **"Scripts"** button
2. If the command references a `.sh` file, an **"Open"** button appears
3. Click to open the script in your default editor
4. View, edit, or audit the exact commands being executed

**Example:**
```
Start Command
"bash /Users/liborballaty/scripts/start-supabase.sh"

[Copy]  [Open script: start-supabase.sh]
```

### Resource Monitoring

**Colima Profiles:**
- CPU count shows allocated CPU cores
- Memory displays allocated RAM in GB
- Updated every 3 seconds
- Parsed from `colima list --json` output

**HTTP Services:**
- Shows health check endpoint URL
- Displays response latency in milliseconds
- Useful for identifying slow services
- Timeout after 5 seconds if unresponsive

### Health Checking

**Process Type Services:**
- Status determined by exit code of status command
- Exit code 0 = running (🟢)
- Non-zero exit code = stopped (🔴)
- Command: `colima status [profile]`

**HTTP Type Services:**
- Makes actual HTTP request to health check endpoint
- Checks for expected status codes (default: 200)
- Measures response time (latency)
- 5-second timeout
- Docker container verification for multi-container services

### Log Access

The gray **"Logs"** button opens service log directories:

**Configured Locations:**
- Colima: `~/.colima/` directory
- Supabase: `/Users/liborballaty/LocalProjects/GitHubProjectsDocuments/xLLMArionComply/arioncomply-v1/logs`
- Backend services: Configured per service in code
- Default: Project logs directory

Opens in Finder for easy file browsing and log inspection.

---

## Technical Architecture

### Data Flow

```
ServiceMonitor (observes changes)
    ↓
    ├── detectColimaProfiles() → List of profile directories
    ├── createColimaProfileService() → Synthetic Service objects
    └── updateStatus() → Periodic status checks
        ↓
        ServiceManager (executes commands)
            ├── checkProcessStatus() → Run status commands
            ├── checkColimaProfileStatus() → Parse JSON resources
            └── checkHttpStatus() → HTTP health checks
        ↓
        ServiceStatus (status + resources)
            ├── icon (🟢/🟠/🔴)
            ├── description (Running/Stopped/etc)
            ├── cpus, memory_gb (colima only)
            └── latency_ms (HTTP services)
    ↓
ServiceRowView (displays UI)
    ├── Status indicator
    ├── Service info & status
    ├── Resource display
    ├── Control buttons
    └── Scripts menu

```

### Key Files

| File | Purpose |
|------|---------|
| `Sources/GUI/App.swift` | Main menu bar UI and app container |
| `Sources/GUI/ServiceMonitor.swift` | Service discovery and monitoring orchestration |
| `Sources/GUI/ServiceRowView.swift` | Individual service display component |
| `Sources/Core/ServiceManager.swift` | Command execution and status checking |
| `Sources/Core/Models.swift` | Data structures (Service, ServiceStatus, etc.) |
| `config/services.json` | Service configuration |

### Refresh Interval

- **Automatic monitoring:** Every 3 seconds
- **Manual refresh:** Click 🔄 button in header
- **On app focus:** Updates immediately on popover open

---

## Troubleshooting

### Service Shows Status as Unknown (❓)

**Causes:**
- Status check command not configured
- Command returned unexpected output
- Health check endpoint unreachable

**Solution:**
1. Click Scripts button to verify command is correct
2. Run command manually in terminal to test
3. Check health check configuration in `config/services.json`

### Service Won't Start

**Possible Issues:**
- Insufficient permissions
- Script file not found
- Port already in use
- Dependencies not met

**Debug Steps:**
1. Click Scripts → Copy the start command
2. Run manually in terminal: `bash /path/to/script.sh`
3. Check for error messages
4. Verify all dependencies are running first

### Colima Profile Not Appearing

**Causes:**
- Profile directory not in `~/.colima/`
- Directory name starts with `.` or `_`
- Directory is not actually a colima profile

**Solution:**
1. Verify profile exists: `ls ~/.colima/`
2. Check directory name doesn't start with `.` or `_`
3. Restart the app to re-scan

### High Memory Usage

**Normal Behavior:**
- Monitoring 3-5 services: ~15-25 MB
- Each HTTP health check uses ~1-2 MB temporarily

**If excessive:**
1. Check number of SSH agents: `ps aux | grep ssh-agent`
2. Click refresh button to force immediate update cycle
3. Quit and relaunch app

### Scripts Menu Buttons Not Working

**Possible Issues:**
- Script file path has spaces or special characters
- Editor not found for file type
- File permissions prevent opening

**Solution:**
- For Copy: Always works, test pasting in terminal
- For Open: Verify file path is valid with `ls -la [path]`

---

## Development Notes

### Adding New Services

1. Edit `config/services.json`
2. Add service entry with commands and health check
3. Rebuild: `swift build -c debug`
4. Restart the app

### Modifying Service Commands

Commands can contain:
- Simple commands: `service-name start`
- Bash scripts: `bash /path/to/script.sh`
- Compound commands: `cmd1 && cmd2 || cmd3`
- Environment variables: `$HOME`, `$PATH`, etc.

### Health Check Configuration

For HTTP services:
```json
"health_check": {
  "type": "http",
  "endpoints": [
    {
      "url": "http://localhost:8000/health",
      "expected_status_codes": [200, 204]
    }
  ],
  "timeout_seconds": 5
}
```

For process-type services:
```json
"health_check": {
  "type": "command",
  "command": "command-to-check-status",
  "expected_output_pattern": "running"
}
```

---

## Feature Checklist

### Phase 1: Core Functionality ✓
- [x] Menu bar UI with service list
- [x] Real-time status monitoring
- [x] Start/Stop/Restart controls
- [x] Overall health indicator
- [x] Automatic refresh (3-second interval)

### Phase 2: Resource Monitoring ✓
- [x] CPU display for colima profiles
- [x] Memory display for colima profiles
- [x] Latency display for HTTP services
- [x] Parse colima JSON output
- [x] Resource updates with status refresh

### Phase 3: Transparency & Control ✓
- [x] Scripts menu showing commands
- [x] Copy to clipboard functionality
- [x] Open script files in editor
- [x] Extract script paths from commands
- [x] Script file detection (.sh extension)

### Phase 4: Profile Management ✓
- [x] Auto-detect colima profiles
- [x] Create synthetic services for profiles
- [x] Profile-specific status checking
- [x] Proper command interpolation
- [x] Alphabetical sorting

### Phase 5: UI Refinement ✓
- [x] Remove emoji icons from status indicators
- [x] Solid background (no translucent material)
- [x] Filled buttons with opacity states
- [x] Improved visual hierarchy
- [x] Better spacing and padding
- [x] Shadow effects on indicators

---

## Version History

**v1.0.0** (2025-12-15)
- Initial release
- Core service management
- Colima profile monitoring
- Resource display
- Script visibility
- Complete UI refinement

---

## Support & Questions

For issues, feature requests, or questions:
- Email: libor@arionetworks.com
- GitHub: [DevManagement Repository](https://github.com/arionrepo/DevManagement)
