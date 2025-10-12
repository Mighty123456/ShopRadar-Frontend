# Google Sign-In Configuration Guide

## Complete Setup for ShopRadar App

### Step 1: Create Google Cloud Project

1. **Go to Google Cloud Console**
   - Visit: https://console.cloud.google.com/
   - Sign in with your Google account

2. **Create New Project**
   - Click "Select a project" → "New Project"
   - Project name: `ShopRadar` (or your preferred name)
   - Click "Create"

3. **Enable APIs**
   - Go to "APIs & Services" → "Library"
   - Search for "Google Sign-In API" and enable it
   - Also enable "Google+ API" if available

### Step 2: Configure OAuth 2.0 Credentials

1. **Go to Credentials**
   - Navigate to "APIs & Services" → "Credentials"
   - Click "Create Credentials" → "OAuth 2.0 Client IDs"

2. **Configure OAuth Consent Screen**
   - Click "Configure Consent Screen"
   - Choose "External" (unless you have Google Workspace)
   - Fill in required fields:
     - App name: `ShopRadar`
     - User support email: Your email
     - Developer contact: Your email
   - Click "Save and Continue"
   - Add scopes: `email`, `profile`, `openid`
   - Click "Save and Continue"
   - Add test users (your email) if needed
   - Click "Save and Continue"

3. **Create Android OAuth Client**
   - Click "Create Credentials" → "OAuth 2.0 Client IDs"
   - Application type: **Android**
   - Name: `ShopRadar Android`
   - Package name: `com.example.frontend_flutter`
   - SHA-1 certificate fingerprint: (Get this in next step)

### Step 3: Get SHA-1 Fingerprint

#### For Debug Build (Development):
```bash
# Navigate to your Flutter project
cd "D:\Program Files\ShopRadar\frontend_flutter"

# Run this command to get SHA-1
keytool -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
```

#### For Release Build (Production):
```bash
# If you have a release keystore
keytool -list -v -keystore path/to/your/release.keystore -alias your-alias
```

**Copy the SHA-1 fingerprint** (it looks like: `AA:BB:CC:DD:EE:FF:00:11:22:33:44:55:66:77:88:99:AA:BB:CC:DD`)

### Step 4: Complete OAuth Client Setup

1. **Paste SHA-1 fingerprint** in the OAuth client form
2. **Click "Create"**
3. **Copy the Client ID** (you'll need this)

### Step 5: Create Web OAuth Client (for Backend)

1. **Create another OAuth Client**
   - Application type: **Web application**
   - Name: `ShopRadar Web`
   - Authorized redirect URIs: `http://localhost:3000` (for development)
2. **Click "Create"**
3. **Copy both Client ID and Client Secret**

### Step 6: Update google-services.json

Replace the content in `android/app/google-services.json`:

```json
{
  "project_info": {
    "project_number": "YOUR_PROJECT_NUMBER",
    "project_id": "your-actual-project-id",
    "storage_bucket": "your-actual-project-id.appspot.com"
  },
  "client": [
    {
      "client_info": {
        "mobilesdk_app_id": "1:YOUR_PROJECT_NUMBER:android:YOUR_APP_ID",
        "android_client_info": {
          "package_name": "com.example.frontend_flutter"
        }
      },
      "oauth_client": [
        {
          "client_id": "YOUR_ANDROID_CLIENT_ID.apps.googleusercontent.com",
          "client_type": 3
        }
      ],
      "api_key": [
        {
          "current_key": "YOUR_API_KEY"
        }
      ],
      "services": {
        "appinvite_service": {
          "other_platform_oauth_client": [
            {
              "client_id": "YOUR_WEB_CLIENT_ID.apps.googleusercontent.com",
              "client_type": 3
            }
          ]
        }
      }
    }
  ],
  "configuration_version": "1"
}
```

**Replace these values:**
- `YOUR_PROJECT_NUMBER`: From Google Cloud Console
- `your-actual-project-id`: Your project ID
- `YOUR_APP_ID`: Generated app ID
- `YOUR_ANDROID_CLIENT_ID`: Android OAuth client ID
- `YOUR_API_KEY`: API key from Google Cloud
- `YOUR_WEB_CLIENT_ID`: Web OAuth client ID

### Step 7: Update Backend Environment

Add to your backend `.env` file:

```env
# Google OAuth Configuration
GOOGLE_CLIENT_ID=your-web-client-id.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=your-web-client-secret
```

### Step 8: Update Package Name (Important!)

Your current package name is `com.example.frontend_flutter`. You should change it to something unique:

1. **Update android/app/build.gradle**:
```gradle
android {
    defaultConfig {
        applicationId "com.shopradar.app"  // Change this
        // ... other config
    }
}
```

2. **Update package name in google-services.json**:
```json
"package_name": "com.shopradar.app"
```

3. **Update OAuth client** in Google Cloud Console with new package name

### Step 9: Test the Configuration

1. **Clean and rebuild**:
```bash
cd "D:\Program Files\ShopRadar\frontend_flutter"
flutter clean
flutter pub get
```

2. **Run the app**:
```bash
flutter run
```

3. **Test Google Sign-In**:
   - Tap "Continue with Google"
   - Should open Google sign-in flow
   - After successful sign-in, should authenticate with your backend

### Step 10: Troubleshooting

#### Common Issues:

1. **"Sign in failed" error**:
   - Check SHA-1 fingerprint matches
   - Verify package name is correct
   - Ensure OAuth client is configured for Android

2. **"Invalid client" error**:
   - Check Client ID is correct
   - Verify OAuth consent screen is configured
   - Ensure APIs are enabled

3. **"Network error"**:
   - Check internet connection
   - Verify backend is running
   - Check backend environment variables

#### Debug Steps:

1. **Check Flutter logs**:
```bash
flutter logs
```

2. **Check backend logs** for authentication errors

3. **Verify google-services.json** is in correct location: `android/app/`

4. **Test with different Google accounts**

### Step 11: Production Setup

For production release:

1. **Create release keystore**:
```bash
keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

2. **Get release SHA-1**:
```bash
keytool -list -v -keystore ~/upload-keystore.jks -alias upload
```

3. **Add release SHA-1** to Google Cloud Console OAuth client

4. **Update backend environment** with production URLs

### Quick Checklist ✅

- [ ] Google Cloud project created
- [ ] OAuth consent screen configured
- [ ] Android OAuth client created with correct SHA-1
- [ ] Web OAuth client created for backend
- [ ] google-services.json updated with real values
- [ ] Backend environment variables set
- [ ] Package name updated (recommended)
- [ ] App tested and working

### Need Help?

If you encounter issues:

1. **Check the Flutter logs** for specific error messages
2. **Verify all IDs and keys** are correctly copied
3. **Ensure package name** matches everywhere
4. **Test with a simple Google account** first

Once configured, Google Sign-In will work seamlessly with your ShopRadar app! 🚀
