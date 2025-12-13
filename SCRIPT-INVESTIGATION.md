# DevManagement - Script Investigation Report

**File:** /Users/liborballaty/LocalProjects/GitHubProjectsDocuments/DevManagement/SCRIPT-INVESTIGATION.md
**Description:** Detailed investigation of ArionComply startup scripts and service requirements
**Author:** Libor Ballaty <libor@arionetworks.com>
**Created:** 2025-12-13
**Investigation Date:** 2025-12-13

## Executive Summary

This document details the critical findings from investigating the ArionComply startup scripts, particularly `main-startsupabase.sh` and related infrastructure requirements. These findings significantly impact how DevManagement must monitor and manage these services.

---

## Critical Finding: Never Use Raw `supabase start`

### Key Requirement
**ALWAYS use `main-startsupabase.sh` script - NEVER use raw `supabase start`**

From supabase/README.md (line 261):
```
ALWAYS use `startsupabase.sh` script - NEVER use raw `supabase start`
```

### Why?
The main-startsupabase.sh script:
1. **Manages Python Backend** - supabase start doesn't start Python backend
2. **Manages Edge Functions** - Starts edge functions runner (npx supabase functions serve)
3. **Orchestrates Colima** - Ensures Docker/Colima is running with proper socket configuration
4. **Manages Service Dependencies** - Ensures services start in correct order
5. **Provides Health Checks** - Verifies each service is truly healthy
6. **Logs Management** - Centralizes logs for debugging

### Implication for DevManagement
- **We CANNOT just call `supabase start`** in dev-services.sh
- **We must wrap the full `main-startsupabase.sh` script**
- **We should parse its logs and status output**
- **We need to understand its start sequence**

---

## Detailed Service Startup Analysis

### 1. Colima (Docker Runtime) - CRITICAL FOUNDATION

**Status:** Required for all containerized services (Supabase, Edge Functions)

**Start Command:**
```bash
colima start
```

**Colima-Specific Requirements (macOS):**

From main-startsupabase.sh (lines 167-206):

1. **Check if Colima daemon is running:**
   ```bash
   pgrep -q -f "colima daemon"
   ```
   - NOT just `colima status` (can hang on some systems)
   - Uses process check which is fast and reliable

2. **Start Colima if needed:**
   ```bash
   colima start
   # Takes 30-60 seconds
   ```

3. **Verify Docker socket is accessible (CRITICAL for wake recovery):**
   ```bash
   docker ps >/dev/null 2>&1  # Test with timeout
   ```
   - Uses 5-second timeout to avoid hanging
   - Retry up to 30 times (60 seconds total)
   - **Socket might not be available immediately after Colima starts**
   - **Must verify Docker accessibility, not just Colima daemon**

4. **Wait for Supabase containers to be healthy:**
   - Checks for: `supabase_kong`, `supabase_db`, `supabase_auth`
   - Waits up to 60 seconds for ALL containers to show "healthy" status
   - Uses: `docker ps --filter "name=${container}" --format "{{.Status}}" | grep -i "healthy"`

**Health Check:**
```bash
docker ps  # Simple but requires socket to be ready
```

**Stop Command:**
```bash
colima stop
```

**Issues to Watch For:**
- Docker socket not immediately available after Colima starts
- Socket may be at different paths on different machines
- `colima restart` may be needed if socket gets stuck
- Container health status can take time to update

---

### 2. Supabase (Database + API + Edge Functions)

**Status:** Started via `main-startsupabase.sh` (NOT raw `supabase start`)

**What Gets Started:**
- PostgreSQL database (Docker container)
- Kong API Gateway (Docker container)
- PostgREST (Docker container)
- Realtime (Docker container)
- Storage (Docker container)
- Edge Runtime container (for functions)

**Database Backup/Recovery Strategy (IMPORTANT):**

From supabase/README.md and deployment docs:

1. **Development Database:**
   - Uses local Supabase instance (not connected to cloud)
   - Database state persists in `.supabase/` directory
   - Automatic backups in `/backups/` directory

2. **Backup Location:**
   ```
   /Users/liborballaty/LocalProjects/GitHubProjectsDocuments/xLLMArionComply/backups/
   ```
   - Latest: `/backups/original-scripts-20251118-125112/`

3. **Recovery Process (if database corrupted):**
   ```bash
   # Don't use `supabase db reset` (DESTRUCTIVE - wipes everything)
   # Instead, restore from backup:
   supabase db push --linked --file <backup-file>.sql
   ```

