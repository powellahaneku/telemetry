#!/bin/bash

echo "🔧 Installing Docker..."
sudo yum update -y
sudo yum install -y docker git curl
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker ec2-user

echo "📁 Creating otel-stack folder..."
mkdir -p ~/otel-stack
cd ~/otel-stack

echo "📦 Creating docker-compose.yml..."
cat <<EOF > docker-compose.yml
version: "3"
services:
  otel-collector:
    image: otel/opentelemetry-collector-contrib:latest
    container_name: otel-collector
    command: ["--config=/etc/otelcol/config.yaml"]
    volumes:
      - ./otel-collector-config.yaml:/etc/otelcol/config.yaml
      - otel_data:/var/lib/otel-collector    
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
  file:
    path: /var/lib/otel-collector/trace-output.json
    rotation:
      max_megabytes: 5
      max_days: 7
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
      exporters: [jaeger, logging, file]
volumes:
  otel_data:

EOF

echo "🚀 Starting the stack..."
sudo docker compose -f docker-compose.yml up -d

echo "✅ Done. OpenTelemetry Collector is running."
echo "🌐 Jaeger UI: http://<your-ec2-ip>:16686"
