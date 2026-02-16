# Deployment Guide - How to Publish This to GitHub

## Quick Deploy Checklist

- [ ] Create GitHub repository
- [ ] Organize files into proper structure
- [ ] Update all URLs in scripts
- [ ] Push to GitHub
- [ ] Create initial release
- [ ] Test from another repository
- [ ] Add documentation
- [ ] Enable GitHub Pages (optional)

---

## Step 1: Create GitHub Repository

1. Go to GitHub and create a new repository
2. Name it: `epg-fetcher` or `iptv-epg-tools`
3. Make it **Public** (so others can use it)
4. Add description: "Tools for fetching EPG (Electronic Program Guide) data from iptv-org/epg"
5. **Do NOT** initialize with README (we have our own)
6. Choose license: **Unlicense** (public domain)

---

## Step 2: Organize Files

### Recommended Structure:

```
epg-fetcher/
├── README.md
├── QUICKSTART.md
├── SUMMARY.md
├── LICENSE
├── .gitignore
│
├── scripts/
│   ├── request-epg.sh          ← Main entry point
│   ├── epg-fetcher.sh
│   ├── epg-fetcher-docker.sh
│   ├── epg_fetcher.py
│   └── epg-fetcher.js
│
├── api/
│   ├── api-server.py
│   ├── requirements.txt
│   └── Dockerfile
│
├── config/
│   └── example-channels.xml
│
├── deployment/
│   ├── docker-compose.yml
│   └── nginx.conf
│
├── .github/
│   └── workflows/
│       └── fetch-epg.yml
│
├── docs/
│   ├── REPOSITORY-STRUCTURE.md
│   └── INTEGRATION-EXAMPLES.md
│
└── package.json
```

### Commands to Organize:

```bash
# Navigate to your local directory with the downloaded files
cd /path/to/epg-fetcher-scripts

# Create directory structure
mkdir -p scripts api config deployment docs .github/workflows

# Move files
mv epg-fetcher*.sh request-epg.sh epg_fetcher.py epg-fetcher.js scripts/
mv api-server.py api/
mv requirements.txt api/
mv Dockerfile.api api/Dockerfile
mv example-channels.xml config/
mv docker-compose.yml nginx.conf deployment/
mv github-actions-workflow.yml .github/workflows/fetch-epg.yml
mv REPOSITORY-STRUCTURE.md INTEGRATION-EXAMPLES.md docs/

# Keep in root
# README.md, QUICKSTART.md, SUMMARY.md, package.json stay in root
```

---

## Step 3: Update URLs in Scripts

**IMPORTANT**: Replace `YOUR-USERNAME` and `yourusername` with your actual GitHub username in these files:

### Files to update:

1. **scripts/request-epg.sh**
   - Line ~230: Change URL to your repo
   ```bash
   script_url="https://raw.githubusercontent.com/YOUR-USERNAME/epg-fetcher/main/$script_name"
   ```

2. **docs/INTEGRATION-EXAMPLES.md**
   - Replace all instances of `YOUR-USERNAME` with your GitHub username

3. **README.md**
   - Update installation instructions with your repo URL

### Quick find/replace:
```bash
# Replace YOUR-USERNAME with your actual username
find . -type f \( -name "*.sh" -o -name "*.md" \) -exec sed -i 's/YOUR-USERNAME/your-actual-username/g' {} +
find . -type f \( -name "*.sh" -o -name "*.md" \) -exec sed -i 's/yourusername/your-actual-username/g' {} +
```

---

## Step 4: Create .gitignore

Create `.gitignore` file:

```bash
cat > .gitignore << 'EOF'
# EPG outputs
*.xml
!example-channels.xml
!config/**/*.xml
*.xml.gz

# Python
__pycache__/
*.py[cod]
*$py.class
venv/
env/

# Node.js
node_modules/
npm-debug.log*
package-lock.json

# Temp files
*.tmp
.DS_Store
epg-work/
epg_cache/
output/
public/

# IDE
.vscode/
.idea/
*.swp
EOF
```

