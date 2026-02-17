#!/usr/bin/env python3
"""
EPG Fetcher Library
A Python library for fetching EPG data from iptv-org/epg
"""

import subprocess
import os
import json
import xml.etree.ElementTree as ET
from typing import List, Optional, Dict
from pathlib import Path
import tempfile
import shutil


class EPGChannel:
    """Represents a single EPG channel"""
    
    def __init__(self, site: str, lang: str, xmltv_id: str, site_id: str, name: str):
        self.site = site
        self.lang = lang
        self.xmltv_id = xmltv_id
        self.site_id = site_id
        self.name = name
    
    def to_xml_element(self) -> ET.Element:
        """Convert channel to XML element"""
        channel = ET.Element('channel')
        channel.set('site', self.site)
        channel.set('lang', self.lang)
        channel.set('xmltv_id', self.xmltv_id)
        channel.set('site_id', self.site_id)
        channel.text = self.name
        return channel
    
    @classmethod
    def from_dict(cls, data: Dict) -> 'EPGChannel':
        """Create channel from dictionary"""
        return cls(
            site=data['site'],
            lang=data['lang'],
            xmltv_id=data['xmltv_id'],
            site_id=data['site_id'],
            name=data['name']
        )


class EPGFetcher:
    """Main EPG fetcher class"""
    
    def __init__(self, work_dir: Optional[str] = None):
        """
        Initialize EPG Fetcher
        
        Args:
            work_dir: Working directory for EPG operations (default: temp directory)
        """
        self.work_dir = work_dir or tempfile.mkdtemp(prefix='epg_')
        self.epg_repo_path = os.path.join(self.work_dir, 'epg')
        self.channels_file = os.path.join(self.work_dir, 'channels.xml')
        self._setup_done = False
    
    def setup(self) -> None:
        """Setup EPG repository"""
        if self._setup_done:
            return
        
        print("Setting up EPG repository...")
        
        # Create work directory
        os.makedirs(self.work_dir, exist_ok=True)
        
        # Clone repository if not exists
        if not os.path.exists(self.epg_repo_path):
            subprocess.run([
                'git', 'clone', '--depth', '1', '-b', 'master',
                'https://github.com/iptv-org/epg.git',
                self.epg_repo_path
            ], check=True, capture_output=True)
        
        # Install dependencies
        subprocess.run(
            ['npm', 'install'],
            cwd=self.epg_repo_path,
            check=True,
            capture_output=True
        )
        
        self._setup_done = True
        print("Setup complete.")
    
    def create_channels_file(self, channels: List[EPGChannel]) -> str:
        """
        Create channels XML file
        
        Args:
            channels: List of EPGChannel objects
        
        Returns:
            Path to created channels.xml file
        """
        root = ET.Element('channels')
        for channel in channels:
            root.append(channel.to_xml_element())
        
        tree = ET.ElementTree(root)
        ET.indent(tree, space='  ')
        tree.write(self.channels_file, encoding='UTF-8', xml_declaration=True)
        
        return self.channels_file
    
    def fetch(
        self,
        site: Optional[str] = None,
        channels: Optional[List[EPGChannel]] = None,
        output_file: str = 'guide.xml',
        days: Optional[int] = None,
        lang: Optional[str] = None,
        max_connections: int = 1,
        timeout: int = 30000,
        delay: int = 0,
        gzip: bool = False
    ) -> str:
        """
        Fetch EPG data
        
        Args:
            site: Site to fetch from (e.g., 'example.com')
            channels: List of EPGChannel objects (alternative to site)
            output_file: Output file path
            days: Number of days to fetch
            lang: Language codes (comma-separated)
            max_connections: Maximum concurrent connections
            timeout: Request timeout in milliseconds
            delay: Delay between requests in milliseconds
            gzip: Create compressed version
        
        Returns:
            Path to output file
        """
        self.setup()
        
        # Build command
        cmd = ['npm', 'run', 'grab', '---']
        
        if site:
            cmd.extend(['--site', site])
        elif channels:
            channels_file = self.create_channels_file(channels)
            cmd.extend(['--channels', channels_file])
        else:
            raise ValueError("Either 'site' or 'channels' must be provided")
        
        cmd.extend(['--output', output_file])
        
        if days:
            cmd.extend(['--days', str(days)])
        
        if lang:
            cmd.extend(['--lang', lang])
        
        cmd.extend(['--maxConnections', str(max_connections)])
        cmd.extend(['--timeout', str(timeout)])
        cmd.extend(['--delay', str(delay)])
        
        if gzip:
            cmd.append('--gzip')
        
        print(f"Fetching EPG data...")
        print(f"Command: {' '.join(cmd)}")
        
        # Run command
        result = subprocess.run(
            cmd,
            cwd=self.epg_repo_path,
            check=True,
            capture_output=True,
            text=True
        )
        
        # Get output file path
        output_path = os.path.join(self.epg_repo_path, output_file)
        
        if not os.path.exists(output_path):
            raise FileNotFoundError(f"Output file not created: {output_path}")
        
        print(f"EPG data fetched successfully: {output_path}")
        return output_path
    
    def fetch_with_docker(
        self,
        channels_file: str,
        output_dir: str,
        max_connections: int = 1,
        days: Optional[int] = None,
        gzip: bool = False,
        timeout: int = 30000,
        delay: int = 0,
        image: str = 'ghcr.io/iptv-org/epg:master'
    ) -> str:
        """
        Fetch EPG data using Docker
        
        Args:
            channels_file: Path to channels.xml file
            output_dir: Directory for output files
            max_connections: Maximum concurrent connections
            days: Number of days to fetch
            gzip: Create compressed version
            timeout: Request timeout in milliseconds
            delay: Delay between requests in milliseconds
            image: Docker image to use
        
        Returns:
            Path to output file
        """
        if not os.path.exists(channels_file):
            raise FileNotFoundError(f"Channels file not found: {channels_file}")
        
        os.makedirs(output_dir, exist_ok=True)
        
        # Build docker command
        cmd = [
            'docker', 'run', '--rm',
            '-v', f'{os.path.abspath(channels_file)}:/epg/channels.xml:ro',
            '-v', f'{os.path.abspath(output_dir)}:/epg/output',
            '-e', f'MAX_CONNECTIONS={max_connections}',
            '-e', f'TIMEOUT={timeout}',
            '-e', f'DELAY={delay}',
            '-e', f'GZIP={str(gzip).lower()}',
            '-e', 'RUN_AT_STARTUP=true'
        ]
        
        if days:
            cmd.extend(['-e', f'DAYS={days}'])
        
        cmd.append(image)
        
        print(f"Fetching EPG data with Docker...")
        
        # Run docker container
        subprocess.run(cmd, check=True)
        
        output_file = os.path.join(output_dir, 'guide.xml')
        
        if not os.path.exists(output_file):
            raise FileNotFoundError(f"Output file not created: {output_file}")
        
        print(f"EPG data fetched successfully: {output_file}")
        return output_file
    
    def cleanup(self) -> None:
        """Clean up working directory"""
        if os.path.exists(self.work_dir) and self.work_dir.startswith('/tmp'):
            shutil.rmtree(self.work_dir)
            print(f"Cleaned up work directory: {self.work_dir}")
    
    def __enter__(self):
        """Context manager entry"""
        return self
    
    def __exit__(self, exc_type, exc_val, exc_tb):
        """Context manager exit"""
        self.cleanup()


# Example usage
if __name__ == '__main__':
    # Example 1: Fetch from specific site
    with EPGFetcher() as fetcher:
        output = fetcher.fetch(
            site='example.com',
            output_file='guide.xml',
            days=3,
            max_connections=5
        )
        print(f"Guide saved to: {output}")
    
    # Example 2: Fetch with custom channels
    channels = [
        EPGChannel(
            site='arirang.com',
            lang='en',
            xmltv_id='ArirangTV.kr',
            site_id='CH_K',
            name='Arirang TV'
        ),
        EPGChannel(
            site='example.com',
            lang='en',
            xmltv_id='Example.tv',
            site_id='123',
            name='Example Channel'
        )
    ]
    
    with EPGFetcher() as fetcher:
        output = fetcher.fetch(
            channels=channels,
            output_file='custom_guide.xml',
            days=7,
            gzip=True
        )
        print(f"Custom guide saved to: {output}")
    
    # Example 3: Fetch with Docker
    fetcher = EPGFetcher()
    try:
        output = fetcher.fetch_with_docker(
            channels_file='channels.xml',
            output_dir='./output',
            max_connections=10,
            days=3
        )
        print(f"Docker guide saved to: {output}")
    finally:
        fetcher.cleanup()
