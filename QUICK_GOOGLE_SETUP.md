# Quick Google Sign-In Setup

## Essential Steps Only

### 1. Your SHA-1 Fingerprint ✅
**Your SHA-1 fingerprint is:**
```
22:93:8A:B3:02:9A:D8:CD:19:CB:05:50:0F:4F:EF:62:5B:B5:3F:A2
```
**Copy this fingerprint for the next step**

### 2. Google Cloud Console Setup
1. Go to: https://console.cloud.google.com/
2. Create project: `ShopRadar`
3. Enable: Google Sign-In API
4. Create OAuth client:
   - Type: Android
   - Package: `com.example.frontend_flutter`
   - SHA-1: `22:93:8A:B3:02:9A:D8:CD:19:CB:05:50:0F:4F:EF:62:5B:B5:3F:A2`
5. Create Web OAuth client:
   - Type: Web application
   - Redirect: `http://localhost:3000`

### 3. Update Files

**android/app/google-services.json** - Replace with real values:
```json
{
  "project_info": {
    "project_number": "YOUR_PROJECT_NUMBER",
    "project_id": "your-project-id"
  },
  "client": [{
    "client_info": {
      "mobilesdk_app_id": "1:YOUR_PROJECT_NUMBER:android:YOUR_APP_ID",
      "android_client_info": {
        "package_name": "com.example.frontend_flutter"
      }
    },
    "oauth_client": [{
      "client_id": "YOUR_ANDROID_CLIENT_ID.apps.googleusercontent.com",
      "client_type": 3
    }],
    "api_key": [{
      "current_key": "YOUR_API_KEY"
    }]
  }]
}
```

**Backend .env file**:
```env
GOOGLE_CLIENT_ID=your-web-client-id.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=your-web-client-secret
```

### 4. Test
```bash
flutter clean
flutter pub get
flutter run
```

## That's it! 🎉

For detailed instructions, see: `GOOGLE_SIGNIN_SETUP.md`
