# EPG Fetcher Scripts - Complete Package

## 📦 Package Contents

This package contains everything needed to fetch EPG (Electronic Program Guide) data from the iptv-org/epg repository and integrate it into other projects.

### Core Scripts (4 files)
1. **epg-fetcher.sh** - Bash script for direct EPG fetching
2. **epg-fetcher-docker.sh** - Bash script using Docker containers
3. **epg_fetcher.py** - Python library with EPGFetcher class
4. **epg-fetcher.js** - Node.js/JavaScript library

### Configuration Files (4 files)
5. **example-channels.xml** - Sample channels configuration
6. **requirements.txt** - Python dependencies
7. **package.json** - Node.js package configuration
8. **nginx.conf** - Nginx configuration for serving EPG files

### Deployment Files (3 files)
9. **docker-compose.yml** - Docker Compose orchestration
10. **Dockerfile.api** - Dockerfile for API server
11. **github-actions-workflow.yml** - GitHub Actions CI/CD example

### API & Service (1 file)
12. **api-server.py** - Flask-based REST API for EPG fetching

### Documentation (2 files)
13. **README.md** - Comprehensive documentation
14. **QUICKSTART.md** - Quick start guide

## 🎯 Use Cases

### 1. Simple One-Time Fetch
```bash
./epg-fetcher.sh --site arirang.com --output guide.xml
```

### 2. Scheduled Daily Updates
```bash
# Add to crontab
0 0 * * * /path/to/epg-fetcher.sh --channels /path/to/channels.xml
```

### 3. Docker Service (Always Running)
```bash
docker-compose up -d
# Access at http://localhost:3000/guide.xml
```

### 4. Python Integration
```python
from epg_fetcher import EPGFetcher
with EPGFetcher() as fetcher:
    fetcher.fetch(site='example.com', output_file='guide.xml')
```

### 5. REST API Service
```bash
python api-server.py
# POST to http://localhost:5000/api/v1/fetch
```

### 6. GitHub Actions Automation
Copy `github-actions-workflow.yml` to `.github/workflows/` in your repo

## 🚀 Quick Start for Different Scenarios

### Scenario A: IPTV Service Provider
You need to fetch EPG for 50+ channels daily and serve it via HTTP:

```bash
# 1. Create channels.xml with your 50 channels
# 2. Deploy with Docker Compose
docker-compose up -d

# EPG auto-updates daily and serves at:
# - http://localhost:3000/guide.xml (from fetcher)
# - http://localhost/guide.xml (from nginx)
```

### Scenario B: Personal IPTV Setup
You want EPG for 5-10 channels updated daily:

```bash
# 1. Setup
chmod +x epg-fetcher.sh

# 2. Create your channels file
nano my-channels.xml

# 3. Add to crontab
crontab -e
# Add: 0 2 * * * /home/user/epg-fetcher.sh --channels /home/user/my-channels.xml --output /media/epg/guide.xml
```

### Scenario C: Software Developer Integration
You're building an IPTV app and need EPG programmatically:

**Python:**
```python
from epg_fetcher import EPGFetcher, EPGChannel

channels = [
    EPGChannel('arirang.com', 'en', 'ArirangTV.kr', 'CH_K', 'Arirang TV'),
    EPGChannel('cnn.com', 'en', 'CNN.us', 'cnn', 'CNN')
]

with EPGFetcher() as fetcher:
    guide_path = fetcher.fetch(channels=channels, days=7)
```

**Node.js:**
```javascript
const { EPGFetcher, EPGChannel } = require('./epg-fetcher.js');

const fetcher = new EPGFetcher();
await fetcher.fetch({
    site: 'arirang.com',
    days: 7,
    maxConnections: 10
});
```

### Scenario D: CI/CD Pipeline
Automatically fetch and publish EPG in your GitHub repository:

1. Copy `github-actions-workflow.yml` to `.github/workflows/fetch-epg.yml`
2. Add your `channels.xml` to the repository
3. Commit and push
4. EPG will auto-update daily and be available as artifacts

### Scenario E: Multi-Source Aggregation
Fetch from multiple sites and combine:

```bash
#!/bin/bash
# fetch-all.sh

sites=("arirang.com" "bloomberg.com" "cnn.com" "bbc.co.uk")

for site in "${sites[@]}"; do
    ./epg-fetcher.sh --site $site --output "guide-$site.xml" --max-connections 5
done

# Combine all guides (requires tv_cat from xmltv-util)
tv_cat guide-*.xml > combined-guide.xml
```

## 📊 Feature Matrix

| Feature | Bash | Docker | Python | Node.js | API |
|---------|------|--------|--------|---------|-----|
| Direct fetching | ✅ | ✅ | ✅ | ✅ | ✅ |
| Docker support | ❌ | ✅ | ✅ | ✅ | ✅ |
| Custom channels | ✅ | ✅ | ✅ | ✅ | ✅ |
| Site fetching | ✅ | ❌ | ✅ | ✅ | ✅ |
| Scheduled updates | Manual | ✅ | Manual | Manual | ✅ |
| HTTP serving | Manual | ✅ | Manual | Manual | ✅ |
| Programmatic | ❌ | ❌ | ✅ | ✅ | ✅ |
| REST API | ❌ | ❌ | ❌ | ❌ | ✅ |

## 🔧 Installation Methods

### Method 1: Clone this package
```bash
git clone https://github.com/yourusername/epg-fetcher-scripts.git
cd epg-fetcher-scripts
```

