#!/bin/bash
# start_services.sh
# Lives on the VM at:
#   /home/azureuser/Ramakrishna/claims-SLM-Finetune/start_services.sh
# Called by run_demo.bat on the manager's Windows machine.
# Kills stale processes, then starts all 4 services in the background.
# If all 4 services are already running, skips startup entirely.

BASE=/home/azureuser/Ramakrishna/claims-SLM-Finetune
PYTHON=$BASE/slm-env/bin/python
LOG_DIR=/tmp/motor_demo_logs

mkdir -p "$LOG_DIR"

echo "=== Motor Claims Demo — Service Startup ==="
echo "Base: $BASE"
echo ""

# ── Check if all services are already running ─────────────────────────────────
ALL_UP=true
for PORT in 8500 8501 8502 5000; do
    if ! lsof -ti:$PORT >/dev/null 2>&1; then
        ALL_UP=false
        break
    fi
done

if [ "$ALL_UP" = true ]; then
    echo "All services are already running — skipping startup."
    echo ""
    echo "=== Port check ==="
    for PORT in 8500 8501 8502 5000; do
        echo "  [OK]  Port $PORT is listening"
    done
    echo ""
    echo "Done. Port forwarding will connect now."
    exit 0
fi

# ── Kill anything already running on these ports ──────────────────────────────
for PORT in 8500 8501 8502 5000; do
    PID=$(lsof -ti:$PORT 2>/dev/null)
    if [ -n "$PID" ]; then
        kill -9 $PID 2>/dev/null
        echo "[cleanup] Stopped existing process on port $PORT (PID $PID)"
    fi
done
sleep 1

# ── Terminal 1: MCP Server (port 8500) ───────────────────────────────────────
cd "$BASE/MotorTriageAgents"
nohup $PYTHON MCP/main.py > "$LOG_DIR/mcp.log" 2>&1 &
MCP_PID=$!
echo "[1/4] MCP server started (PID $MCP_PID, port 8500) — waiting 10s..."
sleep 10

# ── Terminal 2: Intake Validation Agent (port 8501) ──────────────────────────
nohup $PYTHON MotorIntakeValidationAgent/server.py > "$LOG_DIR/intake.log" 2>&1 &
INTAKE_PID=$!
echo "[2/4] Intake Validation Agent started (PID $INTAKE_PID, port 8501) — waiting 10s..."
sleep 10

# ── Terminal 3: Motor Triage Agent (port 8502) ───────────────────────────────
# This agent loads an ML model — needs the most time to be ready
nohup $PYTHON MotorTriageAgent/server.py > "$LOG_DIR/triage.log" 2>&1 &
TRIAGE_PID=$!
echo "[3/4] Motor Triage Agent started (PID $TRIAGE_PID, port 8502) — waiting 20s for model load..."
sleep 20

# ── Terminal 4: Frontend App (port 5000) ─────────────────────────────────────
cd "$BASE/motor_claims"
nohup npm run dev > "$LOG_DIR/app.log" 2>&1 &
APP_PID=$!
echo "[4/4] Frontend app started (PID $APP_PID, port 5000) — waiting 8s..."
sleep 8

# ── Health check ──────────────────────────────────────────────────────────────
echo ""
echo "=== Port check ==="
for PORT in 8500 8501 8502 5000; do
    if lsof -ti:$PORT >/dev/null 2>&1; then
        echo "  [OK]  Port $PORT is listening"
    else
        echo "  [!!]  Port $PORT is NOT listening — check $LOG_DIR/*.log"
    fi
done

echo ""
echo "Logs: $LOG_DIR/"
echo "Done. Port forwarding will connect now."
