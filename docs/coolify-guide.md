# Coolify + Cloudflare wiring

My setup: one VPS managed by Coolify, Cloudflare in front (SSL/CDN/DNS).

## 1. DNS (Cloudflare)
- `A app.example.com -> <VPS-IP>` (proxied / orange cloud ON)
- SSL mode: **Full (strict)**

## 2. Coolify service
1. Coolify UI → New Resource → **Docker Compose** → connect this repo.
2. Set env from `.env.example`: `DOMAIN`, `ACME_EMAIL`, `DB_PASSWORD` (generate one).
3. Deploy. Coolify builds `app`, starts `nginx`, provisions the TLS cert
   (or paste a Cloudflare Origin cert into `nginx/certs/`).
4. Open `https://app.example.com/healthz` → expect `{"status":"ok"}`.

## 3. Rollback
Every deploy tags the previous image. If `/healthz` fails:
```bash
./scripts/rollback.sh previous
```

## 4. Notes
- `nginx.conf` forces HTTP→HTTPS and adds security headers.
- Postgres data lives in the `pgdata` volume — back it up with
  `verdynordsten/postgres-mysql-backup` on a schedule.
