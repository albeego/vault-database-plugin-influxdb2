#!/bin/bash
set -e

go mod tidy && go mod vendor && go build -o terraform-provider-influxdb-v2 cmd/influxdbv2-database-plugin/main.go
sha256sum terraform-provider-influxdb-v2 | cut -d ' ' -f1 > terraform-provider-influxdb-v2.sha256

scp -o StrictHostKeyChecking=no terraform-provider-influxdb-v2 ubuntu@57.128.165.51:/home/ubuntu/terraform-provider-influxdb-v2
ssh -o StrictHostKeyChecking=no ubuntu@57.128.165.51 << EOF
  sudo mv terraform-provider-influxdb-v2 /usr/share/terraform/plugins/influxdb-v2/influxdb-v2/v0.1.0/linux/amd64/terraform-provider-influxdb-v2
  sudo chown ubuntu:ubuntu /usr/share/terraform/plugins/influxdb-v2/influxdb-v2/v0.1.0/linux/amd64/terraform-provider-influxdb-v2
  sudo chmod +x /usr/share/terraform/plugins/influxdb-v2/influxdb-v2/v0.1.0/linux/amd64/terraform-provider-influxdb-v2
EOF