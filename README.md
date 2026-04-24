# mini-apps

Multi-App-Hosting auf Hetzner CX22 mit Docker + Caddy + GitHub Actions.

## Architektur

```
Internet → Cloudflare DNS → Hetzner CX22
                              ├── Caddy (80/443) — Reverse Proxy + Auto-HTTPS
                              ├── hello-world (intern: :8000)
                              ├── rezept-finder (intern: :8000)
                              └── weitere Apps...
```

## Setup

### 1. Server einrichten
```bash
# Als root auf dem neuen Hetzner-Server:
bash scripts/server-setup.sh
```

### 2. Env-Datei anlegen
```bash
cp .env.example .env
nano .env   # Werte eintragen
```

### 3. Starten
```bash
docker compose up -d --build
```

### 4. GitHub Secrets setzen
| Secret | Inhalt |
|--------|--------|
| `HETZNER_HOST` | Server-IP |
| `HETZNER_SSH_KEY` | Privater SSH-Key (für deploy-User) |
| `DOMAIN` | z.B. `meine-domain.de` |
| `SUPABASE_URL` | Aus Supabase Dashboard |
| `SUPABASE_KEY` | Anon-Key aus Supabase |

## Apps hinzufügen

1. `apps/neue-app/` Ordner mit `Dockerfile` erstellen
2. Service in `docker-compose.yml` eintragen (auskommentiertes Beispiel kopieren)
3. Route in `caddy/Caddyfile` eintragen
4. Git push → Auto-Deploy

## Deployment

```
git push origin main
→ GitHub Actions
→ SSH zu Hetzner
→ git pull + docker compose up -d --build
```
