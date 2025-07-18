#!/bin/bash

echo "🔧 Installing Docker and Docker Compose..."
sudo apt update -y
sudo apt install -y docker.io docker-compose
sudo systemctl enable docker
sudo usermod -aG docker ubuntu

echo "📁 Creating otel-stack folder..."
mkdir -p ~/otel-stack
cd ~/otel-stack

echo "📦 Creating docker-compose.yml..."
cat <<EOF > docker-compose.yml
version: "3.9"
services:
  otel-collector:
    image: otel/opentelemetry-collector-contrib:latest
    container_name: otel-collector
    command: ["--config=/etc/otelcol/config.yaml"]
    volumes:
      - ./otel-collector-config.yaml:/etc/otelcol/config.yaml
    ports:
      - "4317:4317"
      - "4318:4318"
      - "8888:8888"

  jaeger:
    image: jaegertracing/all-in-one:1.54
    container_name: jaeger
    ports:
      - "16686:16686"
      - "14250:14250"
EOF

echo "📘 Creating otel-collector-config.yaml..."
cat <<EOF > otel-collector-config.yaml
receivers:
  otlp:
    protocols:
      grpc:
      http:

exporters:
  jaeger:
    endpoint: jaeger:14250
    tls:
      insecure: true
  logging:
    loglevel: debug

service:
  pipelines:
    traces:
      receivers: [otlp]
      exporters: [jaeger, logging]
EOF

echo "🚀 Starting the stack..."
sudo docker compose up -d

echo "✅ Done. OpenTelemetry Collector is running."
echo "🌐 Jaeger UI: http://<your-ec2-ip>:16686"
