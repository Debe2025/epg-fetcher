# EPG Fetcher - Repository Structure Recommendation

## Recommended GitHub Repository Setup

### Repository Name
`epg-fetcher` or `iptv-epg-tools`

### Repository Structure

```
epg-fetcher/
├── README.md                      # Main documentation
├── QUICKSTART.md                  # Quick start guide
├── SUMMARY.md                     # Package overview
├── LICENSE                        # License file (Unlicense recommended)
├── .gitignore                     # Git ignore file
│
├── scripts/                       # Core fetcher scripts
│   ├── epg-fetcher.sh            # Bash script
│   ├── epg-fetcher-docker.sh     # Docker bash script
│   ├── epg_fetcher.py            # Python library
│   ├── epg-fetcher.js            # Node.js library
│   └── request-epg.sh            # Simple request handler (main entry point)
│
├── api/                           # API server
│   ├── api-server.py             # Flask API server
│   ├── requirements.txt          # Python dependencies
│   └── Dockerfile                # API container (rename from Dockerfile.api)
│
├── config/                        # Configuration files
│   ├── example-channels.xml      # Sample channels
│   └── channels/                 # Pre-configured channel lists
│       ├── news.xml              # News channels
│       ├── sports.xml            # Sports channels
│       ├── entertainment.xml     # Entertainment channels
│       └── international.xml     # International channels
│
├── deployment/                    # Deployment configurations
│   ├── docker-compose.yml        # Docker Compose setup
│   ├── nginx.conf                # Nginx configuration
│   └── kubernetes/               # K8s manifests (optional)
│       ├── deployment.yaml
│       └── service.yaml
│
├── .github/                       # GitHub specific files
│   └── workflows/                # GitHub Actions
│       ├── fetch-epg.yml         # Main EPG fetch workflow
│       ├── docker-build.yml      # Build Docker images
│       └── test.yml              # Run tests
│
├── examples/                      # Usage examples
│   ├── basic-fetch.sh            # Basic bash example
│   ├── python-integration.py     # Python example
│   ├── nodejs-server.js          # Node.js server example
│   ├── makefile-integration      # Makefile example
│   └── github-action-usage.yml   # How to use in other repos
│
├── docs/                          # Additional documentation
│   ├── API.md                    # API documentation
│   ├── INTEGRATION.md            # Integration guide
│   ├── TROUBLESHOOTING.md        # Common issues
│   └── CHANNELS.md               # Finding channels guide
│
├── tests/                         # Test files (optional)
│   ├── test_fetcher.py
│   └── test_api.py
│
└── package.json                   # Node.js package config
```

---

## How Other Repositories Should Use This

### Method 1: Direct Script Download (Recommended for Simple Use)

In the consuming repository:

```yaml
# .github/workflows/update-epg.yml
name: Update EPG

on:
  schedule:
    - cron: '0 0 * * *'
  workflow_dispatch:

jobs:
  fetch-epg:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Fetch EPG
        run: |
          curl -sSL https://raw.githubusercontent.com/user/epg-fetcher/main/scripts/request-epg.sh | \
            bash -s -- \
              --channels-url https://example.com/my-channels.xml \
              --output data/guide.xml \
              --days 7
      
      - name: Commit updated EPG
        run: |
          git config user.name "GitHub Actions"
          git config user.email "actions@github.com"
          git add data/guide.xml
          git commit -m "Update EPG $(date +'%Y-%m-%d')" || exit 0
          git push
```

### Method 2: Git Submodule (Recommended for Complex Integration)

In the consuming repository:

```bash
# Add as submodule
git submodule add https://github.com/user/epg-fetcher.git tools/epg

# Create a Makefile
cat > Makefile << 'EOF'
.PHONY: fetch-epg
fetch-epg:
	./tools/epg/scripts/request-epg.sh \
		--channels-file config/channels.xml \
		--output data/guide.xml \
		--days 7

.PHONY: fetch-epg-docker
fetch-epg-docker:
	cd tools/epg && docker-compose up -d
EOF

# Use it
make fetch-epg
```

### Method 3: Package Installation (For Python Projects)

```bash
# Install as package
pip install git+https://github.com/user/epg-fetcher.git

# Use in code
from epg_fetcher import EPGFetcher
```

### Method 4: NPM Package (For Node.js Projects)

```bash
# Install as npm package
npm install git+https://github.com/user/epg-fetcher.git

# Use in code
const { EPGFetcher } = require('epg-fetcher');
```

---

## Recommended .gitignore

