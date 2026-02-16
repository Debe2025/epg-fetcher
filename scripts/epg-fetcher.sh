#!/bin/bash
#
# EPG Fetcher Script
# Fetches EPG data for specified channels from iptv-org/epg
#
# Usage: ./epg-fetcher.sh [options]
#

set -e

# Store initial directory
INITIAL_DIR="$(pwd)"

# Default values
WORK_DIR="./epg-work"
OUTPUT_FILE="guide.xml"
CHANNELS_FILE=""
SITE=""
DAYS=""
MAX_CONNECTIONS="1"
TIMEOUT="30000"
DELAY="0"
LANG=""
GZIP="false"
KEEP_WORK_DIR="false"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Help message
show_help() {
    cat << EOF
EPG Fetcher - Fetch Electronic Program Guide data

Usage: $0 [OPTIONS]

Options:
    -s, --site SITE              Site to fetch from (e.g., example.com)
    -c, --channels FILE          Path to channels.xml file
    -o, --output FILE            Output file path (default: guide.xml)
    -d, --days DAYS              Number of days to fetch
    -l, --lang CODES             Language codes (comma-separated, e.g., en,es)
    -m, --max-connections NUM    Max concurrent connections (default: 1)
    -t, --timeout MS             Request timeout in milliseconds (default: 30000)
    --delay MS                   Delay between requests in milliseconds (default: 0)
    --gzip                       Create gzipped version
    --keep-work                  Keep working directory after completion
    -h, --help                   Show this help message

Examples:
    # Fetch from specific site
    $0 --site example.com --output myguide.xml

    # Fetch with custom channels file
    $0 --channels mychannels.xml --days 3 --max-connections 5

    # Fetch with language filter and gzip
    $0 --site example.com --lang en,es --gzip

EOF
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -s|--site)
                SITE="$2"
                shift 2
                ;;
            -c|--channels)
                CHANNELS_FILE="$(cd "$(dirname "$2")" && pwd)/$(basename "$2")"
                shift 2
                ;;
            -o|--output)
                OUTPUT_FILE="$INITIAL_DIR/$2"
                shift 2
                ;;
            -d|--days)
                DAYS="$2"
                shift 2
                ;;
            -l|--lang)
                LANG="$2"
                shift 2
                ;;
            -m|--max-connections)
                MAX_CONNECTIONS="$2"
                shift 2
                ;;
            -t|--timeout)
                TIMEOUT="$2"
                shift 2
                ;;
            --delay)
                DELAY="$2"
                shift 2
                ;;
            --gzip)
                GZIP="true"
                shift
                ;;
            --keep-work)
                KEEP_WORK_DIR="true"
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                echo -e "${RED}Unknown option: $1${NC}"
                show_help
                exit 1
                ;;
        esac
    done
}

# Print colored message
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    print_info "Checking prerequisites..."
    
    if ! command -v node &> /dev/null; then
        print_error "Node.js is not installed. Please install Node.js first."
        exit 1
    fi
    
    if ! command -v npm &> /dev/null; then
        print_error "npm is not installed. Please install npm first."
        exit 1
    fi
    
    if ! command -v git &> /dev/null; then
        print_error "git is not installed. Please install git first."
        exit 1
    fi
    
    print_info "All prerequisites are met."
}

# Clone or update EPG repository
setup_epg_repo() {
    print_info "Setting up EPG repository..."
    
    if [ -d "$WORK_DIR" ]; then
        print_warn "Work directory already exists. Cleaning up..."
        rm -rf "$WORK_DIR"
    fi
    
    mkdir -p "$WORK_DIR"
    
    print_info "Cloning iptv-org/epg repository..."
    git clone --depth 1 -b master https://github.com/iptv-org/epg.git "$WORK_DIR" 2>&1 | grep -v "Cloning into" || true
    
    cd "$WORK_DIR"
    
    print_info "Installing dependencies..."
    npm install --silent 2>&1 | grep -E "added|removed|changed" || true
    
    cd - > /dev/null
    
    print_info "Repository setup complete."
}

# Build grab command
build_grab_command() {
    local cmd="npm run grab ---"
    
    if [ -n "$SITE" ]; then
        cmd="$cmd --site=$SITE"
    fi
    
    if [ -n "$CHANNELS_FILE" ]; then
        cmd="$cmd --channels=channels.xml"
    fi
    
    cmd="$cmd --output=guide.xml"
    
    if [ -n "$DAYS" ]; then
        cmd="$cmd --days=$DAYS"
    fi
    
    if [ -n "$LANG" ]; then
        cmd="$cmd --lang=$LANG"
    fi
    
    cmd="$cmd --maxConnections=$MAX_CONNECTIONS"
    cmd="$cmd --timeout=$TIMEOUT"
    cmd="$cmd --delay=$DELAY"
    
    if [ "$GZIP" = "true" ]; then
        cmd="$cmd --gzip"
    fi
    
    echo "$cmd"
}

# Fetch EPG data
fetch_epg() {
    print_info "Fetching EPG data..."
    
    # Copy channels file to work directory BEFORE changing directory
    if [ -n "$CHANNELS_FILE" ]; then
        cp "$CHANNELS_FILE" "$WORK_DIR/channels.xml"
    fi
    
    cd "$WORK_DIR"
    
    local cmd=$(build_grab_command)
    print_info "Running: $cmd"
    
    eval "$cmd"
    
    cd - > /dev/null
    
    print_info "EPG data fetched successfully."
}

# Copy output files
copy_output() {
    print_info "Copying output files..."
    
    if [ -f "$WORK_DIR/guide.xml" ]; then
        cp "$WORK_DIR/guide.xml" "$OUTPUT_FILE"
        print_info "Guide saved to: $OUTPUT_FILE"
    else
        print_error "Output file not found: $WORK_DIR/guide.xml"
        exit 1
    fi
    
    if [ "$GZIP" = "true" ] && [ -f "$WORK_DIR/guide.xml.gz" ]; then
        cp "$WORK_DIR/guide.xml.gz" "${OUTPUT_FILE}.gz"
        print_info "Compressed guide saved to: ${OUTPUT_FILE}.gz"
    fi
}

# Cleanup
cleanup() {
    if [ "$KEEP_WORK_DIR" = "false" ]; then
        print_info "Cleaning up work directory..."
        rm -rf "$WORK_DIR"
        print_info "Cleanup complete."
    else
        print_info "Work directory preserved at: $WORK_DIR"
    fi
}

# Main execution
main() {
    parse_args "$@"
    
    # Validate inputs
    if [ -z "$SITE" ] && [ -z "$CHANNELS_FILE" ]; then
        print_error "Either --site or --channels must be specified."
        show_help
        exit 1
    fi
    
    print_info "Starting EPG fetch process..."
    
    check_prerequisites
    setup_epg_repo
    fetch_epg
    copy_output
    cleanup
    
    print_info "EPG fetch completed successfully!"
    echo -e "${GREEN}Output file: $OUTPUT_FILE${NC}"
}

# Run main function
main "$@"