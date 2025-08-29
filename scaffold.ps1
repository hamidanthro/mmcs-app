# scaffold.ps1
# Full MMCS project scaffold: backend (Flask), frontend (React+Vite), Dockerized, with helpful dotfiles

$root = "C:\Users\hamid\OneDrive\Desktop\MyWebApps\MMCS"
$ErrorActionPreference = "Stop"

function Ensure-Dir($p) { New-Item -ItemType Directory -Force -Path $p | Out-Null }

Ensure-Dir $root
Set-Location $root

# ----------------
# Root files
# ----------------
@"
version: "3.9"

services:
  db:
    image: postgres:16
    environment:
      POSTGRES_DB: mmcs
      POSTGRES_USER: mmcs
      POSTGRES_PASSWORD: mmcs
    ports:
      - "5432:5432"
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U mmcs -d mmcs"]
      interval: 5s
      timeout: 5s
      retries: 20

  backend:
    build: ./backend
    env_file:
      - ./backend/.env.example
    environment:
      # Flask will read these envs; DB is optional for this skeleton
      FLASK_APP: app
      FLASK_RUN_HOST: 0.0.0.0
      CORS_ORIGINS: "*"
    ports:
      - "5000:5000"
    depends_on:
      db:
        condition: service_healthy

  frontend:
    build: ./frontend
    ports:
      - "5173:5173"
    depends_on:
      - backend
"@ | Out-File "$root\docker-compose.yml" -Encoding utf8 -Force

@"
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
"@ | Out-File "$root\README.md" -Encoding utf8 -Force

