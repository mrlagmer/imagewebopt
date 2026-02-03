# Image Optimizer Technical Reference

## How It Works

The image optimizer uses a pipeline of specialized tools for each format:

### JPEG Optimization
- **Tool**: jpegoptim
- **Method**: Huffman table optimization + optional quality reduction
- **Typical savings**: 20-60%
- Strips EXIF metadata by default

### PNG Optimization  
- **Tool**: pngquant
- **Method**: Lossy quantization (reduces color palette)
- **Typical savings**: 50-80%
- Converts 24-bit PNG to 8-bit with alpha channel preserved

### WebP Conversion
- **Tool**: cwebp (from libwebp)
- **Method**: VP8 lossy compression
- **Typical savings**: 25-35% smaller than optimized JPEG
- Excellent browser support (95%+ as of 2024)

### Resizing
- **Tool**: ImageMagick (convert)
- **Method**: Lanczos resampling
- Only downscales (never upscales)
- Preserves aspect ratio

## Quality Guidelines

| Quality | Use Case | Notes |
|---------|----------|-------|
| 90-100 | Photography portfolios | Minimal loss, large files |
| 80-89 | General web images | Good balance |
| 70-79 | Thumbnails, backgrounds | Noticeable on close inspection |
| 60-69 | Maximum compression | Visible artifacts |
| <60 | Not recommended | Severe quality loss |

## Format Comparison

| Format | Best For | Browser Support | Transparency |
|--------|----------|-----------------|-------------|
| JPEG | Photos | Universal | No |
| PNG | Graphics, screenshots | Universal | Yes |
| WebP | Everything (modern) | 95%+ | Yes |
| AVIF | Future-proofing | ~75% | Yes |

## Serving WebP with Fallback

Use the HTML `<picture>` element:

```html
<picture>
  <source srcset="image.webp" type="image/webp">
  <source srcset="image.jpg" type="image/jpeg">
  <img src="image.jpg" alt="Description">
</picture>
```

Or use server-side content negotiation with the `Accept` header.

## Performance Benchmarks

Typical results on a folder of 50 photos (original total: 150MB):

| Settings | Result | Time |
|----------|--------|------|
| Default (q80) | 45MB (70% reduction) | ~30s |
| q80 + resize 1920 | 12MB (92% reduction) | ~45s |
| q80 + resize 1920 + webp | 8MB (95% reduction) | ~60s |

## Troubleshooting

### "pngquant: error" on some PNGs
Some PNGs with unusual color profiles may fail. The script continues processing other files.

### Colors look wrong after optimization
Try increasing quality (`-q 90`) or check if the source has an embedded color profile.

### WebP files are larger than JPEG
This can happen with already heavily compressed JPEGs. WebP shines with uncompressed or lightly compressed sources.

### Script is slow on many files
Processing is single-threaded. For thousands of files, consider using GNU parallel:
```bash
find . -name '*.jpg' | parallel -j4 imgopt.sh {}
```

## Dependencies

| Package | Debian/Ubuntu | macOS (Homebrew) | Purpose |
|---------|---------------|------------------|--------|
| imagemagick | imagemagick | imagemagick | Resizing |
| jpegoptim | jpegoptim | jpegoptim | JPEG optimization |
| pngquant | pngquant | pngquant | PNG optimization |
| webp | webp | webp | WebP conversion |
| bc | bc | built-in | Math calculations |
