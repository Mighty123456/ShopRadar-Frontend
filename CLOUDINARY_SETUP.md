# Cloudinary Setup Guide

## 1. Get Cloudinary Credentials

1. Go to [Cloudinary Console](https://cloudinary.com/console)
2. Sign up or log in to your account
3. From the dashboard, copy your credentials:
   - **Cloud Name** (e.g., `dxyz123`)
   - **API Key** (e.g., `123456789012345`)
   - **API Secret** (e.g., `abcdefghijklmnopqrstuvwxyz123456`)

## 2. Update Configuration

Edit `lib/config/cloudinary_config.dart`:

```dart
class CloudinaryConfig {
  static const String cloudName = 'your_actual_cloud_name'; // Replace this
  static const String apiKey = 'your_actual_api_key'; // Replace this  
  static const String apiSecret = 'your_actual_api_secret'; // Replace this
}
```

## 3. Add Dependencies

Add to `pubspec.yaml`:

```yaml
dependencies:
  cloudinary_flutter: ^1.0.0
```

Then run:
```bash
flutter pub get
```

## 4. Security Notes

### For Development:
- ✅ Hardcode credentials in config file (as shown above)

### For Production:
- 🔒 Use environment variables
- 🔒 Use secure storage (Flutter Secure Storage)
- 🔒 Use backend API for uploads (recommended)

## 5. Environment Variables (Production)

Create `.env` file:
```
CLOUDINARY_CLOUD_NAME=your_cloud_name
CLOUDINARY_API_KEY=your_api_key
CLOUDINARY_API_SECRET=your_api_secret
```

## 6. Test Upload

1. Run the app
2. Go to Profile screen
3. Tap profile picture
4. Select "Take Photo" or "Choose from Gallery"
5. Check Cloudinary console to see uploaded image

## 7. Troubleshooting

### Common Issues:
- **"Invalid credentials"**: Check your API key and secret
- **"Cloud name not found"**: Verify your cloud name
- **"Upload failed"**: Check internet connection and permissions

### Debug Steps:
1. Check console logs for error messages
2. Verify credentials in Cloudinary dashboard
3. Test with a simple image first
4. Check network connectivity

## 8. Production Recommendations

1. **Use Backend API**: Don't expose API secret in mobile app
2. **Signed Uploads**: Use upload presets for security
3. **Rate Limiting**: Implement upload limits
4. **Image Validation**: Validate file types and sizes
5. **Error Handling**: Implement proper error recovery

## 9. Cloudinary Dashboard

Monitor your usage at:
- [Cloudinary Console](https://cloudinary.com/console)
- View uploaded images
- Check storage usage
- Monitor API calls
- Set up webhooks

## 10. Support

- [Cloudinary Documentation](https://cloudinary.com/documentation)
- [Flutter Cloudinary Package](https://pub.dev/packages/cloudinary_flutter)
- [Cloudinary Support](https://support.cloudinary.com/)
