#!/bin/bash
#
# imgopt - Optimize images for web (like Squoosh)
# Compresses JPEG, PNG, and optionally converts to WebP
#

set -e

# Default settings
QUALITY=80
MAX_WIDTH=0
MAX_HEIGHT=0
OUTPUT_DIR=""
WEBP=false
KEEP_ORIGINAL=false
RECURSIVE=false
DRY_RUN=false
VERBOSE=false

usage() {
    cat << EOF
Usage: imgopt [OPTIONS] <file|directory>...

Optimize images for web use. Supports JPEG, PNG, and WebP conversion.

Options:
  -q, --quality N      Quality level 1-100 (default: 80)
  -w, --max-width N    Maximum width in pixels (0 = no limit)
  -h, --max-height N   Maximum height in pixels (0 = no limit)
  -o, --output DIR     Output directory (default: overwrite in place)
  --webp               Also create WebP versions
  --keep               Keep original files (save optimized as .opt.ext)
  -r, --recursive      Process directories recursively
  -n, --dry-run        Show what would be done without doing it
  -v, --verbose        Show detailed progress
  --help               Show this help

Examples:
  imgopt image.jpg                  # Optimize single image
  imgopt -q 70 -w 1920 photos/      # Resize & compress folder
  imgopt --webp -r ./images         # Convert all to WebP recursively
  imgopt -o optimized/ *.png        # Output to different directory

Supported formats: JPEG, PNG, GIF, BMP, TIFF
EOF
    exit 0
}

error() {
    echo "Error: $1" >&2
    exit 1
}

log() {
    if [[ "$VERBOSE" == true ]]; then
        echo "$1"
    fi
}

# Check dependencies
check_deps() {
    local missing=()
    for cmd in convert jpegoptim pngquant cwebp; do
        if ! command -v "$cmd" &>/dev/null; then
            missing+=("$cmd")
        fi
    done
    if [[ ${#missing[@]} -gt 0 ]]; then
        error "Missing dependencies: ${missing[*]}\nInstall with: sudo apt-get install imagemagick jpegoptim pngquant webp"
    fi
}

# Get file size in human readable format
filesize() {
    local size=$(stat -c%s "$1" 2>/dev/null || echo 0)
    if [[ $size -ge 1048576 ]]; then
        echo "$(echo "scale=1; $size/1048576" | bc)MB"
    elif [[ $size -ge 1024 ]]; then
        echo "$(echo "scale=1; $size/1024" | bc)KB"
    else
        echo "${size}B"
    fi
}

# Get raw file size in bytes
filesize_bytes() {
    stat -c%s "$1" 2>/dev/null || echo 0
}

# Process a single image
process_image() {
    local input="$1"
    local ext="${input##*.}"
    local ext_lower=$(echo "$ext" | tr '[:upper:]' '[:lower:]')
    local basename="${input%.*}"
    local filename=$(basename "$input")
    local dir=$(dirname "$input")
    
    # Determine output path
    local output
    if [[ -n "$OUTPUT_DIR" ]]; then
        mkdir -p "$OUTPUT_DIR"
        if [[ "$KEEP_ORIGINAL" == true ]]; then
            output="$OUTPUT_DIR/${filename%.*}.opt.$ext"
        else
            output="$OUTPUT_DIR/$filename"
        fi
    elif [[ "$KEEP_ORIGINAL" == true ]]; then
        output="$basename.opt.$ext"
    else
        output="$input"
    fi
    
    local webp_output="${output%.*}.webp"
    if [[ -n "$OUTPUT_DIR" ]]; then
        webp_output="$OUTPUT_DIR/$(basename "${input%.*}").webp"
    fi
    
    local orig_size=$(filesize_bytes "$input")
    local orig_human=$(filesize "$input")
    
    if [[ "$DRY_RUN" == true ]]; then
        echo "[DRY-RUN] Would process: $input ($orig_human)"
        [[ "$WEBP" == true ]] && echo "[DRY-RUN] Would create WebP: $webp_output"
        return 0
    fi
    
    # Create temp file for processing
    local tmpfile=$(mktemp /tmp/imgopt.XXXXXX."$ext")
    trap "rm -f '$tmpfile'" EXIT
    
    # Resize if needed
    if [[ $MAX_WIDTH -gt 0 || $MAX_HEIGHT -gt 0 ]]; then
        local resize=""
        [[ $MAX_WIDTH -gt 0 ]] && resize="${MAX_WIDTH}"
        [[ $MAX_HEIGHT -gt 0 ]] && resize="${resize}x${MAX_HEIGHT}"
        [[ $MAX_WIDTH -gt 0 && $MAX_HEIGHT -eq 0 ]] && resize="${MAX_WIDTH}x"
        
        log "  Resizing to max ${resize}..."
        convert "$input" -resize "${resize}>" -quality "$QUALITY" "$tmpfile"
    else
        cp "$input" "$tmpfile"
    fi
    
    # Optimize based on format
    case "$ext_lower" in
        jpg|jpeg)
            log "  Optimizing JPEG..."
            jpegoptim --max="$QUALITY" --strip-all --quiet "$tmpfile"
            ;;
        png)
            log "  Optimizing PNG..."
            pngquant --quality="$((QUALITY-10))-$QUALITY" --force --ext .png "$tmpfile" 2>/dev/null || true
            ;;
        gif|bmp|tiff|tif)
            log "  Converting to optimized format..."
            convert "$tmpfile" -quality "$QUALITY" "$tmpfile"
            ;;
        *)
            log "  Skipping unsupported format: $ext"
            rm -f "$tmpfile"
            return 0
            ;;
    esac
    
    # Move to output
    cp "$tmpfile" "$output"
    rm -f "$tmpfile"
    
    local new_size=$(filesize_bytes "$output")
    local new_human=$(filesize "$output")
    local saved=$((orig_size - new_size))
    local percent=0
    [[ $orig_size -gt 0 ]] && percent=$((saved * 100 / orig_size))
    
    echo "✓ $input: $orig_human → $new_human (saved ${percent}%)"
    
    # Create WebP version if requested
    if [[ "$WEBP" == true ]]; then
        log "  Creating WebP version..."
        cwebp -q "$QUALITY" -quiet "$output" -o "$webp_output"
        local webp_size=$(filesize "$webp_output")
        echo "  → WebP: $webp_output ($webp_size)"
    fi
    
    # Track totals
    TOTAL_ORIG=$((TOTAL_ORIG + orig_size))
    TOTAL_NEW=$((TOTAL_NEW + new_size))
    TOTAL_FILES=$((TOTAL_FILES + 1))
}

