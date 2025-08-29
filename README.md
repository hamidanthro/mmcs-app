# MMCS Monorepo
# - backend/  : Flask API
# - frontend/ : React + Vite UI
# - docker-compose.yml runs everything together

## Quickstart
1) powershell -NoProfile -ExecutionPolicy Bypass -File .\scaffold.ps1   (this file)
2) docker compose up --build
- Backend:  http://localhost:5000/api/health
- Frontend: http://localhost:5173

## Notes
- Frontend fetches http://localhost:5000/api/... to talk to backend.
- This baseline avoids DB use in code so you can confirm connectivity first.
- Add DB models & endpoints next; then wire to Postgres.