@"
# Ignore local junk
**/__pycache__/
**/.pytest_cache/
**/.DS_Store
**/.env
**/.venv
**/node_modules/
**/dist/
**/.parcel-cache/
**/.turbo/
**/.idea/
**/.vscode/*
!.vscode/settings.json
"@ | Out-File "$root\.gitignore" -Encoding utf8 -Force

@"
# Ignore everything by default
*
!docker-compose.yml
!README.md
!.gitignore
!backend/
!frontend/
!.vscode/
"@ | Out-File "$root\.dockerignore" -Encoding utf8 -Force

Ensure-Dir "$root\.vscode"
@"
{
  "files.eol": "\n",
  "editor.formatOnSave": true
}
"@ | Out-File "$root\.vscode\settings.json" -Encoding utf8 -Force

# ----------------
# Backend
# ----------------
$backend = "$root\backend"
Ensure-Dir $backend
Ensure-Dir "$backend\app\models"

@"
FROM python:3.11-slim

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app ./app

ENV FLASK_APP=app
EXPOSE 5000
CMD ["flask", "run", "--host=0.0.0.0", "--port=5000"]
"@ | Out-File "$backend\Dockerfile" -Encoding utf8 -Force

@"
Flask==3.0.3
Flask-Cors==4.0.1
"@ | Out-File "$backend\requirements.txt" -Encoding utf8 -Force

@"
FLASK_ENV=development
SECRET_KEY=dev-secret
# Not used in skeleton but reserved for later DB work
DATABASE_URL=postgresql+psycopg2://mmcs:mmcs@db:5432/mmcs
CORS_ORIGINS=*
"@ | Out-File "$backend\.env.example" -Encoding utf8 -Force

@"
# Use only what's needed in the image
__pycache__/
*.pyc
*.pyo
*.pyd
.env
.venv/
tests/
"@ | Out-File "$backend\.dockerignore" -Encoding utf8 -Force

@"
from flask import Flask
from flask_cors import CORS
from app.api import api_bp

def create_app():
    app = Flask(__name__)
    # Allow local dev UI to call API
    CORS(app, resources={r"/api/*": {"origins": "*"}})
    app.register_blueprint(api_bp)
    return app

# WSGI entrypoint for flask run / gunicorn
app = create_app()
"@ | Out-File "$backend\app\__init__.py" -Encoding utf8 -Force

@"
from flask import Blueprint, jsonify

api_bp = Blueprint("api", __name__, url_prefix="/api")

@api_bp.get("/health")
def health():
    # Minimal health for connectivity check
    return jsonify({"service": "mmcs", "status": "ok"})
"@ | Out-File "$backend\app\api.py" -Encoding utf8 -Force

@"
import os

class BaseConfig:
    SECRET_KEY = os.getenv("SECRET_KEY", "dev-secret")
    # Extend later with DB config, logging config, etc.

def get_config():
    return BaseConfig()
"@ | Out-File "$backend\app\config.py" -Encoding utf8 -Force

@"
# Placeholder for future SQLAlchemy models
"@ | Out-File "$backend\app\models\__init__.py" -Encoding utf8 -Force

# ----------------
# Frontend
# ----------------
$frontend = "$root\frontend"
Ensure-Dir $frontend
Ensure-Dir "$frontend\src"
Ensure-Dir "$frontend\public"

@"
FROM node:20-slim

WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
EXPOSE 5173
CMD ["npm", "run", "dev", "--", "--host", "0.0.0.0"]
"@ | Out-File "$frontend\Dockerfile" -Encoding utf8 -Force

@"
{
  "name": "mmcs-frontend",
  "version": "0.0.1",
  "private": true,
  "type": "module",
  "scripts": {
    "dev": "vite",
    "build": "vite build",
    "preview": "vite preview --host"
  },
  "dependencies": {
    "react": "^18.2.0",
    "react-dom": "^18.2.0"
  },
  "devDependencies": {
    "@vitejs/plugin-react": "^4.3.0",
    "vite": "^5.4.0"
  }
}
"@ | Out-File "$frontend\package.json" -Encoding utf8 -Force

@"
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

// Note: During local dockerized dev, the UI calls backend via http://localhost:5000
// If you want a dev proxy for /api, uncomment the proxy section.
export default defineConfig({
  plugins: [react()],
  server: {
    host: true,
    port: 5173
    // proxy: {
    //   '/api': {
    //     target: 'http://localhost:5000',
    //     changeOrigin: true
    //   }
    // }
  }
})
"@ | Out-File "$frontend\vite.config.js" -Encoding utf8 -Force

@"
<!doctype html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <title>MMCS</title>
    <meta name="viewport" content="width=device-width, initial-scale=1" />
  </head>
  <body>
    <div id="root"></div>
    <script type="module" src="/src/main.jsx"></script>
  </body>
</html>
"@ | Out-File "$frontend\index.html" -Encoding utf8 -Force

@"
import React from 'react'
import ReactDOM from 'react-dom/client'
import App from './App'

ReactDOM.createRoot(document.getElementById('root')).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>
)
"@ | Out-File "$frontend\src\main.jsx" -Encoding utf8 -Force

@"
import React, { useEffect, useState } from 'react'

function App() {
  const [status, setStatus] = useState('Checking backend...')

  useEffect(() => {
    fetch('http://localhost:5000/api/health')
      .then((r) => r.json())
      .then((d) => setStatus(`Backend says: ${d.status}`))
      .catch(() => setStatus('Backend unreachable'))
  }, [])

  return (
    <div style={{ padding: '2rem', fontFamily: 'Arial, sans-serif' }}>
      <h1>MMCS Frontend</h1>
      <p>{status}</p>
    </div>
  )
}

export default App
"@ | Out-File "$frontend\src\App.jsx" -Encoding utf8 -Force

@"
node_modules/
dist/
.env
"@ | Out-File "$frontend\.gitignore" -Encoding utf8 -Force

@"
*
!Dockerfile
!package.json
!vite.config.js
!index.html
!src/
!public/
"@ | Out-File "$frontend\.dockerignore" -Encoding utf8 -Force

Write-Host "✅ MMCS scaffold complete!"