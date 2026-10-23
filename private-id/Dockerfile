FROM python:3.11-slim

WORKDIR /app

# Install lightweight dependencies
RUN pip install --no-cache-dir flask

# Copy only the files belonging to this specific microservice
COPY . .

EXPOSE 8080

CMD ["python", "app.py"]