---

## Step 5: Initialize Git and Push

```bash
# Initialize git
git init
git branch -M main

# Add all files
git add .

# Commit
git commit -m "Initial commit: EPG Fetcher tools v1.0.0"

# Add remote (replace with your repo URL)
git remote add origin https://github.com/YOUR-USERNAME/epg-fetcher.git

# Push
git push -u origin main
```

---

## Step 6: Create Initial Release

```bash
# Tag the release
git tag -a v1.0.0 -m "Release v1.0.0 - Initial release with all core features"

# Push the tag
git push origin v1.0.0
```

Or create release via GitHub web interface:
1. Go to your repo
2. Click "Releases" → "Create a new release"
3. Tag: `v1.0.0`
4. Title: `EPG Fetcher v1.0.0`
5. Description:
   ```
   Initial release of EPG Fetcher tools
   
   Features:
   - Bash scripts for direct fetching
   - Docker support
   - Python library
   - Node.js library
   - REST API server
   - GitHub Actions examples
   - Full documentation
   ```

---

## Step 7: Configure Repository Settings

### Topics/Tags
Go to repo → About (gear icon) → Add topics:
- `epg`
- `iptv`
- `tv-guide`
- `xmltv`
- `electronic-program-guide`
- `docker`
- `python`
- `nodejs`
- `bash`

### Description
"Tools for fetching EPG (Electronic Program Guide) data from iptv-org/epg for IPTV applications"

### Website
`https://github.com/iptv-org/epg`

---

## Step 8: Test from Another Repository

Create a test repository or use an existing one:

```bash
# In a different directory
mkdir test-epg-integration
cd test-epg-integration

# Test the remote script
curl -sSL https://raw.githubusercontent.com/YOUR-USERNAME/epg-fetcher/main/scripts/request-epg.sh | \
  bash -s -- --site arirang.com --output guide.xml

# Verify it worked
ls -lh guide.xml
```

---

## Step 9: Enable GitHub Pages (Optional)

If you want a nice documentation website:

1. Go to Settings → Pages
2. Source: Deploy from branch
3. Branch: `main`
4. Folder: `/ (root)` or `/docs`
5. Save

Your docs will be at: `https://YOUR-USERNAME.github.io/epg-fetcher/`

---

## Step 10: Add Documentation Links

Update `README.md` to include:

```markdown
## Documentation

- 📚 [Full Documentation](README.md)
- 🚀 [Quick Start Guide](QUICKSTART.md)
- 📦 [Package Summary](SUMMARY.md)
- 🔌 [Integration Examples](docs/INTEGRATION-EXAMPLES.md)
- 🏗️ [Repository Structure](docs/REPOSITORY-STRUCTURE.md)

## Quick Links

- [iptv-org/epg](https://github.com/iptv-org/epg) - Source EPG repository
- [Available Sites](https://github.com/iptv-org/epg/blob/master/SITES.md)
- [Issues](https://github.com/YOUR-USERNAME/epg-fetcher/issues)
```

---

## Complete Initialization Script

Here's a complete script to do everything at once:

