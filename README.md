# Image Web Optimizer

A powerful command-line tool to optimize and compress images for web use. Reduces file sizes of JPEG, PNG, and GIF images using lossy/lossless compression, with support for resizing, WebP conversion, and batch processing.

## 🚀 Features

- **Smart Compression**: Optimize JPEG, PNG, GIF, BMP, and TIFF images
- **WebP Support**: Convert images to modern WebP format for better compression
- **Batch Processing**: Process entire directories recursively
- **Flexible Resizing**: Set maximum width/height while preserving aspect ratio
- **Safe Operations**: Dry-run mode and option to keep originals
- **Cross-Platform**: Works on Linux, macOS, and other Unix-like systems

## 📋 Prerequisites

The following packages are required:
- `imagemagick` - Image resizing and conversion
- `jpegoptim` - JPEG optimization
- `pngquant` - PNG compression
- `webp` - WebP format support
- `bc` - Math calculations (usually pre-installed)

## 🔧 Installation

### Quick Install (Recommended)

Run the installation script to automatically detect and install dependencies:

```bash
./scripts/install-deps.sh
```

### Manual Installation

**Ubuntu/Debian:**
```bash
sudo apt-get update
sudo apt-get install -y imagemagick jpegoptim pngquant webp bc
```

**macOS (Homebrew):**
```bash
brew install imagemagick jpegoptim pngquant webp
```

**Fedora:**
```bash
sudo dnf install -y ImageMagick jpegoptim pngquant libwebp-tools bc
```

**Arch Linux:**
```bash
sudo pacman -S imagemagick jpegoptim pngquant libwebp bc
```

## 🎯 Quick Start

### Optimize a Single Image
```bash
./scripts/imgopt.sh photo.jpg
```

### Compress All Images in a Folder
```bash
./scripts/imgopt.sh images/
```

### Resize and Compress for Web (Recommended)
```bash
./scripts/imgopt.sh -q 80 -w 1920 images/
```

### Create WebP Versions
```bash
./scripts/imgopt.sh --webp images/
```

### Process Recursively and Keep Originals
```bash
./scripts/imgopt.sh -r --keep --webp ./website/images/
```

### Output to Different Directory
```bash
./scripts/imgopt.sh -o optimized/ *.jpg *.png
```

### Preview Changes (Dry Run)
```bash
./scripts/imgopt.sh -n -r images/
```

## 📖 Usage

```bash
./scripts/imgopt.sh [OPTIONS] <files or directories>
```

### Options

| Option | Description | Default |
|--------|-------------|---------|
| `-q, --quality N` | Quality level 1-100 | 80 |
| `-w, --max-width N` | Maximum width in pixels | unlimited |
| `-h, --max-height N` | Maximum height in pixels | unlimited |
| `-o, --output DIR` | Output directory | in-place |
| `--webp` | Also create WebP versions | off |
| `--keep` | Keep originals (save as .opt.ext) | off |
| `-r, --recursive` | Process directories recursively | off |
| `-n, --dry-run` | Show what would be done | off |
| `-v, --verbose` | Show detailed progress | off |
| `--help` | Display help message | - |

## 📁 Supported Formats

- **Input**: JPEG (.jpg, .jpeg), PNG (.png), GIF (.gif), BMP (.bmp), TIFF (.tif, .tiff)
- **Output**: Same format (optimized) + optional WebP (.webp)

## 🎨 Recommended Settings by Use Case

| Use Case | Command | Notes |
|----------|---------|-------|
| **Blog Images** | `-q 80 -w 1200 --webp` | Good balance of quality and size |
| **Hero/Banner Images** | `-q 85 -w 1920 --webp` | Higher quality for large visuals |
| **Thumbnails** | `-q 75 -w 400` | Smaller size for preview images |
| **E-commerce Products** | `-q 85 -w 1000 --webp` | High quality for product display |
| **Maximum Compression** | `-q 60 -w 1920 --webp` | Best compression, some quality loss |

## 💡 Tips and Best Practices

1. **Always Test First**: Use `--keep` or `-o output/` to test on copies before replacing originals
2. **WebP for Modern Web**: WebP typically produces files 25-35% smaller than optimized JPEG
3. **Quality Sweet Spot**: Quality 80 is a good default; below 70 may show visible artifacts
4. **Resizing Matters Most**: Resizing large images (e.g., 4000px -> 1920px) provides the biggest file size reduction
5. **Use Dry Run**: Always preview with `-n` flag when processing many files
6. **Batch Processing**: Combine recursive mode (`-r`) with dry run for safe batch operations

## 📊 Performance Examples

Typical results when optimizing a folder of 50 photos (original total: 150MB):

| Settings | Result | Reduction | Time |
|----------|--------|-----------|------|
| Default (q80) | 45MB | 70% | ~30s |
| q80 + resize 1920 | 12MB | 92% | ~45s |
| q80 + resize 1920 + webp | 8MB | 95% | ~60s |

## 🌐 Using WebP with Fallback

For maximum browser compatibility, use the HTML `<picture>` element:

```html
<picture>
  <source srcset="image.webp" type="image/webp">
  <source srcset="image.jpg" type="image/jpeg">
  <img src="image.jpg" alt="Description">
</picture>
```

## 🔍 Technical Details

- **JPEG Optimization**: Uses jpegoptim with Huffman table optimization (typical savings: 20-60%)
- **PNG Compression**: Uses pngquant with lossy quantization (typical savings: 50-80%)
- **WebP Conversion**: Uses cwebp with VP8 lossy compression (typically 25-35% better than JPEG)
- **Resizing**: Uses ImageMagick with Lanczos resampling (preserves aspect ratio)

*Note: Actual compression results vary based on source image characteristics, original quality, and chosen settings.*

For more technical information, see [references/REFERENCE.md](references/REFERENCE.md).

## 🐛 Troubleshooting

### Colors Look Wrong After Optimization
Try increasing quality (`-q 90`) or check if the source has an embedded color profile.

### WebP Files Larger Than JPEG
This can happen with already heavily compressed JPEGs. WebP works best with uncompressed or lightly compressed sources.

### Script is Slow on Many Files
Processing is single-threaded. For thousands of files, consider using GNU parallel:
```bash
find . -name '*.jpg' | parallel -j4 ./scripts/imgopt.sh {}
```

### "pngquant: error" on Some PNGs
Some PNGs with unusual color profiles may fail. The script will continue processing other files.

## 📄 License

MIT License - See the project metadata for details.

## 👤 Author

Created by exedev

## 🔗 Additional Resources

- [SKILL.md](SKILL.md) - Agent skill documentation
- [references/REFERENCE.md](references/REFERENCE.md) - Detailed technical reference
- [ImageMagick Documentation](https://imagemagick.org/)
- [WebP Documentation](https://developers.google.com/speed/webp)

---

**Note**: This tool is designed to work as an agent skill for automated image optimization workflows.
