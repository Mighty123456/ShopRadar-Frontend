# App Icon Setup Guide

To set up the ShopRadar app icon, you need to convert the SVG to PNG format first.

## Quick Steps:

1. **Convert SVG to PNG (1024x1024)**
   - Option A: Use online converter (e.g., https://convertio.co/svg-png/)
   - Option B: Use ImageMagick (if installed):
     ```bash
     magick shopradar_icon.svg -resize 1024x1024 shopradar_icon.png
     ```
   - Option C: Use Inkscape:
     ```bash
     inkscape shopradar_icon.svg --export-type=png --export-width=1024 --export-height=1024 --export-filename=shopradar_icon.png
     ```

2. **Place the PNG file**
   - Save the converted `shopradar_icon.png` file to:
   - `frontend_flutter/assets/images/shopradar_icon.png`

3. **Generate app icons**
   ```bash
   cd frontend_flutter
   flutter pub run flutter_launcher_icons
   ```

4. **For iOS (additional step)**
   - Open `ios/Runner.xcworkspace` in Xcode
   - Select Assets.xcassets > AppIcon
   - Verify the icons were generated correctly

## Current Configuration

The `pubspec.yaml` is already configured with:
- Android icons: ✓ Enabled
- iOS icons: ✓ Enabled  
- Adaptive icon background: #2979FF (ShopRadar blue)
- Icon file: `assets/images/shopradar_icon.png`

## Notes

- The SVG file is 1024x1024, which is the perfect size for conversion
- Android adaptive icons will use the blue background (#2979FF)
- All required icon sizes will be auto-generated from the 1024x1024 PNG

