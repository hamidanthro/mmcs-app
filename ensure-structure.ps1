# ensure-structure.ps1
# Run from the MMCS folder. Creates any missing dirs/files for the current baseline (non-destructive).

$ErrorActionPreference = "Stop"
$root = (Get-Location).Path

function Ensure-Dir($p) {
  if (-not (Test-Path $p -PathType Container)) {
    New-Item -ItemType Directory -Force -Path $p | Out-Null
    Write-Host "Created  " -ForegroundColor Green -NoNewline; Write-Host $p
  } else {
    Write-Host "Exists   " -ForegroundColor DarkGray -NoNewline; Write-Host $p
  }
}

function Ensure-File($path, $content) {
  if (-not (Test-Path $path -PathType Leaf)) {
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [IO.File]::WriteAllText($path, $content, $utf8NoBom)
    Write-Host "Created  " -ForegroundColor Green -NoNewline; Write-Host $path
  } else {
    Write-Host "Exists   " -ForegroundColor DarkGray -NoNewline; Write-Host $path
  }
}

# --- Expected folder structure ---
Ensure-Dir "backend"
Ensure-Dir "backend\app"
Ensure-Dir "backend\app\models"
Ensure-Dir "frontend"
Ensure-Dir "frontend\src"
Ensure-Dir "frontend\public"

# --- Backend essential files ---
Ensure-File "backend\requirements.txt" @"
Flask==3.0.3
Flask-Cors==4.0.1
Flask-SQLAlchemy==3.1.1
psycopg2-binary==2.9.9
"@

Ensure-File "backend\app\extensions.py" @"
from flask_sqlalchemy import SQLAlchemy

# Global SQLAlchemy handle (initialized in app factory)
db = SQLAlchemy()
"@

Ensure-File "backend\app\models\__init__.py" @"
from .tenant import Tenant
from .dimension import Dimension
"@

Ensure-File "backend\app\models\tenant.py" @"
import uuid
from app.extensions import db

class Tenant(db.Model):
    __tablename__ = "tenant"
    id = db.Column(db.Uuid, primary_key=True, default=uuid.uuid4)
    code = db.Column(db.String(64), unique=True, nullable=False, index=True)
    name = db.Column(db.String(255), nullable=False)
"@

Ensure-File "backend\app\models\dimension.py" @"
import uuid
from app.extensions import db

class Dimension(db.Model):
    __tablename__ = "dimension"
    id = db.Column(db.Uuid, primary_key=True, default=uuid.uuid4)
    tenant_id = db.Column(db.Uuid, nullable=False, index=True)
    code = db.Column(db.String(64), nullable=False)
    name = db.Column(db.String(255), nullable=False)
    description = db.Column(db.Text, nullable=True)

    __table_args__ = (
        db.UniqueConstraint("tenant_id", "code", name="uq_dimension_tenant_code"),
    )
"@

# --- Frontend essential files ---
Ensure-File "frontend\package.json" @"
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
"@

Ensure-File "frontend\postcss.config.cjs" @"
module.exports = {};
"@

Ensure-File "frontend\src\main.jsx" @"
import React from 'react'
import ReactDOM from 'react-dom/client'
import App from './App'

const rootEl = document.getElementById('root')
if (rootEl) {
  ReactDOM.createRoot(rootEl).render(
    <React.StrictMode>
      <App />
    </React.StrictMode>
  )
} else {
  console.error('Root element not found')
}
"@

Ensure-File "frontend\src\App.jsx" @"
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
    <main style={{ padding: '2rem', fontFamily: 'Arial, sans-serif' }}>
      <h1>MMCS Frontend</h1>
      <p id='status-line'>{status}</p>
    </main>
  )
}

export default App
"@

Write-Host "`nDone. Missing files/folders are now in place." -ForegroundColor Cyan
