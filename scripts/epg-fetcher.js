/**
 * EPG Fetcher Library (Node.js)
 * A JavaScript library for fetching EPG data from iptv-org/epg
 */

const { execSync, spawn } = require('child_process');
const fs = require('fs');
const path = require('path');
const os = require('os');

class EPGChannel {
    /**
     * Create an EPG channel
     * @param {string} site - Site domain (e.g., 'example.com')
     * @param {string} lang - Language code (e.g., 'en')
     * @param {string} xmltvId - XMLTV ID
     * @param {string} siteId - Site-specific ID
     * @param {string} name - Channel name
     */
    constructor(site, lang, xmltvId, siteId, name) {
        this.site = site;
        this.lang = lang;
        this.xmltvId = xmltvId;
        this.siteId = siteId;
        this.name = name;
    }

    /**
     * Convert to XML element string
     * @returns {string} XML element
     */
    toXML() {
        return `  <channel site="${this.site}" lang="${this.lang}" xmltv_id="${this.xmltvId}" site_id="${this.siteId}">${this.name}</channel>`;
    }
}

class EPGFetcher {
    /**
     * Initialize EPG Fetcher
     * @param {Object} options - Configuration options
     * @param {string} options.workDir - Working directory (default: temp directory)
     */
    constructor(options = {}) {
        this.workDir = options.workDir || fs.mkdtempSync(path.join(os.tmpdir(), 'epg-'));
        this.epgRepoPath = path.join(this.workDir, 'epg');
        this.channelsFile = path.join(this.workDir, 'channels.xml');
        this.setupDone = false;
    }

    /**
     * Setup EPG repository
     * @returns {Promise<void>}
     */
    async setup() {
        if (this.setupDone) {
            return;
        }

        console.log('Setting up EPG repository...');

        // Create work directory
        if (!fs.existsSync(this.workDir)) {
            fs.mkdirSync(this.workDir, { recursive: true });
        }

        // Clone repository if not exists
        if (!fs.existsSync(this.epgRepoPath)) {
            execSync(
                `git clone --depth 1 -b master https://github.com/iptv-org/epg.git "${this.epgRepoPath}"`,
                { stdio: 'inherit' }
            );
        }

        // Install dependencies
        console.log('Installing dependencies...');
        execSync('npm install', {
            cwd: this.epgRepoPath,
            stdio: 'inherit'
        });

        this.setupDone = true;
        console.log('Setup complete.');
    }

    /**
     * Create channels XML file
     * @param {EPGChannel[]} channels - Array of EPG channels
     * @returns {string} Path to channels file
     */
    createChannelsFile(channels) {
        const xml = [
            '<?xml version="1.0" encoding="UTF-8"?>',
            '<channels>',
            ...channels.map(ch => ch.toXML()),
            '</channels>'
        ].join('\n');

        fs.writeFileSync(this.channelsFile, xml, 'utf8');
        return this.channelsFile;
    }

    /**
     * Fetch EPG data
     * @param {Object} options - Fetch options
     * @param {string} options.site - Site to fetch from
     * @param {EPGChannel[]} options.channels - Array of channels (alternative to site)
     * @param {string} options.output - Output file path (default: 'guide.xml')
     * @param {number} options.days - Number of days to fetch
     * @param {string} options.lang - Language codes (comma-separated)
     * @param {number} options.maxConnections - Max concurrent connections (default: 1)
     * @param {number} options.timeout - Request timeout in ms (default: 30000)
     * @param {number} options.delay - Delay between requests in ms (default: 0)
     * @param {boolean} options.gzip - Create compressed version (default: false)
     * @returns {Promise<string>} Path to output file
     */
    async fetch(options = {}) {
        await this.setup();

        const {
            site,
            channels,
            output = 'guide.xml',
            days,
            lang,
            maxConnections = 1,
            timeout = 30000,
            delay = 0,
            gzip = false
        } = options;

        // Build command arguments
        const args = ['run', 'grab', '---'];

        if (site) {
            args.push(`--site=${site}`);
        } else if (channels && channels.length > 0) {
            const channelsFile = this.createChannelsFile(channels);
            args.push(`--channels=${channelsFile}`);
        } else {
            throw new Error("Either 'site' or 'channels' must be provided");
        }

        args.push(`--output=${output}`);

        if (days) args.push(`--days=${days}`);
        if (lang) args.push(`--lang=${lang}`);
        
        args.push(`--maxConnections=${maxConnections}`);
        args.push(`--timeout=${timeout}`);
        args.push(`--delay=${delay}`);
        
        if (gzip) args.push('--gzip');

        console.log('Fetching EPG data...');
        console.log(`Command: npm ${args.join(' ')}`);

        // Run command
        return new Promise((resolve, reject) => {
            const proc = spawn('npm', args, {
                cwd: this.epgRepoPath,
                stdio: 'inherit'
            });

            proc.on('close', (code) => {
                if (code !== 0) {
                    reject(new Error(`EPG fetch failed with code ${code}`));
                    return;
                }

                const outputPath = path.join(this.epgRepoPath, output);
                
                if (!fs.existsSync(outputPath)) {
                    reject(new Error(`Output file not created: ${outputPath}`));
                    return;
                }

                console.log(`EPG data fetched successfully: ${outputPath}`);
                resolve(outputPath);
            });

            proc.on('error', reject);
        });
    }

