# Phase 3 Implementation - Start Prompt for Claude Sonnet 4.5

**Date:** October 10, 2025  
**Task:** Begin Phase 3 - Analytics & ML Service Implementation  
**Context:** Phase 2 (Grafana + Visualization) completed successfully

---

## 🎯 Task Overview

Implement Phase 3 of the EnMS project following your detailed plan in `PHASE-03-ANALYTICS-ML-PLAN.md`.

The plan has been **reviewed and approved** by Claude 3.5 Sonnet with full codebase access. Your architecture is solid and 95% aligned with the current implementation.

---

## ✅ Current State Verified

**Database:**
- ✅ `energy_baselines` table exists (matches your plan 100%)
- ✅ `anomalies` table exists (matches your plan 100%)
- ✅ All 6 KPI functions exist: `calculate_sec()`, `calculate_peak_demand()`, `calculate_load_factor()`, `calculate_energy_cost()`, `calculate_carbon_intensity()`, `calculate_all_kpis()`
- ✅ TimescaleDB continuous aggregates: `energy_readings_1min`, `energy_readings_15min`, `energy_readings_1hour`, `production_data_1hour`, `environmental_data_1hour`

**Docker:**
- ✅ Analytics service defined in `docker-compose.yml` (port 8001)
- ✅ Environment variables configured correctly
- ✅ Health check configured
- ✅ **FIXED:** Model storage volume added (`./analytics/models/saved:/app/models/saved`)

**Nginx:**
- ✅ Analytics upstream defined (commented out, ready to uncomment)
- ✅ Analytics routes defined in `conf.d/default.conf` (commented out)
- ✅ URL rewrite configured: `/api/analytics/` → `/api/v1/`

**Directory:**
- ✅ `/analytics/` directory exists with all subdirectories (empty, ready for implementation)

**Services Running:**
- ✅ Simulator generating data (port 8003)
- ✅ Node-RED processing MQTT → PostgreSQL
- ✅ Grafana dashboards (port 3001)
- ✅ PostgreSQL + TimescaleDB (port 5433)

---

## ⚠️ Minor Issues to Address During Implementation

### Issue #1: Model Storage Volume ✅ **ALREADY FIXED**
**Status:** No action needed  
**What was done:** Added `volumes: - ./analytics/models/saved:/app/models/saved` to docker-compose.yml  
**Your action:** Use this volume path in your code (`/app/models/saved`)

---

### Issue #2: Machine Status Integration 🟡 **ACTION REQUIRED**
**Status:** Needs your attention during implementation  

**Context:**  
Phase 2 implemented real-time machine status tracking. The `machine_status` table is now populated via Node-RED with:
- `machine_id` (UUID)
- `is_running` (boolean) - true when machine is active
- `current_mode` (enum) - 'idle', 'running', 'maintenance', 'fault', 'offline'
- `current_power_kw` (decimal)
- `last_updated` (timestamp)

**Impact on your implementation:**

1. **Baseline Training** (`services/baseline_service.py`):
   - Filter training data by `is_running = TRUE`
   - Exclude maintenance/fault periods
   ```python
   # ADD JOIN in training data query:
   JOIN machine_status ms ON er.machine_id = ms.machine_id
   WHERE ms.is_running = TRUE 
     AND ms.current_mode NOT IN ('maintenance', 'fault', 'offline')
   ```

2. **Anomaly Detection** (`services/anomaly_service.py`):
   - Don't flag anomalies during maintenance
   - Check machine status before saving anomaly
   ```python
   # Before flagging anomaly:
   if machine_status.current_mode == 'maintenance':
       continue  # Skip - expected behavior
   ```

3. **KPI Calculations** (`services/kpi_service.py`):
   - Consider filtering by operational periods only
   - Optional: add status context to KPI results

**Your action:** Add `machine_status` table joins to your queries where relevant. This wasn't in your original plan but is a valuable enhancement.

---

### Issue #3: Nginx Timeout Configuration 🟢 **ACTION REQUIRED**
**Status:** Fix when uncommenting nginx routes  

**Context:**  
Your plan specifies 300-second timeouts for ML operations, but current nginx config has 180 seconds.

**Your action:**  
When uncommenting analytics routes in `/nginx/conf.d/default.conf`, update timeouts:
```nginx
# Change these lines:
proxy_send_timeout 300s;     # (currently 180s)
proxy_read_timeout 300s;     # (currently 180s)
proxy_connect_timeout 60s;   # (keep as is)
```

---

## 🚀 Implementation Instructions

### Start with Session 1 (2-3 hours):
Follow your plan's "Session 1: Core Infrastructure" tasks:

1. ✅ Create `Dockerfile` (use Python 3.12-slim as planned)
2. ✅ Create `requirements.txt` (use packages from your plan)
3. ✅ Create `main.py` (FastAPI app with lifespan)
4. ✅ Create `config.py` (load environment variables)
5. ✅ Create `database.py` (asyncpg connection pool)
6. 🟡 **Remember:** Add `machine_status` joins where appropriate
7. ✅ Create health endpoint (`/health`)
8. ✅ Build and test: `docker compose build analytics`
9. ✅ Start service: `docker compose up -d analytics`

### Key Points:
- Model storage volume path: `/app/models/saved` (already configured)
- Port: 8001 (already configured)
- Database connection: Use existing environment variables in docker-compose.yml
- All KPI functions exist - call them via SQL, don't reimplement
- Machine status table: Use it to improve model quality

---

## 📋 Pre-Implementation Checklist

Before you start coding:
- [x] Review `PHASE-03-ANALYTICS-ML-PLAN.md` (your original plan)
- [x] Review `PHASE-03-PLAN-REVIEW.md` (detailed alignment check)
- [x] Read this prompt (current document)
- [ ] Understand machine_status integration requirement
- [ ] Note model storage volume path: `/app/models/saved`
- [ ] Note nginx timeout change needed when uncommenting

---

## 💡 Implementation Tips

1. **Use existing database functions:**  
   All KPI calculations already exist as PostgreSQL functions. Call them via SQL:
   ```python
   result = await conn.fetchrow(
       "SELECT * FROM calculate_sec($1, $2, $3)",
       machine_id, start_time, end_time
   )
   ```

2. **Machine status is your friend:**  
   Use it to improve model accuracy by filtering out maintenance/offline periods.

3. **Test incrementally:**  
   Build → Start → Check logs → Test health endpoint → Proceed

4. **Nginx uncommenting:**  
   Do this at the end of Session 3 when service is fully working.
