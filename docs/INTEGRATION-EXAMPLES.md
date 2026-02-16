# Integration Examples for Consuming Repositories

This document shows how other repositories can integrate EPG Fetcher.

---

## Example 1: Simple GitHub Actions Integration

**File: `.github/workflows/update-epg.yml`** (in YOUR repository)

```yaml
name: Update EPG Daily

on:
  schedule:
    - cron: '0 2 * * *'  # 2 AM daily
  workflow_dispatch:      # Allow manual trigger

jobs:
  fetch-epg:
    runs-on: ubuntu-latest
    
    steps:
      - name: Checkout repository
        uses: actions/checkout@v3
      
      - name: Fetch EPG data
        run: |
          # Download and execute the EPG fetcher script
          curl -sSL https://raw.githubusercontent.com/YOUR-USERNAME/epg-fetcher/main/scripts/request-epg.sh | \
            bash -s -- \
              --channels-url https://raw.githubusercontent.com/YOUR-USERNAME/YOUR-REPO/main/config/channels.xml \
              --output data/guide.xml \
              --days 7 \
              --max-connections 10
      
      - name: Commit and push if changed
        run: |
          git config --local user.email "github-actions[bot]@users.noreply.github.com"
          git config --local user.name "github-actions[bot]"
          git add data/guide.xml
          git diff --staged --quiet || git commit -m "Update EPG data - $(date +'%Y-%m-%d %H:%M')"
          git push

      - name: Upload as artifact
        uses: actions/upload-artifact@v3
        with:
          name: epg-guide
          path: data/guide.xml
          retention-days: 7
```

---

## Example 2: Makefile Integration

**File: `Makefile`** (in YOUR repository)

```makefile
.PHONY: help fetch-epg fetch-epg-dev serve-epg clean

help:
	@echo "EPG Management Commands:"
	@echo "  make fetch-epg      - Fetch production EPG (7 days)"
	@echo "  make fetch-epg-dev  - Fetch development EPG (3 days)"
	@echo "  make serve-epg      - Serve EPG locally"
	@echo "  make clean          - Clean EPG files"

# Fetch EPG for production
fetch-epg:
	@echo "Fetching production EPG..."
	curl -sSL https://raw.githubusercontent.com/YOUR-USERNAME/epg-fetcher/main/scripts/request-epg.sh | \
		bash -s -- \
			--channels-file config/channels.xml \
			--output data/epg/guide.xml \
			--days 7 \
			--max-connections 10
	@echo "EPG fetched successfully!"

# Fetch EPG for development
fetch-epg-dev:
	@echo "Fetching development EPG..."
	curl -sSL https://raw.githubusercontent.com/YOUR-USERNAME/epg-fetcher/main/scripts/request-epg.sh | \
		bash -s -- \
			--site arirang.com \
			--output data/epg/guide-dev.xml \
			--days 3 \
			--max-connections 5

# Serve EPG locally for testing
serve-epg:
	@echo "Starting local server..."
	@echo "EPG available at: http://localhost:8000/guide.xml"
	cd data/epg && python3 -m http.server 8000

# Clean generated files
clean:
	rm -f data/epg/*.xml
	@echo "Cleaned EPG files"
```

**Usage in your repo:**
```bash
make fetch-epg        # Fetch EPG
make serve-epg        # Test locally
```

---

## Example 3: Docker Compose Integration

**File: `docker-compose.yml`** (in YOUR repository)

```yaml
version: '3.8'

services:
  # Your main application
  iptv-app:
    build: .
    ports:
      - "8080:8080"
    volumes:
      - ./data/epg:/app/epg:ro
    depends_on:
      - epg-fetcher

  # EPG Fetcher service
  epg-fetcher:
    image: ghcr.io/iptv-org/epg:master
    container_name: epg-fetcher
    volumes:
      - ./config/channels.xml:/epg/channels.xml:ro
      - ./data/epg:/epg/public
    environment:
      CRON_SCHEDULE: "0 */6 * * *"  # Every 6 hours
      MAX_CONNECTIONS: 10
      DAYS: 7
      GZIP: "true"
      RUN_AT_STARTUP: "true"
    restart: unless-stopped

  # Optional: Serve EPG via HTTP
  epg-server:
    image: nginx:alpine
    ports:
      - "3000:80"
    volumes:
      - ./data/epg:/usr/share/nginx/html:ro
    restart: unless-stopped
```

