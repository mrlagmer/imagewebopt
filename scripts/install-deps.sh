#!/bin/bash
# Install dependencies for image-optimizer skill

set -e

echo "Installing image optimization dependencies..."

# Detect package manager
if command -v apt-get &>/dev/null; then
    sudo apt-get update
    sudo apt-get install -y imagemagick jpegoptim pngquant webp bc
elif command -v dnf &>/dev/null; then
    sudo dnf install -y ImageMagick jpegoptim pngquant libwebp-tools bc
elif command -v yum &>/dev/null; then
    sudo yum install -y ImageMagick jpegoptim pngquant libwebp-tools bc
elif command -v pacman &>/dev/null; then
    sudo pacman -S --noconfirm imagemagick jpegoptim pngquant libwebp bc
elif command -v brew &>/dev/null; then
    brew install imagemagick jpegoptim pngquant webp
else
    echo "Error: Could not detect package manager."
    echo "Please install manually: imagemagick, jpegoptim, pngquant, webp"
    exit 1
fi

echo "Dependencies installed successfully!"

# Verify installation
echo ""
echo "Verifying installation:"
for cmd in convert jpegoptim pngquant cwebp; do
    if command -v "$cmd" &>/dev/null; then
        echo "  ✓ $cmd"
    else
        echo "  ✗ $cmd (not found)"
    fi
done
