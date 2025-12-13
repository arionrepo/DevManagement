# DevManagement - Final Design Summary

**File:** /Users/liborballaty/LocalProjects/GitHubProjectsDocuments/DevManagement/DESIGN-SUMMARY.md
**Description:** Summary of approved design approach with key decisions
**Author:** Libor Ballaty <libor@arionetworks.com>
**Created:** 2025-12-13

## Approved Design: Compact Menu Bar → Tabbed Dashboard

### Design Strategy

Start with a minimal, focused menu bar experience that grows into a powerful detailed view system.

**Two-Part UI:**
1. **Menu Bar (MVP)** - Compact dropdown with quick status and actions
2. **Detailed Window (Full-Featured)** - Opens in separate window with comprehensive tabs

---

## MVP: Compact Menu Bar

### What It Shows
```
┌─────────────────────────────────┐
│ ⚙️ Development Services    [↻]  │
├─────────────────────────────────┤
│ 🟢 Colima              [⟳][ℹ️] │
│ 🟢 Supabase            [⟳][ℹ️] │
│ 🟢 Python Backend      [⟳][ℹ️] │
│ 🟢 Admin UI            [⟳][ℹ️] │
│ 🟠 Customer UI         [⟳][ℹ️] │
├─────────────────────────────────┤
│ [Start All] [Stop All]          │
├─────────────────────────────────┤
│ Last: 12:34 PM   [Details]      │
└─────────────────────────────────┘
```

### Key Features
- **Status indicators** - Green (running), Orange (starting/stopping), Red (failed)
- **Quick controls** - Restart button and info button for each service
- **Bulk actions** - Start All / Stop All buttons
- **Refresh** - Auto-refreshes every 3 seconds
- **Details access** - Info button (ℹ️) opens detailed window for that service

### Services Included (MVP)
1. Colima (Docker runtime)
2. Supabase (database, API, Edge Functions)
3. Python Backend (FastAPI on port 8001)
4. Admin UI (internal admin interface)
5. Customer UI (compliance UI on port 8080)

---

## Full-Featured: Detailed View Window

Opens when user clicks info button or "Details" link. Separate window with tabbed interface.

### Tab 1: Overview
- Service selector dropdown
- Status grid (6 boxes showing key metrics)
- Quick summary with health check URL
- Dependencies listed

### Tab 2: Details
- Service information (name, type, port)
- Performance metrics (latency, uptime, requests/min, error rate)
- Health check configuration (URL, interval, timeout, expected codes)

### Tab 3: Files & Scripts (CRITICAL FEATURE)
User can find and open all related files:
- **Startup Scripts**
  - main-startsupabase.sh
  - main-start.sh (for UIs)
  - Custom startup scripts
- **Configuration Files**
  - services.json
  - docker-compose.yml
  - Environment files
- **Related Files**
  - Stop scripts
  - Log files
  - Database migration files
  - README files

