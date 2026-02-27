# Cue — Wearable Micro-Reflection System

## Cursor Cloud specific instructions

### Repository structure

This is a monorepo with three products. Only the **backend** and **website** are runnable on Linux (the iOS/watchOS frontend requires macOS + Xcode).

| Directory | Stack | Dev command |
|---|---|---|
| `backend/` | Node.js + Express 5, MongoDB | `MONGODB_URI="mongodb://127.0.0.1:27017/cue" npm start` |
| `website/` | Next.js 16, React 19, Tailwind 4 | `npm run dev` (port 3000 by default; use `--port 3001` if backend is also running) |
| `frontend/` | Swift / SwiftUI (Xcode) | N/A on Linux |

### Running services

**MongoDB** must be running before starting the backend. Start it manually (systemd is unavailable in this environment):

```
sudo mongod --dbpath /data/db --logpath /var/log/mongodb/mongod.log --fork --bind_ip 127.0.0.1
```

**Backend API** (Express, port 3000): requires `MONGODB_URI` env var. The server gracefully degrades if `MONGODB_URI` is unset (warns but still starts). Other optional env vars: `ANTHROPIC_API_KEY`, `GOOGLE_CLIENT_ID`, `GOOGLE_CLIENT_SECRET`, `ENCRYPTION_KEY`, `GEOCODING_KEY`.

**Website** (Next.js, default port 3000): independent of the backend. Run on port 3001 (`npx next dev --port 3001`) when the backend is also running.

### Lint / Build / Test

- **Website lint**: `cd website && npm run lint` (ESLint)
- **Website build**: `cd website && npm run build`
- **Backend**: no lint or test scripts are configured; test via `curl` against the running API.

### Gotchas

- The backend has no `dev` script with hot-reload; changes require restarting `node ./bin/www`.
- Next.js 16 uses Turbopack by default for both dev and production builds.
- The backend uses Express 5 (not 4) — async route handlers propagate errors automatically.
