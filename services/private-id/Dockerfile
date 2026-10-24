FROM python:3.12-slim

WORKDIR /app

# Paths are relative to the repository root now
COPY services/private-id/requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

# Copy the specific service files into the container working directory
COPY services/private-id/ .

# Cleanly pull the schema without any prohibited "../" syntax
COPY shared/database/base_schema.sql ./base_schema.sql

CMD ["python", "app.py"]