4. **Migration System:**
   - Base schema: `supabase/db/migrations/` (0001-0017 sequential)
   - Applied once during initial setup
   - Incremental changes: `supabase/migrations/` (timestamp-based: 20251003_, 20251004_, etc.)
   - Applied after base schema
   - **Do NOT use `supabase db reset`** - use backup restore instead

**Supabase Health Check Endpoints:**

From main-startsupabase.sh (lines 294-322):

1. **Edge Functions Health Check:**
   ```bash
   curl -s -f "http://localhost:54321/functions/v1/edge-function-health" 2>&1
   # Returns JSON with {"healthy": true} for healthy status
   # Expected: HTTP 200 or 404 (404 means edge-function-health endpoint doesn't exist yet)
   ```

2. **API Health Check:**
   - Uses REST API on port 54321
   - Endpoint: `http://127.0.0.1:54321/rest/v1/` (or `http://localhost:54321/rest/v1/`)
   - Expected: HTTP 200 or 401 (401 = authentication required, but API is running)

3. **Note on localhost vs 127.0.0.1:**
   - **Edge Functions use `localhost`:** `http://localhost:54321/functions/v1/`
   - **API uses `127.0.0.1`:** `http://127.0.0.1:54321/rest/v1/`
   - Both resolve to same address but convention in scripts differs
   - **DevManagement should try both for robustness**

4. **Container Health Status:**
   ```bash
   docker ps --filter "name=supabase_kong" --format "{{.Status}}"
   # Returns: "Up 5 minutes (healthy)" when healthy
   ```

**Stop Command:**
```bash
# Use main-startsupabase.sh --stop
# This stops both Edge Functions AND Python Backend properly
```

**Startup Sequence:**
1. Colima must be running first
2. Supabase containers start via `supabase start` (internal to main-startsupabase.sh)
3. Wait for containers to be healthy (60 seconds max)
4. Then start Edge Functions
5. Then start Python Backend

**Critical Note:**
The script does NOT explicitly run `supabase start` - it relies on Colima/Docker being ready, then the Edge Runtime container comes up automatically with the other Supabase containers.

---

### 3. Python Backend (FastAPI on port 8001)

**Status:** Started separately from Supabase, depends on Supabase being healthy

**Location:**
```
/Users/liborballaty/LocalProjects/GitHubProjectsDocuments/xLLMArionComply/arioncomply-v1/ai-backend/python-backend
```

**Start Command (from main-startsupabase.sh lines 393-443):**
```bash
cd /Users/liborballaty/LocalProjects/GitHubProjectsDocuments/xLLMArionComply/arioncomply-v1/ai-backend/python-backend

# Ensure venv exists
if [ ! -d "venv" ]; then
    python3 -m venv venv
fi

# Activate and start uvicorn
source venv/bin/activate
nohup python -m uvicorn app.main:app --host 127.0.0.1 --port 8001 --log-level info \
    > /Users/liborballaty/LocalProjects/GitHubProjectsDocuments/xLLMArionComply/arioncomply-v1/logs/python-backend.log 2>&1 &

# Save PID
echo $! > /Users/liborballaty/LocalProjects/GitHubProjectsDocuments/xLLMArionComply/arioncomply-v1/.pids/python-backend.pid
```

**Health Check:**
```bash
curl -s -f "http://127.0.0.1:8001/health" >/dev/null 2>&1
# Expected: HTTP 200
```

**Logs Location:**
```
/Users/liborballaty/LocalProjects/GitHubProjectsDocuments/xLLMArionComply/arioncomply-v1/logs/python-backend.log
```

**PID File Location:**
```
/Users/liborballaty/LocalProjects/GitHubProjectsDocuments/xLLMArionComply/arioncomply-v1/.pids/python-backend.pid
```

**Stop Command:**
```bash
# Via PID file if available
kill $(cat .pids/python-backend.pid)

# Or via port
lsof -i :8001 -sTCP:LISTEN -t | xargs kill -9
```

**Startup Delay:**
- Waits up to 10 seconds for backend to respond to health check
- Displays status every second with dots

---

### 4. Edge Functions (Supabase Deno Runtime)

**Status:** Started after Supabase containers are healthy

**Start Command (from main-startsupabase.sh lines 446-497):**
```bash
cd /Users/liborballaty/LocalProjects/GitHubProjectsDocuments/xLLMArionComply/arioncomply-v1

# Check if Edge Runtime container already running
docker ps --filter "name=supabase_edge_runtime" --format "{{.Names}}" | grep -q "supabase_edge_runtime"

# If not, start edge functions
nohup npx supabase functions serve --no-verify-jwt \
    > /Users/liborballaty/LocalProjects/GitHubProjectsDocuments/xLLMArionComply/arioncomply-v1/logs/edge-functions.log 2>&1 &

# Save PID
echo $! > /Users/liborballaty/LocalProjects/GitHubProjectsDocuments/xLLMArionComply/arioncomply-v1/.pids/edge-functions.pid
```

