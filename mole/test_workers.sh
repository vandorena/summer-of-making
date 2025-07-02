#!/bin/bash

# Test script for Mole Browser worker pool
# Run this on your MacBook to test the worker system

HOST="sequoia:5001"
JOBS=()

echo "🐭 Testing Mole Browser Worker Pool"
echo "=================================="

# Function to submit a job and extract job ID
submit_job() {
    local task="$1"
    local provider="${2:-anthropic}"
    local model="${3:-claude-3-5-sonnet-20241022}"
    
    echo "📤 Submitting: $task"
    response=$(curl -s -X POST http://$HOST/run \
        -H "Content-Type: application/json" \
        -d "{\"task\":\"$task\", \"provider\":\"$provider\", \"model\":\"$model\"}")
    
    job_id=$(echo "$response" | python3 -c "import sys, json; print(json.load(sys.stdin).get('job_id', ''))" 2>/dev/null)
    if [ -n "$job_id" ]; then
        JOBS+=("$job_id")
        echo "   ✅ Job ID: $job_id"
    else
        echo "   ❌ Failed: $response"
    fi
    echo
}

# Function to check job status
check_job() {
    local job_id="$1"
    echo "🔍 Checking job: $job_id"
    curl -s http://$HOST/status/$job_id | jq -r '.status // "unknown"'
}

# Function to show worker summary
show_summary() {
    echo "📊 Worker Summary:"
    curl -s http://$HOST/health | jq '.workers'
    echo
}

echo "🚀 Starting test..."
echo

# Check initial status
show_summary

# Submit multiple jobs quickly to test queue
echo "📨 Submitting 5 jobs to test worker pool..."
submit_job "Navigate to google.com and search for 'AI news'"
submit_job "Go to github.com and find a trending repository from today" "openai" "gpt-4o-mini"
submit_job "Visit reddit.com and check the front page"
submit_job "Navigate to weather.com and check the forecast"
submit_job "Go to wikipedia.org and search for 'machine learning'"

echo "💡 Visit http://$HOST/dashboard to see real-time status"
echo

# Show immediate status
show_summary

# Wait a bit and check job statuses
echo "⏱️  Waiting 10 seconds then checking job statuses..."
sleep 10

echo "📋 Job Status Check:"
for job_id in "${JOBS[@]}"; do
    if [ -n "$job_id" ]; then
        status=$(check_job "$job_id")
        echo "   $job_id: $status"
    fi
done
echo

# Show final summary
show_summary

echo "🎯 Test complete!"
echo "   - Dashboard: http://$HOST/dashboard"
echo "   - Health: http://$HOST/health"
echo "   - Jobs list: http://$HOST/jobs"
echo
echo "💡 Tips:"
echo "   - Only 3 jobs run simultaneously"
echo "   - Others queue until workers are free"
echo "   - Dashboard auto-refreshes every 5 seconds"
