# EPG Fetcher Scripts

A complete set of scripts for fetching Electronic Program Guide (EPG) data from the [iptv-org/epg](https://github.com/iptv-org/epg) repository. These scripts can be integrated into other repositories to easily fetch EPG data for specific channels.

## 📦 Available Scripts

1. **epg-fetcher.sh** - Bash script for direct fetching
2. **epg-fetcher-docker.sh** - Bash script using Docker
3. **epg_fetcher.py** - Python library
4. **epg-fetcher.js** - Node.js library
5. **example-channels.xml** - Example channels configuration

## 🚀 Quick Start

### Option 1: Using Bash Script

```bash
# Make script executable
chmod +x epg-fetcher.sh

# Fetch from a specific site
./epg-fetcher.sh --site example.com --output myguide.xml

# Fetch with custom channels file
./epg-fetcher.sh --channels example-channels.xml --days 3 --max-connections 5
```

### Option 2: Using Docker Script

```bash
# Make script executable
chmod +x epg-fetcher-docker.sh

# Single fetch
./epg-fetcher-docker.sh --channels example-channels.xml --output guide.xml

# Run as daemon with custom schedule
./epg-fetcher-docker.sh --channels example-channels.xml --daemon --schedule "0 */12 * * *"
```

### Option 3: Using Python Library

```python
from epg_fetcher import EPGFetcher, EPGChannel

# Fetch from specific site
with EPGFetcher() as fetcher:
    output = fetcher.fetch(
        site='example.com',
        output_file='guide.xml',
        days=3,
        max_connections=5
    )
    print(f"Guide saved to: {output}")

# Fetch with custom channels
channels = [
    EPGChannel(
        site='arirang.com',
        lang='en',
        xmltv_id='ArirangTV.kr',
        site_id='CH_K',
        name='Arirang TV'
    )
]

with EPGFetcher() as fetcher:
    output = fetcher.fetch(
        channels=channels,
        output_file='custom_guide.xml',
        days=7
    )
```

### Option 4: Using Node.js Library

```javascript
const { EPGFetcher, EPGChannel } = require('./epg-fetcher.js');

(async () => {
    // Fetch from specific site
    const fetcher = new EPGFetcher();
    try {
        const output = await fetcher.fetch({
            site: 'example.com',
            output: 'guide.xml',
            days: 3,
            maxConnections: 5
        });
        console.log(`Guide saved to: ${output}`);
    } finally {
        fetcher.cleanup();
    }
})();
```

## 📋 Prerequisites

### For Bash Scripts
- Git
- Node.js and npm (for direct fetching)
- Docker (for Docker-based fetching)

### For Python Library
- Python 3.6+
- Git
- Node.js and npm (for direct fetching)
- Docker (for Docker-based fetching)

### For Node.js Library
- Node.js 12+
- npm
- Git
- Docker (for Docker-based fetching)

## 🔧 Configuration Options

### Common Options

| Option | Description | Default |
|--------|-------------|---------|
| `--site` / `site` | Site to fetch from (e.g., example.com) | - |
| `--channels` / `channels` | Path to channels.xml or list of channels | - |
| `--output` / `output` | Output file path | guide.xml |
| `--days` / `days` | Number of days to fetch | Site default |
| `--lang` / `lang` | Language codes (comma-separated) | - |
| `--max-connections` / `maxConnections` | Max concurrent connections | 1 |
| `--timeout` / `timeout` | Request timeout in milliseconds | 30000 |
| `--delay` / `delay` | Delay between requests in milliseconds | 0 |
| `--gzip` / `gzip` | Create compressed version | false |

## 📝 Creating a Channels File

Create an XML file with your desired channels:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<channels>
  <channel site="example.com" lang="en" xmltv_id="Channel.id" site_id="123">Channel Name</channel>
  <channel site="arirang.com" lang="en" xmltv_id="ArirangTV.kr" site_id="CH_K">Arirang TV</channel>
</channels>
```

### Finding Channel Information

1. Browse available sites at [SITES.md](https://github.com/iptv-org/epg/blob/master/SITES.md)
2. Check site-specific channels in the [sites](https://github.com/iptv-org/epg/tree/master/sites) directory
3. Each site folder contains a `*.channels.xml` file with available channels

## 🐳 Docker Usage

### Pull the Image

```bash
docker pull ghcr.io/iptv-org/epg:master
```

### Run Container

```bash
docker run -p 3000:3000 \
  -v /path/to/channels.xml:/epg/channels.xml \
  -e MAX_CONNECTIONS=10 \
  -e DAYS=7 \
  ghcr.io/iptv-org/epg:master
```

The guide will be available at `http://localhost:3000/guide.xml`

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `CRON_SCHEDULE` | Cron expression for scheduling | 0 0 * * * |
| `MAX_CONNECTIONS` | Concurrent request limit | 1 |
| `GZIP` | Create compressed version | false |
| `CURL` | Display requests as CURL | false |
| `PROXY` | Proxy server to use | - |
| `DAYS` | Number of days to fetch | Site default |
| `TIMEOUT` | Request timeout in ms | 30000 |
| `DELAY` | Delay between requests in ms | 0 |
| `RUN_AT_STARTUP` | Run on container startup | true |

## 🔌 Integration Examples

### GitHub Actions

```yaml
name: Fetch EPG

on:
  schedule:
    - cron: '0 0 * * *'  # Daily at midnight
  workflow_dispatch:

jobs:
  fetch-epg:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Fetch EPG data
        run: |
          chmod +x epg-fetcher.sh
          ./epg-fetcher.sh --channels channels.xml --output guide.xml
      
      - name: Upload guide
        uses: actions/upload-artifact@v3
        with:
          name: epg-guide
          path: guide.xml
```

### Cron Job

```bash
# Add to crontab
0 0 * * * /path/to/epg-fetcher.sh --channels /path/to/channels.xml --output /path/to/guide.xml
```

### Python Script

```python
#!/usr/bin/env python3
import schedule
import time
from epg_fetcher import EPGFetcher

def fetch_epg():
    with EPGFetcher() as fetcher:
        fetcher.fetch(
            site='example.com',
            output_file='/var/www/html/guide.xml',
            days=3
        )
    print("EPG updated successfully")

# Run daily at midnight
schedule.every().day.at("00:00").do(fetch_epg)

while True:
    schedule.run_pending()
    time.sleep(60)
```

### Node.js Server

```javascript
const express = require('express');
const { EPGFetcher } = require('./epg-fetcher.js');
const cron = require('node-cron');

const app = express();
let currentGuide = null;

// Fetch EPG on startup
(async () => {
    const fetcher = new EPGFetcher();
    currentGuide = await fetcher.fetch({
        site: 'example.com',
        output: 'guide.xml'
    });
})();

// Update EPG daily at midnight
cron.schedule('0 0 * * *', async () => {
    const fetcher = new EPGFetcher();
    currentGuide = await fetcher.fetch({
        site: 'example.com',
        output: 'guide.xml'
    });
    console.log('EPG updated');
});

// Serve guide
app.get('/guide.xml', (req, res) => {
    res.sendFile(currentGuide);
});

app.listen(3000, () => {
    console.log('Server running on port 3000');
});
```

## 🎯 Use Cases

### 1. IPTV Service Provider
Automatically fetch and update EPG data for your channel lineup:

```bash
./epg-fetcher-docker.sh \
  --channels my-channels.xml \
  --daemon \
  --schedule "0 */6 * * *" \
  --max-connections 20 \
  --days 7
```

### 2. Personal IPTV Setup
Fetch EPG for your personal channel list:

```python
channels = [
    EPGChannel('bbc.co.uk', 'en', 'BBCOne.uk', 'bbc-one', 'BBC One'),
    EPGChannel('cnn.com', 'en', 'CNN.us', 'cnn', 'CNN')
]

with EPGFetcher() as fetcher:
    fetcher.fetch(channels=channels, output_file='/media/epg/guide.xml')
```

### 3. EPG Aggregation Service
Fetch from multiple sites and merge:

```bash
# Fetch from multiple sites
./epg-fetcher.sh --site site1.com --output guide1.xml
./epg-fetcher.sh --site site2.com --output guide2.xml

# Merge guides (requires xmltv tools)
tv_cat guide1.xml guide2.xml > merged-guide.xml
```

### 4. Research/Analytics
Collect EPG data for analysis:

```python
from epg_fetcher import EPGFetcher
import xml.etree.ElementTree as ET

with EPGFetcher() as fetcher:
    guide_path = fetcher.fetch(site='example.com', days=30)
    
    # Parse and analyze
    tree = ET.parse(guide_path)
    root = tree.getroot()
    
    # Your analysis code here
```

## 🛠 Troubleshooting

### Issue: "Repository clone failed"
**Solution:** Check your internet connection and ensure Git is installed.

### Issue: "npm install failed"
**Solution:** Ensure Node.js and npm are properly installed. Try clearing npm cache: `npm cache clean --force`

### Issue: "Docker image pull failed"
**Solution:** Ensure Docker is running and you have internet access. Try: `docker login ghcr.io`

### Issue: "No channels fetched"
**Solution:** Verify your channels.xml file is correctly formatted and the site IDs are valid.

### Issue: "Timeout errors"
**Solution:** Increase the timeout value or reduce max connections:
```bash
./epg-fetcher.sh --site example.com --timeout 60000 --max-connections 1
```

## 📚 Additional Resources

- [iptv-org/epg GitHub Repository](https://github.com/iptv-org/epg)
- [Supported Sites List](https://github.com/iptv-org/epg/blob/master/SITES.md)
- [XMLTV Format Documentation](http://wiki.xmltv.org/index.php/XMLTVFormat)
- [iptv-org/database](https://github.com/iptv-org/database) - Channel database

## 🤝 Contributing

Contributions are welcome! If you find a bug or have a feature request, please open an issue.

## 📄 License

These scripts are provided as-is under the Unlicense. The iptv-org/epg repository has its own license.

## ⚠️ Important Notes

1. **Rate Limiting**: Be respectful of source websites. Use appropriate delays and connection limits.
2. **Legal Compliance**: Ensure you have the right to use EPG data from the sources you're fetching.
3. **Resource Usage**: Fetching large numbers of channels can be resource-intensive.
4. **Updates**: The iptv-org/epg repository is regularly updated. Your scripts will always use the latest version.

## 📞 Support

For issues with:
- These scripts: Open an issue in your repository
- The iptv-org/epg tool: Visit [iptv-org/epg issues](https://github.com/iptv-org/epg/issues)
- Specific sites: Check the [SITES.md](https://github.com/iptv-org/epg/blob/master/SITES.md) file