**Health Check:**
```bash
curl -s -f "http://localhost:54321/functions/v1/edge-function-health" 2>&1
# Returns JSON: {"healthy": true}
# Expected: HTTP 200 (or 404 if endpoint doesn't exist)
```

**Note:** Uses `localhost` NOT `127.0.0.1`

**Logs Location:**
```
/Users/liborballaty/LocalProjects/GitHubProjectsDocuments/xLLMArionComply/arioncomply-v1/logs/edge-functions.log
```

**PID File Location:**
```
/Users/liborballaty/LocalProjects/GitHubProjectsDocuments/xLLMArionComply/arioncomply-v1/.pids/edge-functions.pid
```

**Stop Command:**
```bash
# Via PID file
kill $(cat .pids/edge-functions.pid)

# Or via process name
pkill -f "supabase functions serve"

# Or via port
lsof -i :54321 -sTCP:LISTEN -t | xargs kill -9
```

---

## Critical Socket & Networking Details

### Colima Socket Configuration (macOS-Specific)

From investigation of main-startsupabase.sh:

**The Problem:**
- After Colima starts, Docker socket may not be immediately available
- Running `docker ps` right after `colima start` can hang indefinitely
- Socket initialization can take several seconds

**The Solution (Implemented in main-startsupabase.sh):**
1. Use timeout wrapper on all docker commands (5-second timeout)
2. Retry up to 30 times (60 seconds total wait)
3. Check process with `pgrep -q -f "colima daemon"` first (fast, non-blocking)
4. Then verify Docker socket accessibility

**Code Pattern:**
```bash
# macOS-specific timeout function (lines 78-102)
run_with_timeout() {
    local timeout_seconds=$1
    shift
    local command="$@"

    if [ "$OS_TYPE" = "Linux" ] && command -v timeout &>/dev/null; then
        # GNU timeout
        timeout "${timeout_seconds}s" $command
    else
        # macOS without GNU timeout - use background process
        $command &
        local cmd_pid=$!
        ( sleep $timeout_seconds; kill -9 $cmd_pid 2>/dev/null ) &
        local timeout_pid=$!

        if wait $cmd_pid 2>/dev/null; then
            kill $timeout_pid 2>/dev/null
            return 0
        else
            kill $timeout_pid 2>/dev/null
            return 124  # Same as GNU timeout
        fi
    fi
}
```

**For DevManagement Implementation:**
- **Must use timeout wrapper for ALL docker commands**
- **Cannot just run bare `docker ps` - it will hang**
- **Should retry with delays between attempts**
- **After wake from sleep, may need 30-60 seconds for Docker to be ready**

---

## Service Dependency & Startup Order

### Correct Startup Sequence

From main-startsupabase.sh (lines 583-628):

1. **Colima** (Docker runtime)
   - Start and verify Docker socket is accessible
   - Wait for Docker daemon to be fully ready
   - Wait for Supabase containers to become healthy

2. **Supabase Containers** (PostgreSQL, Kong, PostgREST, Realtime, Storage)
   - Automatically starts when Docker is accessible
   - Wait up to 60 seconds for containers to be healthy
   - Check for: `supabase_kong`, `supabase_db`, `supabase_auth`

3. **Edge Functions** (Deno runtime)
   - Depends on Supabase containers being healthy
   - Start: `npx supabase functions serve --no-verify-jwt`
   - Wait up to 10 seconds for health check to pass
   - Health check: `http://localhost:54321/functions/v1/edge-function-health`

4. **Python Backend** (FastAPI)
   - Depends on Supabase being fully healthy (needs database connection)
   - Verify venv exists, create if needed
   - Activate venv and start uvicorn
   - Wait up to 10 seconds for health check to pass
   - Health check: `http://127.0.0.1:8001/health`

**Total Startup Time:**
- Colima: 30-60 seconds (first start) or 5-10 seconds (if already running)
- Supabase: 10-60 seconds to become healthy
- Edge Functions: 5-10 seconds
- Python Backend: 5-10 seconds
- **Total: 45-140 seconds** (depends on whether Colima is already running)

### Important: After Wake From Sleep

After macOS wake:
- Colima daemon likely still running BUT Docker socket may not be ready
- Need to verify socket accessibility (not just Colima daemon)
- May need up to 30 seconds for Docker socket to respond
- Supabase containers may need health re-check
- **This is critical for wake recovery feature**

