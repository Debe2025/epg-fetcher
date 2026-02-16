# Quick Start Guide

Get up and running with EPG Fetcher in under 5 minutes!

## 🚀 Method 1: Bash Script (Easiest)

### Step 1: Download the script
```bash
curl -O https://raw.githubusercontent.com/yourusername/epg-fetcher/main/epg-fetcher.sh
chmod +x epg-fetcher.sh
```

### Step 2: Create a channels file
```bash
cat > my-channels.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<channels>
  <channel site="arirang.com" lang="en" xmltv_id="ArirangTV.kr" site_id="CH_K">Arirang TV</channel>
  <channel site="bloomberg.com" lang="en" xmltv_id="BloombergTVEurope.uk" site_id="europe">Bloomberg TV Europe</channel>
</channels>
EOF
```

### Step 3: Fetch EPG
```bash
./epg-fetcher.sh --channels my-channels.xml --output guide.xml
```

✅ Done! Your EPG is in `guide.xml`

---

## 🐳 Method 2: Docker (No Install Required)

### One-liner to fetch EPG:
```bash
docker run --rm \
  -v $PWD/my-channels.xml:/epg/channels.xml:ro \
  -v $PWD:/epg/output \
  -e MAX_CONNECTIONS=10 \
  -e DAYS=3 \
  ghcr.io/iptv-org/epg:master
```

✅ Your guide will be at `./guide.xml`

---

## 🐍 Method 3: Python

### Step 1: Install
```bash
pip install git+https://github.com/yourusername/epg-fetcher.git
```

### Step 2: Use it
```python
from epg_fetcher import EPGFetcher

with EPGFetcher() as fetcher:
    fetcher.fetch(site='arirang.com', output_file='guide.xml')
```

✅ EPG fetched!

---

## 📦 Method 4: Node.js

### Step 1: Install
```bash
npm install epg-fetcher
```

### Step 2: Use it
```javascript
const { EPGFetcher } = require('epg-fetcher');

(async () => {
    const fetcher = new EPGFetcher();
    await fetcher.fetch({ site: 'arirang.com' });
    fetcher.cleanup();
})();
```

✅ Guide created!

---

## 🔄 Automated Daily Updates

### Using Cron:
```bash
# Edit crontab
crontab -e

# Add this line (runs daily at midnight):
0 0 * * * /path/to/epg-fetcher.sh --channels /path/to/channels.xml --output /path/to/guide.xml
```

### Using Docker Compose:
```bash
# Download docker-compose.yml
curl -O https://raw.githubusercontent.com/yourusername/epg-fetcher/main/docker-compose.yml

# Start the service
docker-compose up -d
```

Guide will be auto-updated daily and served at `http://localhost:3000/guide.xml`

---

## 🌐 Serving EPG via HTTP

### Quick HTTP Server:
```bash
# After fetching guide.xml
npx serve
```

Access at: `http://localhost:3000/guide.xml`

### Using Docker:
```bash
docker-compose up -d nginx
```

Access at: `http://localhost/guide.xml`

---

## 🎯 Common Use Cases

### For IPTV Apps:
```bash
./epg-fetcher.sh \
  --channels my-channels.xml \
  --output /var/www/html/epg/guide.xml \
  --days 7 \
  --max-connections 10
```

### For Personal Use:
```bash
./epg-fetcher.sh \
  --site arirang.com \
  --output ~/Videos/IPTV/guide.xml \
  --days 3
```

### For Multiple Sites:
```bash
for site in arirang.com bloomberg.com cnn.com; do
  ./epg-fetcher.sh --site $site --output "guide-$site.xml"
done
```

---

## 📊 Finding Available Channels

### Browse sites:
Visit: https://github.com/iptv-org/epg/blob/master/SITES.md

### Check site channels:
```bash
# Clone the repo
git clone https://github.com/iptv-org/epg.git
cd epg/sites

# View channels for a specific site
cat arirang.com/arirang.com.channels.xml
```

---

## 🛟 Troubleshooting

### Problem: Script can't find Node.js
```bash
# Install Node.js
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs
```

### Problem: Permission denied
```bash
chmod +x epg-fetcher.sh
```

### Problem: Channels not found
Make sure your channels.xml has the correct format:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<channels>
  <channel site="SITE" lang="LANG" xmltv_id="ID" site_id="SITE_ID">NAME</channel>
</channels>
```

### Problem: Slow fetching
Increase connections:
```bash
./epg-fetcher.sh --channels channels.xml --max-connections 20
```

---

## 📚 Next Steps

- [Full Documentation](README.md)
- [API Reference](api-server.py)
- [GitHub Actions Setup](.github-workflows-example.yml)
- [Available Sites](https://github.com/iptv-org/epg/blob/master/SITES.md)

---

## 💡 Tips

1. **Start small**: Test with 1-2 channels first
2. **Be respectful**: Use delays if fetching many channels
3. **Cache results**: EPG doesn't change every minute
4. **Use compression**: Enable `--gzip` for large guides
5. **Automate**: Set up cron jobs for hands-free updates

---

## ❓ Need Help?

- Check the [README](README.md) for detailed docs
- Open an issue on GitHub
- Visit [iptv-org/epg](https://github.com/iptv-org/epg) for source issues