**Usage:**
```bash
docker-compose up -d           # Start all services
docker-compose logs epg-fetcher  # View logs
docker-compose restart epg-fetcher  # Force EPG update
```

---

## Example 4: Python Script Integration

**File: `scripts/update_epg.py`** (in YOUR repository)

```python
#!/usr/bin/env python3
"""
EPG Update Script for Your Application
"""

import subprocess
import os
from datetime import datetime

def fetch_epg(channels_file='config/channels.xml', output_file='data/epg/guide.xml'):
    """Fetch EPG data using the epg-fetcher tool"""
    
    print(f"[{datetime.now()}] Starting EPG fetch...")
    
    # Ensure output directory exists
    os.makedirs(os.path.dirname(output_file), exist_ok=True)
    
    # Download and execute the fetcher script
    cmd = [
        'bash', '-c',
        f'curl -sSL https://raw.githubusercontent.com/YOUR-USERNAME/epg-fetcher/main/scripts/request-epg.sh | '
        f'bash -s -- '
        f'--channels-file {channels_file} '
        f'--output {output_file} '
        f'--days 7 '
        f'--max-connections 10'
    ]
    
    try:
        result = subprocess.run(cmd, check=True, capture_output=True, text=True)
        print(result.stdout)
        print(f"[{datetime.now()}] EPG fetch completed successfully!")
        return True
    except subprocess.CalledProcessError as e:
        print(f"[{datetime.now()}] EPG fetch failed!")
        print(e.stderr)
        return False

def validate_epg(epg_file='data/epg/guide.xml'):
    """Validate that EPG file exists and is not empty"""
    if not os.path.exists(epg_file):
        print(f"EPG file not found: {epg_file}")
        return False
    
    size = os.path.getsize(epg_file)
    if size == 0:
        print(f"EPG file is empty: {epg_file}")
        return False
    
    print(f"EPG file validated: {epg_file} ({size} bytes)")
    return True

if __name__ == '__main__':
    success = fetch_epg()
    
    if success and validate_epg():
        print("✓ EPG update completed successfully")
        exit(0)
    else:
        print("✗ EPG update failed")
        exit(1)
```

**Usage:**
```bash
python scripts/update_epg.py
```

---

## Example 5: Shell Script Integration

**File: `scripts/fetch-epg.sh`** (in YOUR repository)

```bash
#!/bin/bash
#
# EPG Fetch Wrapper for Your Application
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

CHANNELS_FILE="${PROJECT_ROOT}/config/channels.xml"
OUTPUT_FILE="${PROJECT_ROOT}/data/epg/guide.xml"
DAYS="${EPG_DAYS:-7}"
MAX_CONNECTIONS="${EPG_MAX_CONNECTIONS:-10}"

echo "=== EPG Fetch ==="
echo "Channels: $CHANNELS_FILE"
echo "Output:   $OUTPUT_FILE"
echo "Days:     $DAYS"
echo "================="

# Ensure output directory exists
mkdir -p "$(dirname "$OUTPUT_FILE")"

# Fetch EPG using the remote script
curl -sSL https://raw.githubusercontent.com/YOUR-USERNAME/epg-fetcher/main/scripts/request-epg.sh | \
    bash -s -- \
        --channels-file "$CHANNELS_FILE" \
        --output "$OUTPUT_FILE" \
        --days "$DAYS" \
        --max-connections "$MAX_CONNECTIONS"

echo "✓ EPG fetched successfully!"
```

**Usage:**
```bash
chmod +x scripts/fetch-epg.sh
./scripts/fetch-epg.sh

# Or with custom settings
EPG_DAYS=14 EPG_MAX_CONNECTIONS=20 ./scripts/fetch-epg.sh
```

