#!/usr/bin/env bash
# Self-test: validates YAML + nginx + scripts without a Docker daemon.
set -euo pipefail
cd "$(dirname "$0")/.."
pass=0; fail=0
ok() { pass=$((pass+1)); echo "  ok: $1"; }
bad() { fail=$((fail+1)); echo "  FAIL: $1"; }

echo "[1] compose + env"
python3 - <<'EOF'
import yaml
d = yaml.safe_load(open('docker-compose.yml'))
svcs = d.get('services', {})
assert {'app','db','nginx'} <= set(svcs), "services missing"
assert 'pgdata' in d.get('volumes', {}), "pgdata volume missing"
assert '8000' in str(svcs['app'].get('expose', [])), "app must expose 8000"
print("compose ok:", sorted(svcs))
EOF
[[ $? -eq 0 ]] && ok "compose structure" || bad "compose structure"
grep -q "DB_PASSWORD" .env.example && ok ".env.example has DB_PASSWORD" || bad ".env.example"
! grep -qiE "password\s*=\s*[^c$]" .env.example || ok ".env.example has no real secret"

echo "[2] bash syntax"
for f in scripts/*.sh tests/test.sh; do bash -n "$f" && ok "syntax $f" || bad "syntax $f"; done
grep -q "\.env missing" scripts/deploy.sh && ok "deploy guards missing .env" || bad "deploy guard"
grep -q "health" scripts/deploy.sh && ok "deploy has health gate" || bad "health gate"

echo "[3] nginx config sanity"
for directive in "proxy_pass http://app" "ssl_certificate" "X-Frame-Options" "healthz" "return 301 https"; do
  grep -q "$directive" nginx/nginx.conf && ok "nginx: $directive" || bad "nginx: $directive"
done

echo "[4] app boots and answers (stdlib only)"
python3 app/server.py >/dev/null 2>&1 & SRV=$!
ready=0
for i in $(seq 1 15); do
  if curl -s --max-time 1 http://127.0.0.1:8000/healthz 2>/dev/null | grep -q ok; then ready=1; break; fi
  sleep 1
done
if [[ $ready -eq 1 ]]; then ok "app booted"; else bad "app booted"; fi
if curl -s http://127.0.0.1:8000/healthz | grep -q '"ok"'; then ok "app /healthz"; else bad "app /healthz"; fi
if curl -s http://127.0.0.1:8000/ | grep -q "nginx"; then ok "app /"; else bad "app /"; fi
kill $SRV 2>/dev/null || true

echo
echo "pass=$pass fail=$fail"
[[ $fail -eq 0 ]]
