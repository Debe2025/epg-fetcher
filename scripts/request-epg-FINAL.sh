#!/bin/bash
#
# EPG Request Handler
# This script is meant to be called from other repositories to fetch specific EPG data
# It acts as a simple interface that other repos can use via curl or git submodule
#
# Usage from another repository:
#   curl -sSL https://raw.githubusercontent.com/Debe2025/epg-fetcher/main/request-epg.sh | bash -s -- [options]
#   OR
#   git submodule add https://github.com/Debe2025/epg-fetcher.git epg
#   ./epg/request-epg.sh [options]
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Default configuration
DEFAULT_SITE=""
DEFAULT_CHANNELS_URL=""
DEFAULT_OUTPUT="guide.xml"
DEFAULT_DAYS="3"
DEFAULT_MAX_CONNECTIONS="5"
METHOD="auto"  # auto, direct, docker
KEEP_TEMP="false"

print_info() {
    echo -e "${GREEN}[EPG]${NC} $1" >&2
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

show_help() {
    cat << EOF
EPG Request Handler - Fetch EPG data for your repository

This script can be used by other repositories to fetch EPG data.

Usage: 
    # Direct execution
    ./request-epg.sh [OPTIONS]
    
    # Remote execution
    curl -sSL https://raw.githubusercontent.com/user/repo/main/request-epg.sh | bash -s -- [OPTIONS]

Options:
    --site SITE                  Fetch from specific site (e.g., arirang.com)
    --channels-file FILE         Use local channels.xml file
    --channels-url URL           Download channels.xml from URL
    --output FILE                Output file path (default: guide.xml)
    --days DAYS                  Number of days to fetch (default: 3)
    --max-connections NUM        Max concurrent connections (default: 5)
    --method METHOD              Fetch method: auto|direct|docker (default: auto)
    --keep-temp                  Keep temporary files
    -h, --help                   Show this help

Examples:
    # Fetch from a specific site
    ./request-epg.sh --site arirang.com --output epg/guide.xml

    # Use channels from a URL
    ./request-epg.sh --channels-url https://example.com/channels.xml --days 7

    # Use local channels file
    ./request-epg.sh --channels-file my-channels.xml --max-connections 10

    # Remote execution
    curl -sSL https://raw.githubusercontent.com/user/epg-fetcher/main/request-epg.sh | \\
        bash -s -- --site arirang.com --output guide.xml

Integration in other repos:
    # In your repo's script or Makefile
    fetch-epg:
        curl -sSL https://raw.githubusercontent.com/user/epg-fetcher/main/request-epg.sh | \\
            bash -s -- --channels-url https://your-site.com/channels.xml

    # Or as git submodule
    git submodule add https://github.com/user/epg-fetcher.git epg-tools
    ./epg-tools/request-epg.sh --site example.com

EOF
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --site)
                DEFAULT_SITE="$2"
                shift 2
                ;;
            --channels-file)
                CHANNELS_FILE="$2"
                shift 2
                ;;
            --channels-url)
                DEFAULT_CHANNELS_URL="$2"
                shift 2
                ;;
            --output)
                DEFAULT_OUTPUT="$2"
                shift 2
                ;;
            --days)
                DEFAULT_DAYS="$2"
                shift 2
                ;;
            --max-connections)
                DEFAULT_MAX_CONNECTIONS="$2"
                shift 2
                ;;
            --method)
                METHOD="$2"
                shift 2
                ;;
            --keep-temp)
                KEEP_TEMP="true"
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

detect_method() {
    if [ "$METHOD" != "auto" ]; then
        return
    fi
    
    # If site is specified, use direct method (Docker doesn't support sites)
    if [ -n "$DEFAULT_SITE" ]; then
        if command -v node &> /dev/null && command -v npm &> /dev/null && command -v git &> /dev/null; then
            METHOD="direct"
            print_info "Using direct method (required for site-based fetching)"
            return
        else
            print_error "Site-based fetching requires Node.js, npm, and git"
            print_error "Please install Node.js: https://nodejs.org/"
            exit 1
        fi
    fi
    
    # Check if Docker is available (for channels-based fetching)
    if command -v docker &> /dev/null; then
        if docker info &> /dev/null 2>&1; then
            METHOD="docker"
            print_info "Using Docker method"
            return
        fi
    fi
    
    # Check if Node.js is available
    if command -v node &> /dev/null && command -v npm &> /dev/null && command -v git &> /dev/null; then
        METHOD="direct"
        print_info "Using direct method"
        return
    fi
    
    print_error "Neither Docker nor Node.js/npm/git are available"
    print_error "Please install one of the following:"
    print_error "  - Docker: https://docs.docker.com/get-docker/"
    print_error "  - Node.js: https://nodejs.org/"
    exit 1
}