```bash
#!/bin/bash
# deploy-to-github.sh

set -e

# Configuration
GITHUB_USERNAME="YOUR-USERNAME"  # ← CHANGE THIS
REPO_NAME="epg-fetcher"

echo "=== EPG Fetcher - GitHub Deployment ==="
echo "Username: $GITHUB_USERNAME"
echo "Repo:     $REPO_NAME"
echo "========================================"

# Create structure
mkdir -p scripts api config deployment docs .github/workflows

# Move files
mv epg-fetcher*.sh request-epg.sh epg_fetcher.py epg-fetcher.js scripts/ 2>/dev/null || true
mv api-server.py api/ 2>/dev/null || true
mv requirements.txt api/ 2>/dev/null || true
mv Dockerfile.api api/Dockerfile 2>/dev/null || true
mv example-channels.xml config/ 2>/dev/null || true
mv docker-compose.yml nginx.conf deployment/ 2>/dev/null || true
mv github-actions-workflow.yml .github/workflows/fetch-epg.yml 2>/dev/null || true
mv REPOSITORY-STRUCTURE.md INTEGRATION-EXAMPLES.md docs/ 2>/dev/null || true

# Update URLs
find . -type f \( -name "*.sh" -o -name "*.md" \) -exec sed -i "s/YOUR-USERNAME/$GITHUB_USERNAME/g" {} +
find . -type f \( -name "*.sh" -o -name "*.md" \) -exec sed -i "s/yourusername/$GITHUB_USERNAME/g" {} +

# Create .gitignore
cat > .gitignore << 'EOF'
*.xml
!example-channels.xml
!config/**/*.xml
*.xml.gz
__pycache__/
*.py[cod]
venv/
node_modules/
*.tmp
.DS_Store
EOF

# Initialize git
git init
git branch -M main

# Add files
git add .
git commit -m "Initial commit: EPG Fetcher tools v1.0.0"

# Add remote
git remote add origin "https://github.com/$GITHUB_USERNAME/$REPO_NAME.git"

echo ""
echo "✓ Repository prepared!"
echo ""
echo "Next steps:"
echo "  1. Create the repository on GitHub: https://github.com/new"
echo "  2. Run: git push -u origin main"
echo "  3. Run: git tag -a v1.0.0 -m 'Release v1.0.0' && git push origin v1.0.0"
echo "  4. Test: curl -sSL https://raw.githubusercontent.com/$GITHUB_USERNAME/$REPO_NAME/main/scripts/request-epg.sh"
```

Save as `deploy-to-github.sh`, update `GITHUB_USERNAME`, and run it!

---

## Verification Checklist

After deployment, verify:

- [ ] Repository is public
- [ ] README displays correctly
- [ ] All scripts are executable
- [ ] Remote script execution works:
  ```bash
  curl -sSL https://raw.githubusercontent.com/YOUR-USERNAME/epg-fetcher/main/scripts/request-epg.sh
  ```
- [ ] Topics/tags are set
- [ ] License file exists
- [ ] Release v1.0.0 is created
- [ ] Integration examples work from another repo

---

## Usage After Deployment

### For You:
```bash
# Update the repo
git pull

# Make changes
# ... edit files ...

git add .
git commit -m "Description of changes"
git push

# New release
git tag -a v1.0.1 -m "Release v1.0.1"
git push origin v1.0.1
```

### For Others:
```bash
# They can use your tool immediately:
curl -sSL https://raw.githubusercontent.com/YOUR-USERNAME/epg-fetcher/main/scripts/request-epg.sh | \
  bash -s -- --site arirang.com --output guide.xml
```

---

## Troubleshooting

**Problem: "Permission denied" on git push**
```bash
# Use SSH instead of HTTPS
git remote set-url origin git@github.com:YOUR-USERNAME/epg-fetcher.git
```

**Problem: Script URL returns 404**
- Make sure repository is public
- Check the URL is correct
- Wait a few minutes for GitHub to propagate

**Problem: Raw URL not working**
- Must be: `raw.githubusercontent.com` not `github.com`
- Must include `/main/` in path
- Check file actually exists in repo

---

## Support & Maintenance

After deployment, monitor:
- GitHub Issues for bug reports
- Pull requests from contributors
- Star/fork count
- Integration questions

Consider:
- Creating a CHANGELOG.md
- Setting up GitHub Actions for automated tests
- Adding a CONTRIBUTING.md guide
- Creating issue templates

---

## You're Ready to Deploy! 🚀

Follow the steps above and you'll have a fully functional, shareable EPG fetcher repository that others can use immediately!