### Method 2: Download individual scripts
```bash
# Bash script
curl -O https://raw.githubusercontent.com/yourusername/epg-fetcher-scripts/main/epg-fetcher.sh
chmod +x epg-fetcher.sh

# Python library
curl -O https://raw.githubusercontent.com/yourusername/epg-fetcher-scripts/main/epg_fetcher.py

# Node.js library
curl -O https://raw.githubusercontent.com/yourusername/epg-fetcher-scripts/main/epg-fetcher.js
```

### Method 3: Docker only
```bash
# No installation needed
docker pull ghcr.io/iptv-org/epg:master
```

## 🌐 Finding Channels

### Option 1: Browse the official repository
Visit: https://github.com/iptv-org/epg/tree/master/sites

Each site folder contains a `.channels.xml` file with all available channels.

### Option 2: Check supported sites
See: https://github.com/iptv-org/epg/blob/master/SITES.md

### Option 3: Use example channels
The `example-channels.xml` file includes popular international channels.

## 📈 Performance Tuning

### For large channel lists (100+ channels):
```bash
./epg-fetcher.sh \
  --channels channels.xml \
  --max-connections 20 \
  --timeout 60000 \
  --delay 50
```

### For slow/unreliable sources:
```bash
./epg-fetcher.sh \
  --channels channels.xml \
  --max-connections 1 \
  --timeout 120000 \
  --delay 1000
```

### For fast, reliable sources:
```bash
./epg-fetcher.sh \
  --channels channels.xml \
  --max-connections 50 \
  --timeout 10000 \
  --delay 0
```

## 🛡️ Best Practices

1. **Start small**: Test with 1-2 channels before scaling up
2. **Respect rate limits**: Use appropriate delays for the source
3. **Cache results**: EPG data doesn't change every minute
4. **Use compression**: Enable `--gzip` for large guides
5. **Monitor errors**: Check logs for failed fetches
6. **Update regularly**: But not more than 2-4 times per day
7. **Validate output**: Ensure XML is well-formed
8. **Backup configs**: Keep channels.xml in version control

## 🔍 Troubleshooting Guide

### Problem: "Command not found"
**Solution:** Ensure script is executable: `chmod +x epg-fetcher.sh`

### Problem: "Node.js not found"
**Solution:** Install Node.js: 
```bash
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs
```

### Problem: "Docker not found"
**Solution:** Install Docker: `curl -fsSL https://get.docker.com | sh`

### Problem: "No channels fetched"
**Solution:** 
- Verify channels.xml format
- Check site_id values match the source
- Test with a known working channel first

### Problem: "Timeout errors"
**Solution:** Increase timeout and reduce connections:
```bash
./epg-fetcher.sh --timeout 120000 --max-connections 1
```

### Problem: "Permission denied on output"
**Solution:** Check write permissions: `ls -la /path/to/output/`

## 📦 Integration Examples

### With Jellyfin
```bash
# Fetch EPG
./epg-fetcher.sh --channels channels.xml --output /var/lib/jellyfin/epg/guide.xml

# Configure Jellyfin to use: /var/lib/jellyfin/epg/guide.xml
```

### With Plex
```bash
# Fetch EPG
./epg-fetcher.sh --channels channels.xml --output /config/epg/guide.xml

# Add to Plex as XMLTV source
```

### With Kodi
```bash
# Fetch EPG
./epg-fetcher.sh --channels channels.xml --output ~/.kodi/userdata/addon_data/pvr.iptvsimple/guide.xml
```

### With custom IPTV player
```python
import xml.etree.ElementTree as ET
from epg_fetcher import EPGFetcher

# Fetch EPG
with EPGFetcher() as fetcher:
    guide_path = fetcher.fetch(site='example.com')

# Parse and use
tree = ET.parse(guide_path)
# Your player code here
```

## 🎓 Learning Resources

- **XMLTV Format**: http://wiki.xmltv.org/index.php/XMLTVFormat
- **iptv-org/epg**: https://github.com/iptv-org/epg
- **iptv-org/database**: https://github.com/iptv-org/database
- **Cron expressions**: https://crontab.guru/

## 📝 File Descriptions

| File | Purpose | When to Use |
|------|---------|-------------|
| epg-fetcher.sh | Bash script | Quick CLI fetching, cron jobs |
| epg-fetcher-docker.sh | Docker wrapper | Isolated environments |
| epg_fetcher.py | Python library | Python projects, scripting |
| epg-fetcher.js | Node.js library | JavaScript/Node.js projects |
| api-server.py | REST API | Remote fetching, microservices |
| docker-compose.yml | Full stack | Production deployments |
| example-channels.xml | Sample config | Getting started, testing |
| github-actions-workflow.yml | CI/CD | Automated updates |

## 🔐 Security Considerations

1. **API Server**: Use authentication in production
2. **Exposed Ports**: Use firewall rules appropriately
3. **File Permissions**: Restrict write access to output directories
4. **Docker**: Run containers as non-root user when possible
5. **Sensitive Data**: Don't commit API keys or credentials

## 📊 Performance Metrics

Typical fetch times (depends on source and network):

- **Single channel**: 5-30 seconds
- **10 channels (1 connection)**: 1-5 minutes
- **10 channels (10 connections)**: 10-30 seconds
- **100 channels (20 connections)**: 2-5 minutes

## 🆘 Support

- **Issues**: Open an issue in your repository
- **Source issues**: https://github.com/iptv-org/epg/issues
- **Documentation**: See README.md and QUICKSTART.md
- **Examples**: All scripts include usage examples

## 📜 License

These scripts are provided as-is under the Unlicense (public domain).
The iptv-org/epg repository has its own license.

## 🎉 You're Ready!

Choose your method, follow the quickstart, and you'll have EPG data in minutes!

For detailed docs, see [README.md](README.md)
For quick start, see [QUICKSTART.md](QUICKSTART.md)
