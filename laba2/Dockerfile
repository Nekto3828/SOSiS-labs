
# Multi-stage build for Python application
# Stage 1: Base image with dependencies
FROM python:3.8-slim-buster AS base

# Set working directory
WORKDIR /app

# Create non-root user for security
RUN useradd -m -u 1000 appuser && \
    chown -R appuser:appuser /app

# Stage 2: Production image
FROM base AS production

# Copy application file
COPY --chown=appuser:appuser main.py .

# Set environment variables
ENV PYTHONUNBUFFERED=1 \
    TIME_SLEEP=5 \
    USE_TIMESTAMP=false \
    PYTHONDONTWRITEBYTECODE=1

# Switch to non-root user
USER appuser

# Health check to monitor container status
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
    CMD python3 -c "import os; print('OK')" || exit 1

# Run application with unbuffered output
CMD ["python3", "-u", "main.py"]

# Stage 3: Development image with additional tools
FROM base AS development

# Install development tools and dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copy application file
COPY --chown=appuser:appuser main.py .

# Set environment variables for development
ENV PYTHONUNBUFFERED=1 \
    TIME_SLEEP=5 \
    USE_TIMESTAMP=false \
    PYTHONDONTWRITEBYTECODE=1

# Switch to non-root user
USER appuser

# Run application with unbuffered output
CMD ["python3", "-u", "main.py"]
