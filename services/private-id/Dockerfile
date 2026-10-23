FROM python:3.11-slim

WORKDIR /app

RUN pip install --no-cache-dir flask==3.0.3

# Copy the microservice code
COPY . .

# Pull the master schema file from the shared directory into this container image
COPY ../../shared/database/base_schema.sql ./base_schema.sql

EXPOSE 8080

CMD ["python", "app.py"]
