FROM python:3.11-slim

WORKDIR /app

# Install system dependencies for browser automation
RUN apt-get update && apt-get install -y \
    chromium \
    chromium-driver \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements and install with pip
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Install Playwright browsers
RUN playwright install chromium --with-deps

# Copy application code
COPY app.py .

# Set environment variables
ENV PYTHONPATH=/app
ENV CHROME_BIN=/usr/bin/chromium
ENV CHROMEDRIVER_PATH=/usr/bin/chromedriver
ENV BROWSER_USE_DISABLE_TELEMETRY=true
ENV BROWSER_USE_SYNC_ENABLED=false

EXPOSE 5001

CMD ["python", "app.py"]
