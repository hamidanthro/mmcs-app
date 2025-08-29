cd C:\Users\hamid\OneDrive\Desktop\MyWebApps\MMCS

@'
import os
import sys

# Ensure the backend folder is on sys.path when running tests locally or in CI
BACKEND_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
if BACKEND_ROOT not in sys.path:
    sys.path.insert(0, BACKEND_ROOT)
'@ | Set-Content -Encoding UTF8 "backend\tests\conftest.py"

# quick sanity check
Get-Content "backend\tests\conftest.py"