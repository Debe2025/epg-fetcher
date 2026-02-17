#!/usr/bin/env python3
"""
EPG API Server
A simple Flask API server for fetching EPG data on demand
"""

import sys
import os
from flask import Flask, request, send_file, jsonify
from datetime import datetime

# --- PATH CONFIGURATION ---
# This allows api-server.py (in /api) to find epg_fetcher.py (in /scripts)
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'scripts')))

try:
    from epg_fetcher import EPGFetcher, EPGChannel
except ImportError as e:
    print(f"Error: Could not find epg_fetcher.py. Ensure it is in the ../scripts folder. {e}")
    sys.exit(1)
# --------------------------

app = Flask(__name__)

# Configuration
CACHE_DIR = './epg_cache'
DEFAULT_DAYS = 3
DEFAULT_MAX_CONNECTIONS = 5

os.makedirs(CACHE_DIR, exist_ok=True)

@app.route('/health', methods=['GET'])
def health():
    """Health check endpoint"""
    return jsonify({
        'status': 'healthy',
        'timestamp': datetime.utcnow().isoformat()
    })

@app.route('/api/v1/fetch', methods=['POST'])
def fetch_epg():
    """
    Fetch EPG data
    
    Request body:
    {
        "channels": [
            {
                "site": "arirang.com",
                "lang": "en",
                "xmltv_id": "ArirangTV.kr",
                "site_id": "CH_K",
                "name": "Arirang TV"
            }
        ],
        "days": 3,
        "max_connections": 5
    }
    """
    try:
        data = request.get_json()
        
        if not data:
            return jsonify({'error': 'No data provided'}), 400
        
        site = data.get('site')
        channels_data = data.get('channels')
        days = data.get('days', DEFAULT_DAYS)
        max_connections = data.get('max_connections', DEFAULT_MAX_CONNECTIONS)
        output_format = data.get('output_format', 'xml')
        
        if not site and not channels_data:
            return jsonify({'error': 'Either site or channels must be provided'}), 400
        
        # Generate unique filename
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        output_file = f'guide_{timestamp}.xml'
        output_path = os.path.join(CACHE_DIR, output_file)
        
        # Create fetcher
        fetcher = EPGFetcher()
        
        try:
            if site:
                # Fetch by site
                result_path = fetcher.fetch(
                    site=site,
                    output_file=output_path,
                    days=days,
                    max_connections=max_connections
                )
            else:
                # Fetch by channels
                channels = [EPGChannel.from_dict(ch) for ch in channels_data]
                result_path = fetcher.fetch(
                    channels=channels,
                    output_file=output_path,
                    days=days,
                    max_connections=max_connections
                )
            
            if output_format == 'xml':
                return send_file(
                    result_path,
                    mimetype='application/xml',
                    as_attachment=True,
                    download_name='guide.xml'
                )
            else:
                return jsonify({
                    'status': 'success',
                    'file_path': result_path,
                    'timestamp': datetime.utcnow().isoformat()
                })
        
        finally:
            fetcher.cleanup()
    
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/v1/sites', methods=['GET'])
def list_sites():
    """List available EPG sites"""
    sites = [
        {'site': 'arirang.com', 'name': 'Arirang TV'},
        {'site': 'bloomberg.com', 'name': 'Bloomberg'},
        {'site': 'cnn.com', 'name': 'CNN'},
        {'site': 'bbc.co.uk', 'name': 'BBC'},
        {'site': 'aljazeera.com', 'name': 'Al Jazeera'}
    ]
    return jsonify({'sites': sites})

@app.route('/api/v1/cache', methods=['GET'])
def list_cache():
    """List cached EPG files"""
    files = []
    if os.path.exists(CACHE_DIR):
        for filename in os.listdir(CACHE_DIR):
            if filename.endswith('.xml'):
                filepath = os.path.join(CACHE_DIR, filename)
                files.append({
                    'filename': filename,
                    'size': os.path.getsize(filepath),
                    'created': datetime.fromtimestamp(os.path.getctime(filepath)).isoformat()
                })
    return jsonify({'cached_files': files})

@app.route('/api/v1/cache', methods=['DELETE'])
def clear_cache():
    """Clear all cached EPG files"""
    deleted = 0
    if os.path.exists(CACHE_DIR):
        for filename in os.listdir(CACHE_DIR):
            filepath = os.path.join(CACHE_DIR, filename)
            if os.path.isfile(filepath):
                os.remove(filepath)
                deleted += 1
    return jsonify({'status': 'success', 'deleted_files': deleted})

if __name__ == '__main__':
    # Use environment variable for port (required for Railway)
    port = int(os.environ.get("PORT", 5000))
    app.run(host='0.0.0.0', port=port)