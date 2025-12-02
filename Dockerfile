# Use lightweight Alpine base image
FROM python:3.11-alpine

# Create non-root user
RUN addgroup -g 1000 appuser && \
    adduser -D -s /bin/sh -u 1000 -G appuser appuser

# Set working directory
WORKDIR /app

# Copy requirements and install Python dependencies
COPY app/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY app/main.py .

# Change ownership of app directory to non-root user
RUN chown -R appuser:appuser /app

# Switch to non-root user
USER appuser

# Expose port 8080 (container port) for PWD compatibility
EXPOSE 8080

# Run the Flask application
CMD ["python", "main.py"]
