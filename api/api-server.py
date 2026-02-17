#!/usr/bin/env python3
"""
EPG API Server
A simple Flask API server for fetching EPG data on demand
"""

from flask import Flask, request, send_file, jsonify
from epg_fetcher import EPGFetcher, EPGChannel
import os
import json
from datetime import datetime

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
        "site": "example.com",
        "days": 3,
        "max_connections": 5,
        "output_format": "xml"
    }
    
    OR
    
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

@app.route('/api/v1/fetch-docker', methods=['POST'])
def fetch_epg_docker():
    """
    Fetch EPG data using Docker
    
    Request body:
    {
        "channels_xml": "<xml content>",
        "days": 3,
        "max_connections": 5
    }
    """
    try:
        data = request.get_json()
        
        if not data or 'channels_xml' not in data:
            return jsonify({'error': 'channels_xml is required'}), 400
        
        channels_xml = data['channels_xml']
        days = data.get('days', DEFAULT_DAYS)
        max_connections = data.get('max_connections', DEFAULT_MAX_CONNECTIONS)
        
        # Create temporary channels file
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        channels_file = os.path.join(CACHE_DIR, f'channels_{timestamp}.xml')
        output_dir = os.path.join(CACHE_DIR, f'output_{timestamp}')
        
        os.makedirs(output_dir, exist_ok=True)
        
        with open(channels_file, 'w') as f:
            f.write(channels_xml)
        
        # Fetch using Docker
        fetcher = EPGFetcher()
        
        try:
            result_path = fetcher.fetch_with_docker(
                channels_file=channels_file,
                output_dir=output_dir,
                days=days,
                max_connections=max_connections
            )
            
            return send_file(
                result_path,
                mimetype='application/xml',
                as_attachment=True,
                download_name='guide.xml'
            )
        
        finally:
            fetcher.cleanup()
    
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/v1/sites', methods=['GET'])
def list_sites():
    """List available EPG sites"""
    # This would ideally fetch from the iptv-org/epg repository
    # For now, return a static list
    sites = [
        {'site': 'arirang.com', 'name': 'Arirang TV'},
        {'site': 'bloomberg.com', 'name': 'Bloomberg'},
        {'site': 'cnn.com', 'name': 'CNN'},
        {'site': 'bbc.co.uk', 'name': 'BBC'},
        {'site': 'aljazeera.com', 'name': 'Al Jazeera'},
        {'site': 'dw.com', 'name': 'DW (Deutsche Welle)'},
        {'site': 'france24.com', 'name': 'France 24'},
        {'site': 'rt.com', 'name': 'RT'},
        {'site': 'trtworld.com', 'name': 'TRT World'}
    ]
    
    return jsonify({'sites': sites})

@app.route('/api/v1/cache', methods=['GET'])
def list_cache():
    """List cached EPG files"""
    files = []
    for filename in os.listdir(CACHE_DIR):
        if filename.endswith('.xml'):
            filepath = os.path.join(CACHE_DIR, filename)
            files.append({
                'filename': filename,
                'size': os.path.getsize(filepath),
                'created': datetime.fromtimestamp(os.path.getctime(filepath)).isoformat()
            })
    
    return jsonify({'cached_files': files})

@app.route('/api/v1/cache/<filename>', methods=['GET'])
def get_cached_file(filename):
    """Get a cached EPG file"""
    filepath = os.path.join(CACHE_DIR, filename)
    
    if not os.path.exists(filepath):
        return jsonify({'error': 'File not found'}), 404
    
    return send_file(
        filepath,
        mimetype='application/xml',
        as_attachment=True,
        download_name=filename
    )

@app.route('/api/v1/cache', methods=['DELETE'])
def clear_cache():
    """Clear all cached EPG files"""
    deleted = 0
    for filename in os.listdir(CACHE_DIR):
        filepath = os.path.join(CACHE_DIR, filename)
        if os.path.isfile(filepath):
            os.remove(filepath)
            deleted += 1
    
    return jsonify({
        'status': 'success',
        'deleted_files': deleted
    })

if __name__ == '__main__':
    print("Starting EPG API Server...")
    print("Available endpoints:")
    print("  GET  /health - Health check")
    print("  POST /api/v1/fetch - Fetch EPG data")
    print("  POST /api/v1/fetch-docker - Fetch EPG data using Docker")
    print("  GET  /api/v1/sites - List available sites")
    print("  GET  /api/v1/cache - List cached files")
    print("  GET  /api/v1/cache/<filename> - Get cached file")
    print("  DELETE /api/v1/cache - Clear cache")
    print("\nServer running on http://0.0.0.0:5000")
    
    app.run(host='0.0.0.0', port=5000, debug=True)