setup_temp_dir() {
    TEMP_DIR=$(mktemp -d -t epg-XXXXXX)
    print_info "Using temp directory: $TEMP_DIR"
    
    # Cleanup on exit
    if [ "$KEEP_TEMP" = "false" ]; then
        trap "rm -rf $TEMP_DIR" EXIT
    fi
}

download_channels() {
    if [ -n "$DEFAULT_CHANNELS_URL" ]; then
        print_info "Downloading channels from: $DEFAULT_CHANNELS_URL"
        CHANNELS_FILE="$TEMP_DIR/channels.xml"
        
        if command -v curl &> /dev/null; then
            curl -sSL "$DEFAULT_CHANNELS_URL" -o "$CHANNELS_FILE"
        elif command -v wget &> /dev/null; then
            wget -q "$DEFAULT_CHANNELS_URL" -O "$CHANNELS_FILE"
        else
            print_error "Neither curl nor wget is available"
            exit 1
        fi
        
        if [ ! -s "$CHANNELS_FILE" ]; then
            print_error "Failed to download channels file or file is empty"
            exit 1
        fi
        
        print_info "Channels downloaded successfully"
    fi
}

download_fetcher_script() {
    local script_name="$1"
    local script_url="https://raw.githubusercontent.com/Debe2025/epg-fetcher/main/scripts/$script_name"
    local script_path="$TEMP_DIR/$script_name"
    
    print_info "Downloading $script_name..."
    
    if command -v curl &> /dev/null; then
        curl -sSL "$script_url" -o "$script_path"
    elif command -v wget &> /dev/null; then
        wget -q "$script_url" -O "$script_path"
    else
        print_error "Neither curl nor wget is available"
        exit 1
    fi
    
    chmod +x "$script_path"
    echo "$script_path"
}

fetch_with_docker() {
    print_info "Fetching EPG using Docker method..."
    
    # Validate inputs
    if [ -z "$CHANNELS_FILE" ] && [ -z "$DEFAULT_SITE" ]; then
        print_error "Either --channels-file, --channels-url, or --site must be provided"
        exit 1
    fi
    
    # Pull the image
    print_info "Pulling Docker image..."
    docker pull ghcr.io/iptv-org/epg:master
    
    # Create output directory
    OUTPUT_DIR=$(dirname "$DEFAULT_OUTPUT")
    mkdir -p "$OUTPUT_DIR"
    
    if [ -n "$CHANNELS_FILE" ]; then
        # Fetch with channels file
        docker run --rm \
            -v "$(realpath "$CHANNELS_FILE"):/epg/channels.xml:ro" \
            -v "$(realpath "$OUTPUT_DIR"):/epg/output" \
            -e MAX_CONNECTIONS="$DEFAULT_MAX_CONNECTIONS" \
            -e DAYS="$DEFAULT_DAYS" \
            -e RUN_AT_STARTUP=true \
            ghcr.io/iptv-org/epg:master
        
        # Move from output directory to desired location
        if [ -f "$OUTPUT_DIR/guide.xml" ]; then
            mv "$OUTPUT_DIR/guide.xml" "$DEFAULT_OUTPUT"
        fi
    else
        print_error "Docker method requires a channels file"
        print_error "Site-based fetching is not supported with Docker method"
        exit 1
    fi
}

fetch_with_direct() {
    print_info "Fetching EPG using direct method..."
    
    # Download the fetcher script
    FETCHER_SCRIPT=$(download_fetcher_script "epg-fetcher.sh")
    
    # Build command
    CMD="$FETCHER_SCRIPT --output $DEFAULT_OUTPUT --days $DEFAULT_DAYS --max-connections $DEFAULT_MAX_CONNECTIONS"
    
    if [ -n "$DEFAULT_SITE" ]; then
        CMD="$CMD --site $DEFAULT_SITE"
    elif [ -n "$CHANNELS_FILE" ]; then
        CMD="$CMD --channels $CHANNELS_FILE"
    else
        print_error "Either --site or --channels must be provided"
        exit 1
    fi
    
    print_info "Running: $CMD"
    eval "$CMD"
}

main() {
    parse_args "$@"
    
    print_info "EPG Request Handler started"
    
    setup_temp_dir
    download_channels
    detect_method
    
    case "$METHOD" in
        docker)
            fetch_with_docker
            ;;
        direct)
            fetch_with_direct
            ;;
        *)
            print_error "Unknown method: $METHOD"
            exit 1
            ;;
    esac
    
    if [ -f "$DEFAULT_OUTPUT" ]; then
        FILE_SIZE=$(du -h "$DEFAULT_OUTPUT" | cut -f1)
        print_info "EPG data fetched successfully!"
        echo -e "${GREEN}✓${NC} Output: $DEFAULT_OUTPUT (${FILE_SIZE})"
    else
        print_error "Failed to create output file: $DEFAULT_OUTPUT"
        exit 1
    fi
}

main "$@"