---

## Example 6: Cron Job Setup

**File: `scripts/setup-cron.sh`** (in YOUR repository)

```bash
#!/bin/bash
#
# Setup cron job for automatic EPG updates
#

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FETCH_SCRIPT="${SCRIPT_DIR}/fetch-epg.sh"

# Make script executable
chmod +x "$FETCH_SCRIPT"

# Create cron job (runs daily at 2 AM)
CRON_JOB="0 2 * * * $FETCH_SCRIPT >> /tmp/epg-fetch.log 2>&1"

# Add to crontab
(crontab -l 2>/dev/null | grep -v "$FETCH_SCRIPT"; echo "$CRON_JOB") | crontab -

echo "✓ Cron job installed"
echo "  Schedule: Daily at 2 AM"
echo "  Script:   $FETCH_SCRIPT"
echo "  Logs:     /tmp/epg-fetch.log"
echo ""
echo "To view cron jobs: crontab -l"
echo "To remove: crontab -e"
```

**Usage:**
```bash
./scripts/setup-cron.sh
```

---

## Example 7: Git Submodule Integration

**Setup in YOUR repository:**

```bash
# Add epg-fetcher as submodule
git submodule add https://github.com/YOUR-USERNAME/epg-fetcher.git tools/epg-fetcher

# Initialize submodule
git submodule update --init --recursive

# Create wrapper script
cat > scripts/fetch-epg.sh << 'EOF'
#!/bin/bash
./tools/epg-fetcher/scripts/request-epg.sh \
    --channels-file config/channels.xml \
    --output data/epg/guide.xml \
    --days 7
EOF

chmod +x scripts/fetch-epg.sh

# Commit
git add .gitmodules tools/epg-fetcher scripts/fetch-epg.sh
git commit -m "Add EPG fetcher as submodule"
```

**Update submodule:**
```bash
git submodule update --remote tools/epg-fetcher
```

---

## Example 8: Node.js Application Integration

**File: `scripts/updateEpg.js`** (in YOUR repository)

```javascript
#!/usr/bin/env node

const { exec } = require('child_process');
const fs = require('fs');
const path = require('path');

const CONFIG = {
    channelsFile: path.join(__dirname, '../config/channels.xml'),
    outputFile: path.join(__dirname, '../data/epg/guide.xml'),
    days: 7,
    maxConnections: 10
};

function fetchEpg() {
    return new Promise((resolve, reject) => {
        console.log('Fetching EPG data...');
        
        // Ensure output directory exists
        fs.mkdirSync(path.dirname(CONFIG.outputFile), { recursive: true });
        
        const cmd = `curl -sSL https://raw.githubusercontent.com/YOUR-USERNAME/epg-fetcher/main/scripts/request-epg.sh | \
            bash -s -- \
            --channels-file ${CONFIG.channelsFile} \
            --output ${CONFIG.outputFile} \
            --days ${CONFIG.days} \
            --max-connections ${CONFIG.maxConnections}`;
        
        exec(cmd, (error, stdout, stderr) => {
            if (error) {
                console.error('EPG fetch failed:', stderr);
                reject(error);
                return;
            }
            
            console.log(stdout);
            console.log('✓ EPG fetched successfully!');
            resolve();
        });
    });
}

// Run
fetchEpg()
    .then(() => process.exit(0))
    .catch(() => process.exit(1));
```

**Usage:**
```bash
node scripts/updateEpg.js
```

**Add to package.json:**
```json
{
  "scripts": {
    "fetch-epg": "node scripts/updateEpg.js"
  }
}
```

Then run: `npm run fetch-epg`

---

## Summary

All these examples can be added to OTHER repositories to integrate EPG fetching. The key points:

1. **No code duplication** - Just call the remote script
2. **Always up-to-date** - Gets latest version from your repo
3. **Flexible** - Choose the integration method that fits your workflow
4. **Automated** - Set up cron/GitHub Actions for automatic updates

Each example is production-ready and can be copied directly into other repositories!
