# Fix Cloudinary Upload Preset Error

## The Error
```
Upload failed: {"error": {"message":"Upload preset not found"}}
```

## Solution: Create Upload Preset in Cloudinary Console

### Step 1: Go to Cloudinary Console
1. Open [Cloudinary Console](https://cloudinary.com/console)
2. Log in with your account
3. Select your cloud: `dm9oh76nw`

### Step 2: Create Upload Preset
1. Go to **Settings** → **Upload** → **Upload presets**
2. Click **"Add upload preset"**
3. Fill in the details:
   - **Preset name**: `shopradar_profiles`
   - **Signing Mode**: `Unsigned` (important for mobile apps)
   - **Folder**: `shopradar/profiles`
   - **Transformation**: 
     - Width: `400`
     - Height: `400`
     - Crop: `fill`
     - Gravity: `face`
     - Quality: `auto`
     - Format: `auto`

### Step 3: Save the Preset
1. Click **"Save"**
2. The preset `shopradar_profiles` will be created
3. This allows unsigned uploads from your mobile app

### Step 4: Test the Upload
1. Run your Flutter app
2. Go to Profile screen
3. Tap profile picture
4. Select "Take Photo" or "Choose from Gallery"
5. The upload should now work!

## Alternative: Use Signed Uploads (More Secure)

If you prefer signed uploads, update the upload method to include API credentials:

```dart
final response = await http.post(
  Uri.parse(uploadUrl),
  body: {
    'file': 'data:image/jpeg;base64,$base64Image',
    'public_id': publicId,
    'folder': 'shopradar/profiles',
    'api_key': CloudinaryConfig.apiKey,
    'api_secret': CloudinaryConfig.apiSecret,
    // Remove upload_preset for signed uploads
  },
);
```

## Troubleshooting

### If upload still fails:
1. **Check preset name**: Must be exactly `shopradar_profiles`
2. **Check signing mode**: Must be `Unsigned`
3. **Check folder**: Should be `shopradar/profiles`
4. **Check cloud name**: Must be `dm9oh76nw`

### Debug Steps:
1. Check Cloudinary console for upload logs
2. Verify the preset exists in Settings → Upload presets
3. Test with a simple image first
4. Check network connectivity

## Security Notes

- **Unsigned uploads** are easier but less secure
- **Signed uploads** require API credentials but are more secure
- For production, consider using your backend API for uploads
