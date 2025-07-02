import os
import asyncio
import tempfile
import uuid
import threading
import time
import shutil
import hashlib
import subprocess
import json
import sys
from concurrent.futures import ThreadPoolExecutor
from flask import Flask, request, jsonify
from browser_use import Agent, BrowserSession
from dotenv import load_dotenv
import requests
from pathlib import Path
from screeninfo import get_monitors

load_dotenv()

app = Flask(__name__)

# Worker pool configuration
MAX_WORKERS = 3  # Use multiple subprocess workers
executor = ThreadPoolExecutor(max_workers=MAX_WORKERS)
jobs = {}  # Store job status and results

class BrowserAgent:
    def create_agent(self, task_prompt, provider="anthropic", model=None, api_key=None, gif_path=None, initial_actions=None):
        """Create an agent with specified provider and credentials"""
        if provider == "anthropic":
            from browser_use.llm import ChatAnthropic
            llm = ChatAnthropic(
                model=model or "claude-3-7-sonnet-20250219", 
                api_key=api_key
            )
        elif provider == "openai":
            from browser_use.llm import ChatOpenAI
            llm = ChatOpenAI(
                model=model or "gpt-4o-mini", 
                api_key=api_key
            )
        else:
            raise ValueError(f"Unsupported provider: {provider}")
        
        # Calculate window position based on screen size
        try:
            # Get primary monitor dimensions
            monitors = get_monitors()
            primary_monitor = monitors[0]  # Use first monitor
            screen_width = primary_monitor.width
            screen_height = primary_monitor.height
        except:
            # Fallback to common resolution
            screen_width = 1920
            screen_height = 1080
        
        # Calculate optimal window size and grid
        # Leave 20% margin on each side for taskbar/edges
        usable_width = int(screen_width * 0.8)
        usable_height = int(screen_height * 0.8)
        start_x = int(screen_width * 0.1)
        start_y = int(screen_height * 0.1)
        
        # Get worker ID first
        import threading
        worker_id = threading.current_thread().ident
        
        # For 3 workers max, use 3 columns, 1 row
        cols = 3
        rows = 1
        
        window_width = (usable_width // cols) - 20  # 20px gap between windows
        window_height = min(usable_height - 40, 700)  # Max 700px height
        
        # Use thread ID to determine grid position for consistent tiling
        position_index = (worker_id % 1000) % (cols * rows)  # Ensure we stay within grid
        col = position_index % cols
        row = position_index // cols
        
        x_pos = start_x + col * (window_width + 20)
        y_pos = start_y + row * (window_height + 40)
        
        # Removed print statement to avoid stdout contamination in subprocess
        
        # Create isolated browser session for this worker
        # Use unique user data directory to force separate processes
        user_data_dir = tempfile.mkdtemp(prefix=f"chrome_worker_{worker_id}_")
        
        # Use different debug ports for each worker to prevent interference
        base_debug_port = 9222
        debug_port = base_debug_port + (worker_id % 1000) % 100  # Ensure unique port per worker
        
        # Removed print statement to avoid stdout contamination in subprocess
        
        browser_session = BrowserSession(
            headless=False,  # Make Chrome visible for WebGL
            user_data_dir=user_data_dir,  # Each worker gets its own profile
            args=[
                "--disable-web-security",
                "--allow-running-insecure-content",
                "--no-first-run",
                "--disable-default-apps",
                "--disable-extensions",
                "--disable-background-timer-throttling",
                "--disable-backgrounding-occluded-windows",
                "--disable-renderer-backgrounding",
                "--no-default-browser-check",
                "--disable-sync",
                f"--remote-debugging-port={debug_port}",  # Use unique debug port
                "--disable-dev-shm-usage",  # Prevent crashes
                "--no-sandbox",  # For better compatibility
                "--force-new-instance",  # Force new Chrome instance
                "--disable-session-crashed-bubble",  # Prevent session restore
                "--disable-restore-session-state"  # Don't restore previous session
            ],
            browser_type="chromium",
            keep_alive=False  # Let each session manage its own lifecycle
        )
        
        # Store position info for later use
        browser_session._window_position = (x_pos, y_pos)
        browser_session._window_size = (window_width, window_height)
        
        # Create agent with the actual task prompt
        agent_kwargs = {
            "task": task_prompt,
            "llm": llm,
            "browser_session": browser_session
        }
        
        # Enable GIF generation for debugging
        if gif_path:
            agent_kwargs["generate_gif"] = gif_path
        
        if initial_actions:
            agent_kwargs["initial_actions"] = initial_actions
        
        return Agent(**agent_kwargs), user_data_dir
    
    async def upload_to_hackclub_cdn(self, file_path):
        """Upload file to Hack Club CDN via Bucky transfer"""
        try:
            # Step 1: Upload to Bucky (temporary storage)
            with open(file_path, 'rb') as f:
                files = {'file': f}
                bucky_response = requests.post(
                    'https://bucky.hackclub.com/',
                    files=files,
                    timeout=30
                )
            
            if bucky_response.status_code != 200:
                raise Exception(f"Bucky upload failed: {bucky_response.status_code} - {bucky_response.text}")
            
            bucky_url = bucky_response.text.strip()
            
            # Step 2: Transfer from Bucky to CDN (permanent storage)
            cdn_response = requests.post(
                'https://cdn.hackclub.com/upload',
                json={'url': bucky_url},
                headers={'Content-Type': 'application/json'},
                timeout=30
            )
            
            if cdn_response.status_code == 200:
                # CDN returns the permanent URL
                cdn_data = cdn_response.json()
                return cdn_data.get('url', bucky_url)  # Fallback to bucky URL if no CDN URL
            else:
                # If CDN transfer fails, return the Bucky URL as fallback
                return bucky_url
                
        except Exception as e:
            raise Exception(f"Failed to upload to CDN: {str(e)}")
    
    async def run_task(self, task_prompt, urls=None, provider="anthropic", model=None, api_key=None):
        """Run a generic browser automation task with recording"""
        gif_path = None
        gif_url = None
        user_data_dir = None
        
        try:
            # Create local GIFs directory for debugging
            gifs_dir = os.path.join(os.getcwd(), "gifs")
            os.makedirs(gifs_dir, exist_ok=True)
            
            session_id = str(uuid.uuid4())
            gif_path = os.path.join(gifs_dir, f"session_{session_id}.gif")
            
            # Build the full task prompt with URLs
            if urls:
                urls_text = "\n".join([f"- {url}" for url in urls if url])
                full_prompt = f"{task_prompt}\n\nURLs to visit:\n{urls_text}"
                
                # Start at the first URL to speed things up
                initial_actions = [{'go_to_url': {'url': urls[0], 'new_tab': False}}]
            else:
                full_prompt = task_prompt
                initial_actions = None
            
            # Create agent with the complete task prompt and initial action
            agent, user_data_dir = self.create_agent(full_prompt, provider, model, api_key, gif_path=gif_path, initial_actions=initial_actions)
            
            # Apply window positioning after browser starts
            try:
                if hasattr(agent.browser_session, '_window_position'):
                    x_pos, y_pos = agent.browser_session._window_position
                    width, height = agent.browser_session._window_size
                    
                    # Wait for browser to be ready
                    await agent.browser_session.start()
                    
                    # Try to position the browser window using CDP (Chrome DevTools Protocol)
                    if agent.browser_session.browser_context:
                        try:
                            cdp_session = await agent.browser_session.browser_context.new_cdp_session(
                                agent.browser_session.page
                            )
                            await cdp_session.send("Browser.setWindowBounds", {
                                "windowId": 1,
                                "bounds": {
                                    "left": x_pos,
                                    "top": y_pos,
                                    "width": width,
                                    "height": height
                                }
                            })
                            pass  # Suppress window positioning logs to avoid stdout contamination
                        except Exception as e:
                            pass  # Suppress window positioning errors to avoid stdout contamination
            except Exception as e:
                pass  # Suppress window positioning errors to avoid stdout contamination
            
            # Run the task (removed logging to avoid stdout contamination in subprocess)
            start_time = time.time()
            result = await agent.run()
            end_time = time.time()
            duration = end_time - start_time
            
            # Check if GIF was generated and upload to Bucky
            gif_url = None
            if gif_path and os.path.exists(gif_path):
                try:
                    # Upload to Bucky CDN
                    gif_url = await self.upload_to_hackclub_cdn(gif_path)
                except Exception as e:
                    # Fallback to local path if upload fails
                    gif_url = f"file://{gif_path}"
            
            # Wait a bit to ensure browser actions complete
            if duration < 5:  # If task completed very quickly, it might be an error
                await asyncio.sleep(2)  # Give time for potential delayed actions
            
            # Extract result properly
            if hasattr(result, 'final_result'):
                final_result = result.final_result()
            elif hasattr(result, 'result'):
                final_result = result.result
            else:
                final_result = str(result)
            
            return {
                "success": True,
                "result": final_result,
                "raw_result": str(result),  # Include raw result for debugging
                "gif_url": gif_url,  # Local file path for debugging
                "gif_path": gif_path if os.path.exists(gif_path) else None,  # Local path
                "session_id": session_id,
                "error": None
            }
            
        except Exception as e:
            return {
                "success": False,
                "result": None,
                "gif_url": None,
                "session_id": None,
                "error": str(e)
            }
        finally:
            # Keep GIFs for debugging, only clean up Chrome profile directory
            if user_data_dir and os.path.exists(user_data_dir):
                try:
                    shutil.rmtree(user_data_dir, ignore_errors=True)
                except:
                    pass

def run_task_subprocess(job_id, task_prompt, urls, provider, model, api_key):
    """Launch task in separate subprocess for complete isolation"""
    try:
        # Update job status
        jobs[job_id]["status"] = "running"
        jobs[job_id]["started_at"] = time.time()
        
        # Prepare task data for subprocess
        task_data = {
            "task_prompt": task_prompt,
            "urls": urls,
            "provider": provider,
            "model": model,
            "api_key": api_key,
            "job_id": job_id
        }
        
        # Launch subprocess with stderr redirected to prevent logging corruption
        process = subprocess.Popen([
            sys.executable, __file__, "--subprocess"
        ], 
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        stderr=subprocess.DEVNULL,  # Suppress stderr to prevent JSON corruption
        text=True
        )
        
        # Send task data to subprocess
        task_json = json.dumps(task_data)
        stdout, _ = process.communicate(input=task_json)
        
        # Debug logging - capture raw output
        print(f"DEBUG: Job {job_id} - Return code: {process.returncode}")
        print(f"DEBUG: Job {job_id} - Raw stdout length: {len(stdout)}")
        print(f"DEBUG: Job {job_id} - Raw stdout (first 500 chars): {repr(stdout[:500])}")
        
        if process.returncode == 0 and stdout.strip():
            try:
                # Parse result from subprocess
                result = json.loads(stdout.strip())
                jobs[job_id]["status"] = "completed"
                jobs[job_id]["result"] = result
                jobs[job_id]["completed_at"] = time.time()
                print(f"DEBUG: Job {job_id} - Successfully parsed JSON result")
            except json.JSONDecodeError as e:
                # Handle JSON parsing error
                jobs[job_id]["status"] = "failed"
                jobs[job_id]["error"] = f"Failed to parse subprocess output: {e}. Raw output: {repr(stdout[:200])}"
                jobs[job_id]["completed_at"] = time.time()
                print(f"DEBUG: Job {job_id} - JSON parse error: {e}")
        else:
            # Handle subprocess error
            jobs[job_id]["status"] = "failed"
            jobs[job_id]["error"] = f"Subprocess failed with return code {process.returncode}. Output: {repr(stdout[:200])}"
            jobs[job_id]["completed_at"] = time.time()
            print(f"DEBUG: Job {job_id} - Subprocess failed or empty output")
            
    except Exception as e:
        # Update job with error
        jobs[job_id]["status"] = "failed"
        jobs[job_id]["error"] = str(e)
        jobs[job_id]["completed_at"] = time.time()

@app.route('/run', methods=['POST'])
def start_browser_task():
    """Start a browser automation task"""
    data = request.get_json()
    
    if not data:
        return jsonify({"error": "No JSON data provided"}), 400
    
    task_prompt = data.get('task')
    urls = data.get('urls', [])
    provider = data.get('provider', 'anthropic')
    model = data.get('model')
    api_key = data.get('api_key')
    
    if not task_prompt:
        return jsonify({"error": "Task prompt is required"}), 400
    
    # Use API key from env if not provided in request
    if not api_key:
        if provider == 'anthropic':
            api_key = os.getenv('ANTHROPIC_API_KEY')
        elif provider == 'openai':
            api_key = os.getenv('OPENAI_API_KEY')
        elif provider == 'gemini':
            api_key = os.getenv('GEMINI_API_KEY')
    
    if not api_key:
        return jsonify({"error": f"API key is required for {provider}"}), 400
    
    # Create job
    job_id = str(uuid.uuid4())
    jobs[job_id] = {
        "status": "queued",
        "task": task_prompt,
        "provider": provider,
        "model": model,
        "urls": urls,
        "created_at": time.time(),
        "result": None,
        "error": None
    }
    
    # Submit to thread pool
    executor.submit(run_task_subprocess, job_id, task_prompt, urls, provider, model, api_key)
    
    return jsonify({
        "job_id": job_id,
        "status": "queued",
        "message": f"Task submitted to worker pool ({len([j for j in jobs.values() if j['status'] == 'running'])} running, {len([j for j in jobs.values() if j['status'] == 'queued'])} queued)"
    })

@app.route('/status/<job_id>', methods=['GET'])
def get_job_status(job_id):
    """Get status of a specific job"""
    if job_id not in jobs:
        return jsonify({"error": "Job not found"}), 404
    
    job = jobs[job_id].copy()
    # Calculate duration if job is running or completed
    if "started_at" in job and job["started_at"]:
        end_time = job.get("completed_at", time.time())
        job["duration"] = round(end_time - job["started_at"], 2)
    
    return jsonify(job)

@app.route('/jobs', methods=['GET'])
def list_jobs():
    """List all jobs with their status"""
    job_list = []
    for job_id, job_data in jobs.items():
        job_summary = {
            "job_id": job_id,
            "status": job_data["status"],
            "task": job_data["task"][:100] + "..." if len(job_data["task"]) > 100 else job_data["task"],
            "provider": job_data["provider"],
            "created_at": job_data["created_at"]
        }
        if "started_at" in job_data and job_data["started_at"]:
            end_time = job_data.get("completed_at", time.time())
            job_summary["duration"] = round(end_time - job_data["started_at"], 2)
        job_list.append(job_summary)
    
    # Sort by creation time (newest first)
    job_list.sort(key=lambda x: x["created_at"], reverse=True)
    
    return jsonify({
        "jobs": job_list,
        "summary": {
            "total": len(jobs),
            "queued": len([j for j in jobs.values() if j["status"] == "queued"]),
            "running": len([j for j in jobs.values() if j["status"] == "running"]),
            "completed": len([j for j in jobs.values() if j["status"] == "completed"]),
            "failed": len([j for j in jobs.values() if j["status"] == "failed"]),
            "max_workers": MAX_WORKERS
        }
    })

@app.route('/dashboard')
def dashboard():
    """Web dashboard showing job status"""
    job_list = []
    for job_id, job_data in jobs.items():
        job_info = {
            "job_id": job_id,
            "status": job_data["status"],
            "task": job_data["task"],
            "provider": job_data["provider"],
            "model": job_data.get("model", "default"),
            "created_at": time.strftime('%Y-%m-%d %H:%M:%S', time.localtime(job_data["created_at"])),
            "duration": None,
            "error": job_data.get("error")
        }
        
        if "started_at" in job_data and job_data["started_at"]:
            end_time = job_data.get("completed_at", time.time())
            job_info["duration"] = round(end_time - job_data["started_at"], 2)
        
        if job_data["status"] == "completed" and job_data.get("result"):
            job_info["success"] = job_data["result"].get("success", False)
            if job_data["result"].get("result"):
                job_info["result_preview"] = str(job_data["result"]["result"])[:200]
            if job_data["result"].get("gif_url"):
                job_info["gif_url"] = job_data["result"]["gif_url"]
        
        job_list.append(job_info)
    
    # Sort by creation time (newest first)
    job_list.sort(key=lambda x: x["job_id"], reverse=True)
    
    summary = {
        "total": len(jobs),
        "queued": len([j for j in jobs.values() if j["status"] == "queued"]),
        "running": len([j for j in jobs.values() if j["status"] == "running"]),
        "completed": len([j for j in jobs.values() if j["status"] == "completed"]),
        "failed": len([j for j in jobs.values() if j["status"] == "failed"]),
        "max_workers": MAX_WORKERS
    }
    
    html = f"""
    <!DOCTYPE html>
    <html>
    <head>
        <title>Mole Browser Dashboard</title>
        <meta http-equiv="refresh" content="5">
        <style>
            body {{ font-family: Arial, sans-serif; margin: 20px; background-color: #f5f5f5; }}
            .header {{ background-color: #333; color: white; padding: 20px; border-radius: 5px; margin-bottom: 20px; }}
            .summary {{ background-color: white; padding: 15px; border-radius: 5px; margin-bottom: 20px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }}
            .jobs {{ background-color: white; border-radius: 5px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }}
            .job {{ padding: 15px; border-bottom: 1px solid #eee; }}
            .job:last-child {{ border-bottom: none; }}
            .status {{ padding: 4px 8px; border-radius: 3px; color: white; font-size: 12px; font-weight: bold; }}
            .status.queued {{ background-color: #ffa500; }}
            .status.running {{ background-color: #007bff; }}
            .status.completed {{ background-color: #28a745; }}
            .status.failed {{ background-color: #dc3545; }}
            .task {{ font-weight: bold; margin: 5px 0; }}
            .details {{ color: #666; font-size: 14px; }}
            .job-id {{ font-family: monospace; font-size: 12px; color: #999; }}
            .error {{ background-color: #f8d7da; color: #721c24; padding: 8px; border-radius: 3px; margin-top: 5px; }}
            .result-preview {{ background-color: #d4edda; color: #155724; padding: 8px; border-radius: 3px; margin-top: 5px; font-size: 12px; }}
        </style>
    </head>
    <body>
        <div class="header">
            <h1>🐭 Mole Browser Dashboard</h1>
            <p>Auto-refreshes every 5 seconds</p>
        </div>
        
        <div class="summary">
            <h2>Worker Summary</h2>
            <p><strong>Workers:</strong> {summary['running']}/{summary['max_workers']} running, {summary['queued']} queued</p>
            <p><strong>Jobs:</strong> {summary['total']} total ({summary['completed']} completed, {summary['failed']} failed)</p>
        </div>
        
        <div class="jobs">
            <h2>Recent Jobs</h2>
    """
    
    if not job_list:
        html += "<div class='job'>No jobs yet</div>"
    else:
        for job in job_list:
            duration_text = f" ({job['duration']}s)" if job['duration'] else ""
            html += f"""
            <div class="job">
                <div class="task">{job['task'][:100]}{'...' if len(job['task']) > 100 else ''}</div>
                <div class="details">
                    <span class="status {job['status']}">{job['status'].upper()}</span>
                    {job['provider']} ({job['model']}) • {job['created_at']}{duration_text}
                </div>
                <div class="job-id">{job['job_id']}</div>
            """
            
            if job.get('error'):
                html += f"<div class='error'>Error: {job['error']}</div>"
            
            if job.get('result_preview'):
                html += f"<div class='result-preview'>Result: {job['result_preview']}...</div>"
            
            if job.get('gif_url'):
                if job['gif_url'].startswith('http'):
                    # Bucky CDN URL
                    html += f"<div class='result-preview'>🎬 GIF: <a href='{job['gif_url']}' target='_blank'>View GIF</a></div>"
                else:
                    # Local file fallback
                    gif_filename = os.path.basename(job['gif_url'].replace('file://', ''))
                    html += f"<div class='result-preview'>🎬 GIF: <a href='{job['gif_url']}' target='_blank'>{gif_filename}</a></div>"
            
            html += "</div>"
    
    html += """
        </div>
    </body>
    </html>
    """
    
    return html

@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    return jsonify({
        "status": "healthy", 
        "service": "mole-browser",
        "workers": {
            "max": MAX_WORKERS,
            "running": len([j for j in jobs.values() if j["status"] == "running"]),
            "queued": len([j for j in jobs.values() if j["status"] == "queued"])
        }
    })

def subprocess_worker():
    """Worker function that runs in subprocess for complete browser isolation"""
    # Debug log to file to avoid stdout contamination
    debug_file = f"debug_subprocess_{os.getpid()}.log"
    
    try:
        with open(debug_file, "w") as f:
            f.write("Subprocess started\n")
            f.flush()
        
        # Suppress ALL logging to prevent JSON corruption
        import logging
        import sys
        
        # Disable all logging
        logging.disable(logging.CRITICAL)
        
        # Redirect stderr to null to catch any remaining output
        sys.stderr = open(os.devnull, 'w')
        
        # Read task data from stdin
        task_json = sys.stdin.read()
        
        with open(debug_file, "a") as f:
            f.write(f"Read input: {len(task_json)} chars\n")
            f.flush()
            
        task_data = json.loads(task_json)
        
        # Extract task parameters
        task_prompt = task_data["task_prompt"]
        urls = task_data.get("urls", [])
        provider = task_data["provider"]
        model = task_data.get("model")
        api_key = task_data["api_key"]
        job_id = task_data["job_id"]
        
        with open(debug_file, "a") as f:
            f.write(f"Parsed task data for job {job_id}\n")
            f.flush()
        
        # Create browser agent and run task
        browser_agent = BrowserAgent()
        
        # Run async task
        loop = asyncio.new_event_loop()
        asyncio.set_event_loop(loop)
        
        try:
            with open(debug_file, "a") as f:
                f.write("Starting browser task\n")
                f.flush()
                
            result = loop.run_until_complete(
                browser_agent.run_task(task_prompt, urls, provider, model, api_key)
            )
            
            with open(debug_file, "a") as f:
                f.write(f"Task completed, result type: {type(result)}\n")
                f.flush()
            
            # Ensure we only output valid JSON to stdout
            json_output = json.dumps(result)
            
            with open(debug_file, "a") as f:
                f.write(f"JSON output length: {len(json_output)}\n")
                f.flush()
                
            sys.stdout.write(json_output)
            sys.stdout.flush()
            
        finally:
            loop.close()
            
    except Exception as e:
        with open(debug_file, "a") as f:
            f.write(f"Error occurred: {str(e)}\n")
            f.flush()
            
        # Output error as JSON
        error_result = {
            "success": False,
            "result": None,
            "error": str(e)
        }
        sys.stdout.write(json.dumps(error_result))
        sys.stdout.flush()
        sys.exit(1)

if __name__ == '__main__':
    if len(sys.argv) > 1 and sys.argv[1] == "--subprocess":
        subprocess_worker()
    else:
        app.run(host='0.0.0.0', port=5001, debug=True)