    /**
     * Fetch EPG data using Docker
     * @param {Object} options - Docker fetch options
     * @param {string} options.channelsFile - Path to channels.xml file
     * @param {string} options.outputDir - Directory for output files
     * @param {number} options.maxConnections - Max concurrent connections (default: 1)
     * @param {number} options.days - Number of days to fetch
     * @param {boolean} options.gzip - Create compressed version (default: false)
     * @param {number} options.timeout - Request timeout in ms (default: 30000)
     * @param {number} options.delay - Delay between requests in ms (default: 0)
     * @param {string} options.image - Docker image (default: ghcr.io/iptv-org/epg:master)
     * @returns {Promise<string>} Path to output file
     */
    async fetchWithDocker(options = {}) {
        const {
            channelsFile,
            outputDir,
            maxConnections = 1,
            days,
            gzip = false,
            timeout = 30000,
            delay = 0,
            image = 'ghcr.io/iptv-org/epg:master'
        } = options;

        if (!channelsFile) {
            throw new Error('channelsFile is required');
        }

        if (!fs.existsSync(channelsFile)) {
            throw new Error(`Channels file not found: ${channelsFile}`);
        }

        if (!fs.existsSync(outputDir)) {
            fs.mkdirSync(outputDir, { recursive: true });
        }

        // Build docker command
        const args = [
            'run', '--rm',
            '-v', `${path.resolve(channelsFile)}:/epg/channels.xml:ro`,
            '-v', `${path.resolve(outputDir)}:/epg/output`,
            '-e', `MAX_CONNECTIONS=${maxConnections}`,
            '-e', `TIMEOUT=${timeout}`,
            '-e', `DELAY=${delay}`,
            '-e', `GZIP=${gzip}`,
            '-e', 'RUN_AT_STARTUP=true'
        ];

        if (days) {
            args.push('-e', `DAYS=${days}`);
        }

        args.push(image);

        console.log('Fetching EPG data with Docker...');

        return new Promise((resolve, reject) => {
            const proc = spawn('docker', args, {
                stdio: 'inherit'
            });

            proc.on('close', (code) => {
                if (code !== 0) {
                    reject(new Error(`Docker fetch failed with code ${code}`));
                    return;
                }

                const outputFile = path.join(outputDir, 'guide.xml');
                
                if (!fs.existsSync(outputFile)) {
                    reject(new Error(`Output file not created: ${outputFile}`));
                    return;
                }

                console.log(`EPG data fetched successfully: ${outputFile}`);
                resolve(outputFile);
            });

            proc.on('error', reject);
        });
    }

    /**
     * Clean up working directory
     */
    cleanup() {
        if (fs.existsSync(this.workDir) && this.workDir.includes('/tmp')) {
            fs.rmSync(this.workDir, { recursive: true, force: true });
            console.log(`Cleaned up work directory: ${this.workDir}`);
        }
    }
}

// Export for use as module
module.exports = { EPGFetcher, EPGChannel };

// Example usage if run directly
if (require.main === module) {
    (async () => {
        // Example 1: Fetch from specific site
        const fetcher1 = new EPGFetcher();
        try {
            const output = await fetcher1.fetch({
                site: 'example.com',
                output: 'guide.xml',
                days: 3,
                maxConnections: 5
            });
            console.log(`Guide saved to: ${output}`);
        } finally {
            fetcher1.cleanup();
        }

        // Example 2: Fetch with custom channels
        const channels = [
            new EPGChannel('arirang.com', 'en', 'ArirangTV.kr', 'CH_K', 'Arirang TV'),
            new EPGChannel('example.com', 'en', 'Example.tv', '123', 'Example Channel')
        ];

        const fetcher2 = new EPGFetcher();
        try {
            const output = await fetcher2.fetch({
                channels: channels,
                output: 'custom_guide.xml',
                days: 7,
                gzip: true
            });
            console.log(`Custom guide saved to: ${output}`);
        } finally {
            fetcher2.cleanup();
        }

        // Example 3: Fetch with Docker
        const fetcher3 = new EPGFetcher();
        try {
            const output = await fetcher3.fetchWithDocker({
                channelsFile: 'channels.xml',
                outputDir: './output',
                maxConnections: 10,
                days: 3
            });
            console.log(`Docker guide saved to: ${output}`);
        } finally {
            fetcher3.cleanup();
        }
    })();
}
