#!/bin/bash
#
# Docker EPG Fetcher Script
# Fetches EPG data using the official iptv-org/epg Docker container
#
# Usage: ./epg-fetcher-docker.sh [options]
#

set -e

# Default values
OUTPUT_FILE="guide.xml"
CHANNELS_FILE=""
DOCKER_IMAGE="ghcr.io/iptv-org/epg:master"
CONTAINER_NAME="epg-fetcher-$$"
CRON_SCHEDULE="0 0 * * *"
MAX_CONNECTIONS="1"
GZIP="false"
DAYS=""
TIMEOUT="30000"
DELAY="0"
RUN_ONCE="true"
DETACHED="false"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Help message
show_help() {
    cat << EOF
Docker EPG Fetcher - Fetch EPG data using Docker

Usage: $0 [OPTIONS]

Options:
    -c, --channels FILE          Path to channels.xml file (required)
    -o, --output FILE            Output file path (default: guide.xml)
    -m, --max-connections NUM    Max concurrent connections (default: 1)
    -d, --days DAYS              Number of days to fetch
    -t, --timeout MS             Request timeout in milliseconds (default: 30000)
    --delay MS                   Delay between requests in milliseconds (default: 0)
    --gzip                       Create gzipped version
    --schedule CRON              Cron schedule for recurring fetches (default: 0 0 * * *)
    --daemon                     Run as daemon (keeps container running)
    --image IMAGE                Docker image to use (default: ghcr.io/iptv-org/epg:master)
    -h, --help                   Show this help message

Examples:
    # Single fetch
    $0 --channels mychannels.xml --output myguide.xml

    # Run as daemon with custom schedule (every 12 hours)
    $0 --channels mychannels.xml --daemon --schedule "0 */12 * * *"

    # Fetch with multiple connections and compression
    $0 --channels mychannels.xml --max-connections 10 --gzip

EOF
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -c|--channels)
                CHANNELS_FILE="$2"
                shift 2
                ;;
            -o|--output)
                OUTPUT_FILE="$2"
                shift 2
                ;;
            -m|--max-connections)
                MAX_CONNECTIONS="$2"
                shift 2
                ;;
            -d|--days)
                DAYS="$2"
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
            --schedule)
                CRON_SCHEDULE="$2"
                shift 2
                ;;
            --daemon)
                DETACHED="true"
                RUN_ONCE="false"
                shift
                ;;
            --image)
                DOCKER_IMAGE="$2"
                shift 2
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

print_success() {
    echo -e "${BLUE}[SUCCESS]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    print_info "Checking prerequisites..."
    
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed. Please install Docker first."
        exit 1
    fi
    
    if ! docker info &> /dev/null; then
        print_error "Docker daemon is not running or you don't have permissions."
        exit 1
    fi
    
    print_info "Docker is available."
}

# Validate channels file
validate_channels_file() {
    if [ -z "$CHANNELS_FILE" ]; then
        print_error "Channels file is required. Use --channels option."
        show_help
        exit 1
    fi
    
    if [ ! -f "$CHANNELS_FILE" ]; then
        print_error "Channels file not found: $CHANNELS_FILE"
        exit 1
    fi
    
    print_info "Channels file validated: $CHANNELS_FILE"
}

# Pull Docker image
pull_image() {
    print_info "Pulling Docker image: $DOCKER_IMAGE"
    docker pull "$DOCKER_IMAGE"
    print_info "Image pulled successfully."
}

# Build Docker run command
build_docker_command() {
    local cmd="docker run --rm"
    
    if [ "$DETACHED" = "true" ]; then
        cmd="$cmd -d"
    fi
    
    cmd="$cmd --name $CONTAINER_NAME"
    
    # Mount channels file
    cmd="$cmd -v $(realpath $CHANNELS_FILE):/epg/channels.xml:ro"
    
    # Mount output directory
    local output_dir=$(dirname $(realpath $OUTPUT_FILE))
    local output_name=$(basename $OUTPUT_FILE)
    cmd="$cmd -v $output_dir:/epg/output"
    
    # Environment variables
    cmd="$cmd -e MAX_CONNECTIONS=$MAX_CONNECTIONS"
    cmd="$cmd -e TIMEOUT=$TIMEOUT"
    cmd="$cmd -e DELAY=$DELAY"
    cmd="$cmd -e GZIP=$GZIP"
    cmd="$cmd -e CRON_SCHEDULE=\"$CRON_SCHEDULE\""
    cmd="$cmd -e RUN_AT_STARTUP=$RUN_ONCE"
    
    if [ -n "$DAYS" ]; then
        cmd="$cmd -e DAYS=$DAYS"
    fi
    
    cmd="$cmd $DOCKER_IMAGE"
    
    echo "$cmd"
}

# Run Docker container
run_container() {
    print_info "Starting Docker container..."
    
    local cmd=$(build_docker_command)
    print_info "Running: docker run [options] $DOCKER_IMAGE"
    
    eval "$cmd"
    
    local container_id=$CONTAINER_NAME
    
    if [ "$DETACHED" = "true" ]; then
        print_success "Container started in daemon mode: $container_id"
        print_info "To view logs: docker logs -f $container_id"
        print_info "To stop: docker stop $container_id"
    else
        print_info "Container execution started..."
    fi
}

# Wait for output and copy it
wait_and_copy_output() {
    if [ "$DETACHED" = "false" ]; then
        print_info "Waiting for EPG fetch to complete..."
        
        # The container should have already completed since we used --rm without -d
        sleep 2
        
        # Check if the guide.xml was created in the mounted output directory
        local output_dir=$(dirname $(realpath $OUTPUT_FILE))
        if [ -f "$output_dir/guide.xml" ]; then
            print_success "EPG data fetched successfully!"
            print_info "Output file: $OUTPUT_FILE"
            
            if [ "$GZIP" = "true" ] && [ -f "$output_dir/guide.xml.gz" ]; then
                print_info "Compressed output: ${OUTPUT_FILE}.gz"
            fi
        else
            print_error "Output file not found. Check container logs."
            exit 1
        fi
    fi
}

# Cleanup function
cleanup() {
    if [ "$DETACHED" = "false" ]; then
        # Container should already be removed with --rm flag
        print_info "Cleanup complete."
    fi
}

# Main execution
main() {
    parse_args "$@"
    
    print_info "Starting Docker EPG fetch process..."
    
    check_prerequisites
    validate_channels_file
    pull_image
    run_container
    wait_and_copy_output
    
    if [ "$DETACHED" = "false" ]; then
        print_success "EPG fetch completed successfully!"
        echo -e "${GREEN}Output file: $OUTPUT_FILE${NC}"
    fi
}

# Trap errors
trap 'print_error "An error occurred. Exiting..."; cleanup; exit 1' ERR

# Run main function
main "$@"
