Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Always run from this script directory
Set-Location $PSScriptRoot

# Create venv if missing
if (!(Test-Path ".\.venv")) {
  Write-Host "Creating venv..." -ForegroundColor Cyan
  python -m venv .venv
}

Write-Host "Activating venv..." -ForegroundColor Cyan
.\.venv\Scripts\Activate.ps1

Write-Host "Installing dependencies..." -ForegroundColor Cyan
python -m pip install -U pip
pip install -r requirements.txt

Write-Host "Starting backend: http://127.0.0.1:8000" -ForegroundColor Green
uvicorn app.main:app --reload --port 8000
