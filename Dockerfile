# FinRL Trading Platform Dockerfile
FROM python:3.11-slim

# Set environment variables
ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE=1
# Fix: consolidate PYTHONPATH into a single ENV instruction to avoid the second one overwriting the first
ENV PYTHONPATH=/app/src:/app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    curl \
    sqlite3 \
    && rm -rf /var/lib/apt/lists/*

# Create app directory
WORKDIR /app

# Copy requirements first for better caching
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY src/ ./src/
COPY setup.py .
COPY README.md .
# Note: .env files are optional; ignore errors if they don't exist
COPY .env* ./

# Install the package in development mode
RUN pip install -e .

# Create necessary directories
# Also create a models/ directory for saving trained RL model checkpoints locally
# Added notebooks/ so I can mount Jupyter notebooks for experimentation without rebuilding
RUN mkdir -p data logs models notebooks

# Create non-root user
RUN useradd --create-home --shell /bin/bash app \
    && chown -R app:app /app
USER app

# Health check - increased start-period to give the app more time to initialize
HEALTHCHECK --interval=30s --timeout=30s --start-period=15s --retries=3 \
    CMD python -c "import sys; sys.path.insert(0, '/app/src'); import config; print('Health check passed')" || exit 1

# Expose port for web interface
EXPOSE 8501

# Also expose 8888 for Jupyter if I spin it up locally for experimentation
EXPOSE 8888

# Default command - use the main CLI
CMD ["python", "src/main.py", "dashboard"]