```gitignore
# EPG outputs
*.xml
!example-channels.xml
!config/**/*.xml
*.xml.gz

# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
venv/
env/
.venv

# Node.js
node_modules/
npm-debug.log*
yarn-debug.log*
yarn-error.log*
package-lock.json

# Temp files
*.tmp
*.temp
.DS_Store
Thumbs.db

# EPG work directories
epg-work/
epg_cache/
output/
public/

# Docker
.dockerignore

# IDE
.vscode/
.idea/
*.swp
*.swo
*~
```

---

## Recommended README.md Structure

```markdown
# EPG Fetcher

> Fetch EPG (Electronic Program Guide) data for IPTV applications

[![License](badge)](link)
[![Tests](badge)](link)

## Quick Start

```bash
# Remote execution
curl -sSL https://raw.githubusercontent.com/user/epg-fetcher/main/scripts/request-epg.sh | \
  bash -s -- --site arirang.com --output guide.xml
```

## Installation

### As Git Submodule
```bash
git submodule add https://github.com/user/epg-fetcher.git
```

### As Python Package
```bash
pip install git+https://github.com/user/epg-fetcher.git
```

### As NPM Package
```bash
npm install git+https://github.com/user/epg-fetcher.git
```

## Usage

[Link to QUICKSTART.md]

## Integration Examples

[Link to examples/]

## Documentation

- [Quick Start](QUICKSTART.md)
- [API Reference](docs/API.md)
- [Integration Guide](docs/INTEGRATION.md)
- [Troubleshooting](docs/TROUBLESHOOTING.md)

## Contributing

## License
```

---

## Publishing to GitHub

### Step 1: Create Repository

```bash
# Initialize
git init
git branch -M main

# Add all files
git add .
git commit -m "Initial commit: EPG Fetcher tools"

# Create on GitHub, then:
git remote add origin https://github.com/yourusername/epg-fetcher.git
git push -u origin main
```

### Step 2: Create Releases

```bash
# Tag a release
git tag -a v1.0.0 -m "Initial release"
git push origin v1.0.0
```

### Step 3: Enable GitHub Pages (Optional)

- Go to Settings → Pages
- Enable for docs/ or use README

### Step 4: Add Topics/Tags

Add these topics to your GitHub repo:
- `epg`
- `iptv`
- `tv-guide`
- `xmltv`
- `electronic-program-guide`
- `docker`
- `python`
- `nodejs`
- `bash`

---

## Integration Documentation for Other Repos

Create `docs/INTEGRATION.md`:

```markdown
# Integration Guide

## For IPTV Applications

### Add to Your Project

**Option A: Direct Script Download**
```yaml
# .github/workflows/fetch-epg.yml
- name: Fetch EPG
  run: |
    curl -sSL https://raw.githubusercontent.com/user/epg-fetcher/main/scripts/request-epg.sh | \
      bash -s -- --site example.com
```

**Option B: Git Submodule**
```bash
git submodule add https://github.com/user/epg-fetcher.git tools/epg
./tools/epg/scripts/request-epg.sh --site example.com
```

**Option C: Docker**
```yaml
services:
  epg-fetcher:
    image: ghcr.io/iptv-org/epg:master
    volumes:
      - ./channels.xml:/epg/channels.xml
      - ./output:/epg/public
```

### Configuration

Create `channels.xml` in your repo:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<channels>
  <channel site="example.com" lang="en" xmltv_id="ID" site_id="123">Channel</channel>
</channels>
```

### Automation

Add to your CI/CD:
```yaml
schedule:
  - cron: '0 0 * * *'  # Daily at midnight
```

### Examples

See [examples/](../examples/) directory for:
- GitHub Actions integration
- Makefile integration
- Docker Compose setup
- Python/Node.js usage
```

---

## Summary

### Yes, Commit Everything to One Repository

**Recommended Structure:**
1. **Main Entry Point**: `scripts/request-epg.sh` - Simple interface for other repos
2. **Core Tools**: All fetcher scripts in `scripts/`
3. **API Server**: In `api/` directory
4. **Examples**: How to use from other repos in `examples/`
5. **Deployment**: Docker/K8s configs in `deployment/`

### How Others Use It:

```bash
# From any other repository:
curl -sSL https://raw.githubusercontent.com/YOU/epg-fetcher/main/scripts/request-epg.sh | \
  bash -s -- --site arirang.com --output guide.xml
```

This way, other repositories don't need to copy all your code - they just call your script!

---

## Next Steps

1. ✅ Reorganize files into the structure above
2. ✅ Create comprehensive README.md
3. ✅ Add examples/ directory with integration examples
4. ✅ Push to GitHub
5. ✅ Create initial release (v1.0.0)
6. ✅ Add usage examples to README
7. ✅ Test integration from a different repository
