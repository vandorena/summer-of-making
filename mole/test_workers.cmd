@echo off
setlocal enabledelayedexpansion

echo Testing Mole Browser Worker Pool
echo ==================================

set HOST=localhost:5001

echo Checking health...
curl -s "http://%HOST%/health"
echo.

echo.
echo Submitting 3 test jobs...

echo Submitting job 1...
curl -s -X POST "http://%HOST%/run" -H "Content-Type: application/json" -d "{\"task\":\"Navigate to google.com and search for AI news\", \"provider\":\"anthropic\"}"
echo.

echo Submitting job 2...
curl -s -X POST "http://%HOST%/run" -H "Content-Type: application/json" -d "{\"task\":\"Go to github.com and browse trending repositories\", \"provider\":\"anthropic\"}"
echo.

echo Submitting job 3...
curl -s -X POST "http://%HOST%/run" -H "Content-Type: application/json" -d "{\"task\":\"Visit reddit.com and check the front page\", \"provider\":\"anthropic\"}"
echo.

echo.
echo Waiting 5 seconds then checking status...
timeout 5 >nul

echo.
echo Current worker status:
curl -s "http://%HOST%/health"
echo.

echo.
echo All jobs:
curl -s "http://%HOST%/jobs"
echo.

echo.
echo Visit http://%HOST%/dashboard to see real-time status