**Each file has:**
- Icon showing file type
- One-click "Open" button (opens in user's default editor)
- Copy path button (copies full path to clipboard)
- Full file path displayed

### Tab 4: Logs
- Real-time service logs
- Color-coded by level (green=INFO, orange=WARN, red=ERROR)
- Monospace font for readability
- Auto-scroll to latest
- Clear logs button
- Log level filter

### Tab 5: Architecture
- Service dependency tree
  ```
  Colima (Docker Runtime)
  └─→ Supabase
      ├─→ PostgreSQL Database
      ├─→ Kong API Gateway
      ├─→ PostgREST
      ├─→ Realtime
      ├─→ Storage
      └─→ Edge Functions
  ```
- Related containers and services
- **Future Services Roadmap** (expandable)
  - VectorDB (Supabase pgvector) - Add monitoring
  - ChromaDB - Vector storage alternative
  - Logging Database - Observability storage
  - App Container - Main application
  - Backup Container - Automated backups
  - Observability Stack - Monitoring & tracing

### Tab 6: Settings
- Service-specific preferences
  - Auto-start when Colima starts
  - Auto-recover on wake from sleep
  - Notify on failures
- Health monitoring settings
  - Check interval (2-10 seconds)
  - Timeout duration
- Logging preferences
  - Log retention period
  - Storage location

---

## Key Implementation Details

### Service Configuration (services.json)

Each service includes:
```json
{
  "name": "supabase",
  "display_name": "Supabase",
  "type": "http",
  "description": "Database + API + Edge Functions",
  "commands": {
    "start": "bash /path/to/main-startsupabase.sh",
    "stop": "bash /path/to/main-stopsupabase.sh",
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
  "startup_delay_seconds": 5,
  "files": {
    "startup_scripts": [
      {
        "name": "main-startsupabase.sh",
        "path": "/Users/liborballaty/LocalProjects/GitHubProjectsDocuments/xLLMArionComply/arioncomply-v1/supabase/main-startsupabase.sh"
      }
    ],
    "config_files": [
      {
        "name": "services.json",
        "path": "/Users/liborballaty/LocalProjects/GitHubProjectsDocuments/DevManagement/config/services.json"
      },
      {
        "name": "docker-compose.yml",
        "path": "/Users/liborballaty/LocalProjects/GitHubProjectsDocuments/xLLMArionComply/arioncomply-v1/docker-compose.yml"
      }
    ],
    "related_files": [
      {
        "name": "main-stopsupabase.sh",
        "path": "/Users/liborballaty/LocalProjects/GitHubProjectsDocuments/xLLMArionComply/arioncomply-v1/supabase/main-stopsupabase.sh"
      }
    ]
  }
}
```

### Wake Recovery

When Mac wakes from sleep:
1. System notification triggers PowerEventMonitor
2. Immediate status refresh (< 1 second)
3. Wait 3 seconds for services to respond
4. Identify unhealthy services
5. Show notification to user
6. Optionally auto-restart (if preference enabled)

---

## Future Expansion Path (v1.1+)

### New Services to Add

**VectorDB Integration**
- Monitor Supabase pgvector health
- Track embedding storage usage
- Monitor query performance

**ChromaDB Integration**
- Alternative vector store support
- Health monitoring
- Collection management

**Logging Database**
- Observability storage monitoring
- Query performance
- Data retention tracking

**Individual Containers**
- app-container
- backup-container
- observability-stack
- Each with separate start/stop/restart and file explorer

### New Features

1. **Dashboard** - Historical graphs of uptime/latency
2. **Metrics** - Real-time performance metrics per service
3. **Advanced Logging** - Persistent storage with search/filtering
4. **Notifications** - Desktop alerts for failures/recovery
5. **Remote Management** - SSH support for managing remote machines
6. **Service Templates** - Pre-configured for common stacks
7. **Export/Import** - Share configs between developers

---

## Implementation Phases

### Phase 1: Project Infrastructure (1-2 hours)
- Directory structure
- Swift package manifest
- Config files with service definitions + file mappings
- Git setup

### Phase 2: Service Management CLI (2-3 hours)
- dev-services.sh script
- Status, start, stop, restart, health-check commands
- JSON output for GUI
- Return file paths

### Phase 3: Swift GUI (3-4 hours)
- MenuBarExtra app
- Compact dropdown view
- Status indicators
- Quick action buttons

### Phase 3B: Detailed Window (2-3 hours)
- Separate window with tabs
- Overview, Details, Files & Scripts, Logs, Architecture, Settings
- File opening and clipboard copy
- Service selector

### Phase 4: Wake Recovery (1 hour)
- PowerEventMonitor for wake detection
- Auto-recovery logic
- Preferences UI

### Phase 5: Build Scripts (1 hour)
- rebuild-gui.sh for development
- build_app.sh for production releases

### Phase 6: Testing (6-8 hours)
- Unit tests
- Integration tests
- System tests
- User acceptance testing

**Total Time: 17-23 hours of development**

---

## Critical Questions Before We Start

Before implementation, we need to confirm:

1. **Service Commands** - Exact commands for start/stop/restart?
   - Colima: `colima start` / `colima stop`?
   - Supabase: Use main-startsupabase.sh?
   - UIs: Use their main-start.sh scripts?

2. **File Paths** - Are these paths correct for the startup scripts?
   - Verify all paths in the proposed services.json

3. **Health Check URLs** - Are these endpoints correct and reachable?
   - Supabase: `http://127.0.0.1:54321/rest/v1/`?
   - Python Backend: `http://127.0.0.1:8001/health`?
   - UIs: What endpoints should be checked?

4. **Additional Services** - Should we add any other services for MVP?
   - PostgreSQL management?
   - Container monitoring?
   - Any other critical dev services?

5. **Preferences** - Which settings matter most?
   - Auto-recover on wake (yes/no)?
   - Auto-start on app launch (yes/no)?
   - Notification preferences (yes/no)?
   - Custom refresh intervals (yes/no)?

6. **Future Features** - Anything critical we shouldn't wait for v1.1?
   - Persistent logs?
   - Historical metrics?
   - Notifications?

---

## Next Step: Phase 1 Implementation

Once you confirm the above, we proceed with Phase 1:
1. Create directory structure
2. Write Package.swift
3. Create comprehensive services.json with all file mappings
4. Create initial test to validate service discovery
5. First commit: "Phase 1 complete"

Then move sequentially through Phases 2-6.

---

## Questions?

All mockups, plans, and documentation are in:
- Interactive mockups: `mockups-enhanced.html` (open in browser)
- Text mockups: `UI-MOCKUPS.md`
- Implementation plan: `PLAN.md`
- Design summary: This file (DESIGN-SUMMARY.md)

Ready to proceed when you confirm the questions above!