---

## Logs & Debugging

### Log File Locations

```
/Users/liborballaty/LocalProjects/GitHubProjectsDocuments/xLLMArionComply/arioncomply-v1/logs/

├── python-backend.log       # FastAPI uvicorn logs
├── edge-functions.log       # Supabase functions serve logs
├── supabase.log             # (May exist)
└── ...
```

### How to Monitor Real-Time

From main-startsupabase.sh (lines 618-620):
```bash
# Backend logs
tail -f /Users/liborballaty/LocalProjects/GitHubProjectsDocuments/xLLMArionComply/arioncomply-v1/logs/python-backend.log

# Edge Functions logs
tail -f /Users/liborballaty/LocalProjects/GitHubProjectsDocuments/xLLMArionComply/arioncomply-v1/logs/edge-functions.log
```

### Important Log Indicators

**Python Backend Starting:**
```
INFO:     Uvicorn running on http://127.0.0.1:8001 (Press CTRL+C to quit)
```

**Edge Functions Available:**
```
✓ Function "edge-function-health" loaded
✓ Function "ai-conversation-send" loaded
...
```

**Supabase Container Health Check:**
```
docker ps --filter "name=supabase_kong" --format "{{.Status}}"
# Should show: "Up X minutes (healthy)"
```

---

## Port Assignments

| Service | Port | Type | Health Check |
|---------|------|------|--------------|
| Python Backend | 8001 | HTTP | `/health` → 200 |
| Supabase API | 54321 | HTTP | `/rest/v1/` → 200/401 |
| Edge Functions | 54321 | HTTP | `/functions/v1/edge-function-health` → 200/JSON |
| Supabase Studio | 54323 | HTTP | Web UI |
| Chat Interface | 5500 | HTTP | Web UI |

---

## Key Implementation Guidelines for DevManagement

### For Health Checks:
1. **Always use timeout wrapper** on docker/curl commands
2. **Try both localhost and 127.0.0.1** for Supabase endpoints
3. **Check container health status** via docker ps, not just port availability
4. **Edge Functions health check returns JSON** - parse it, don't just check HTTP code
5. **Python backend simple curl** - just needs 200 response

### For Wake Recovery:
1. **After wake, Colima daemon may be running but socket not ready**
2. **Retry docker commands with delays** (up to 60 seconds)
3. **Check all dependencies** - Colima → Supabase → Edge Functions → Python Backend
4. **Don't assume containers stayed healthy** - re-check them all
5. **Logs are critical** - must capture and display startup issues

### For Logging:
1. **Capture startup script output** for debugging
2. **Monitor log files** for errors (python-backend.log, edge-functions.log)
3. **Use structured logging** - timestamps, levels (INFO, WARN, ERROR)
4. **Keep logs accessible** to user in detailed view

### For Service Start/Stop:
1. **Must use main-startsupabase.sh** - never raw `supabase start`
2. **Use provided functions** - stop_all() function or PID files
3. **Port-based cleanup** - if PID files missing, kill by port
4. **Colima separately** - can start/stop independently

---

## Summary: What DevManagement Must Do

### Configuration (services.json):
```json
{
  "name": "colima",
  "commands": {
    "start": "colima start",
    "stop": "colima stop",
    "status": "pgrep -q -f 'colima daemon'"
  },
  "health_check": {
    "type": "command",
    "command": "docker ps --filter 'name=supabase' --format '{{.Names}}' | wc -l"
  }
}
```

### Health Checking:
- Use timeout wrapper for all docker commands
- Retry on timeout
- Check container status, not just port
- Validate socket accessibility

### Wake Recovery:
- Colima daemon likely still running
- Docker socket needs verification
- All services need re-health-check
- May take up to 60 seconds

### Logging:
- Capture main-startsupabase.sh output
- Monitor log files for errors
- Display in Logs tab
- Make accessible via Files & Scripts tab

---

## References

**Source Scripts:**
- `/Users/liborballaty/LocalProjects/GitHubProjectsDocuments/xLLMArionComply/arioncomply-v1/supabase/main-startsupabase.sh`

**Documentation:**
- `/Users/liborballaty/LocalProjects/GitHubProjectsDocuments/xLLMArionComply/arioncomply-v1/supabase/README.md`
- `/Users/liborballaty/LocalProjects/GitHubProjectsDocuments/xLLMArionComply/arioncomply-v1/supabase/DEPLOYMENT-STATUS.md`
- `/Users/liborballaty/LocalProjects/GitHubProjectsDocuments/xLLMArionComply/arioncomply-v1/supabase/DEPLOYMENT-PLAN-PROD.md`
