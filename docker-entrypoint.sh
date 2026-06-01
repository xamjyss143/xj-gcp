#!/bin/sh
set -eu

NGINX_CONF="/etc/nginx/nginx.conf"
API_URL="https://vpnhub.cloud/xjvpn/api/server/register-gcp"

if [ -z "${GCP_HOST:-}" ]; then
  echo "ERROR: GCP_HOST is not set"
  exit 1
fi

echo "Using GCP_HOST=$GCP_HOST"

register_servers() {
  awk '
  /location \/[a-z0-9]+ \{/ {
      path=$2
  }
  /proxy_pass http:\/\/[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+:700;/ {
      gsub(";", "", $2)
      gsub("http://", "", $2)
      split($2, parts, ":")
      print path "|" parts[1]
  }
  ' "$NGINX_CONF" | while IFS="|" read -r gcp_path ip; do
      code=$(echo "$gcp_path" | sed 's#^/##')
      gcp_xray_path="/vless_${code}"
      gcp_vmess_path="/vmess_${code}"
      gcp_trojan_path="/trojan-ws_${code}"

      echo "Registering $ip -> $gcp_path"

      curl -sS --connect-timeout 5 --max-time 15 -X POST "$API_URL" \
        -H "Content-Type: application/json" \
        -H "Accept: application/json" \
        -d "{
          \"ip\": \"$ip\",
          \"gcp_host\": \"$GCP_HOST\",
          \"gcp_path\": \"$gcp_path\",
          \"gcp_xray_path\": \"$gcp_xray_path\",
          \"gcp_vmess_path\": \"$gcp_vmess_path\",
          \"gcp_trojan_path\": \"$gcp_trojan_path\"
        }" || echo "WARNING: registration failed for $ip"

      echo ""
  done
}

nginx -t
register_servers &
exec nginx -g 'daemon off;'