# Find and process images
process_path() {
    local path="$1"
    
    if [[ -f "$path" ]]; then
        # Check if it's an image
        local ext="${path##*.}"
        local ext_lower=$(echo "$ext" | tr '[:upper:]' '[:lower:]')
        case "$ext_lower" in
            jpg|jpeg|png|gif|bmp|tiff|tif)
                process_image "$path"
                ;;
            *)
                log "Skipping non-image: $path"
                ;;
        esac
    elif [[ -d "$path" ]]; then
        local find_opts="-maxdepth 1"
        [[ "$RECURSIVE" == true ]] && find_opts=""
        
        while IFS= read -r -d '' file; do
            process_image "$file"
        done < <(find "$path" $find_opts -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" -o -iname "*.bmp" -o -iname "*.tiff" -o -iname "*.tif" \) -print0 2>/dev/null)
    else
        error "Path not found: $path"
    fi
}

# Parse arguments
FILES=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        -q|--quality)
            QUALITY="$2"
            shift 2
            ;;
        -w|--max-width)
            MAX_WIDTH="$2"
            shift 2
            ;;
        -h|--max-height)
            MAX_HEIGHT="$2"
            shift 2
            ;;
        -o|--output)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        --webp)
            WEBP=true
            shift
            ;;
        --keep)
            KEEP_ORIGINAL=true
            shift
            ;;
        -r|--recursive)
            RECURSIVE=true
            shift
            ;;
        -n|--dry-run)
            DRY_RUN=true
            shift
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        --help)
            usage
            ;;
        -*)
            error "Unknown option: $1"
            ;;
        *)
            FILES+=("$1")
            shift
            ;;
    esac
done

# Validate
[[ ${#FILES[@]} -eq 0 ]] && usage
[[ $QUALITY -lt 1 || $QUALITY -gt 100 ]] && error "Quality must be 1-100"

# Check dependencies
check_deps

# Track totals
TOTAL_ORIG=0
TOTAL_NEW=0
TOTAL_FILES=0

echo "Image Optimizer - Quality: $QUALITY"
[[ $MAX_WIDTH -gt 0 ]] && echo "Max width: ${MAX_WIDTH}px"
[[ $MAX_HEIGHT -gt 0 ]] && echo "Max height: ${MAX_HEIGHT}px"
[[ "$WEBP" == true ]] && echo "Creating WebP versions"
echo "---"

# Process all paths
for path in "${FILES[@]}"; do
    process_path "$path"
done

# Summary
if [[ $TOTAL_FILES -gt 0 && "$DRY_RUN" != true ]]; then
    echo "---"
    total_saved=$((TOTAL_ORIG - TOTAL_NEW))
    if [[ $TOTAL_ORIG -gt 0 ]]; then
        percent=$((total_saved * 100 / TOTAL_ORIG))
    else
        percent=0
    fi
    
    # Format sizes
    if [[ $TOTAL_ORIG -ge 1048576 ]]; then
        orig_fmt="$(echo "scale=2; $TOTAL_ORIG/1048576" | bc)MB"
    else
        orig_fmt="$(echo "scale=1; $TOTAL_ORIG/1024" | bc)KB"
    fi
    if [[ $TOTAL_NEW -ge 1048576 ]]; then
        new_fmt="$(echo "scale=2; $TOTAL_NEW/1048576" | bc)MB"
    else
        new_fmt="$(echo "scale=1; $TOTAL_NEW/1024" | bc)KB"
    fi
    if [[ $total_saved -ge 1048576 ]]; then
        saved_fmt="$(echo "scale=2; $total_saved/1048576" | bc)MB"
    else
        saved_fmt="$(echo "scale=1; $total_saved/1024" | bc)KB"
    fi
    
    echo "Processed $TOTAL_FILES files"
    echo "Total: $orig_fmt → $new_fmt (saved $saved_fmt / ${percent}%)"
fi
