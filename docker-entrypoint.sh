#!/bin/sh
set -e

NGINX_CONF="/etc/nginx/nginx.conf"
API_URL="https://vpnhub.cloud/xjvpn/api/server/register-gcp"

if [ -z "$GCP_HOST" ]; then
  echo "ERROR: GCP_HOST is not set"
  exit 1
fi

awk '
/location \/[a-z0-9]+ \{/ {
    path=$2
}
/proxy_pass http:\/\/[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+:700;/ {
    gsub(";", "", $2)
    gsub("http://", "", $2)
    split($2, parts, ":")
    ip=parts[1]
    print path "|" ip
}
' "$NGINX_CONF" | while IFS="|" read -r gcp_path ip; do
    code=$(echo "$gcp_path" | sed 's#^/##')
    gcp_xray_path="/vmess_${code}"

    echo "Registering $ip -> $gcp_path -> $gcp_xray_path with host=$GCP_HOST"

    curl -X POST "$API_URL" \
      -H "Content-Type: application/json" \
      -H "Accept: application/json" \
      -d "{
        \"ip\": \"$ip\",
        \"gcp_host\": \"$GCP_HOST\",
        \"gcp_path\": \"$gcp_path\",
        \"gcp_xray_path\": \"$gcp_xray_path\"
      }"

    echo ""
done

exec nginx -g 'daemon off;'
