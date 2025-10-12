# Voice Search Troubleshooting Guide

## Issue: Microphone Interface Not Appearing

If the microphone interface is not appearing when you click the voice search icon, follow these troubleshooting steps:

### 🔍 **Step 1: Check Debug Information**

Navigate to the debug screen to see detailed information:
```
/voice-debug
```

This will show you:
- Microphone permission status
- Speech recognition availability
- Current listening state
- Error messages

### 🔧 **Step 2: Common Issues & Solutions**

#### **Issue 1: Permission Denied**
**Symptoms:** Button appears disabled or shows "Voice search not available"
**Solution:**
1. Go to device Settings > Apps > ShopRadar > Permissions
2. Enable Microphone permission
3. Restart the app

#### **Issue 2: Speech Recognition Not Available**
**Symptoms:** Debug screen shows "Speech recognition available: false"
**Solution:**
1. Check if your device supports speech recognition
2. Ensure you have an active internet connection
3. Try on a different device/emulator

#### **Issue 3: Initialization Failed**
**Symptoms:** Button shows loading spinner indefinitely
**Solution:**
1. Force close and restart the app
2. Check device storage space
3. Update the app to latest version

### 🛠️ **Step 3: Manual Testing**

#### **Test 1: Permission Check**
```dart
// Add this to your debug code
final permission = await Permission.microphone.status;
print('Microphone permission: $permission');
```

#### **Test 2: Direct Service Test**
```dart
// Test voice search service directly
final isAvailable = await VoiceSearchService.isAvailable();
print('Voice search available: $isAvailable');
```

#### **Test 3: Manual Initialization**
```dart
// Force reinitialize
await VoiceSearchService.initialize();
```

### 📱 **Step 4: Platform-Specific Issues**

#### **Android Issues:**
1. **Target SDK Version:** Ensure your app targets API 23+ for runtime permissions
2. **Emulator Issues:** Some emulators don't support speech recognition
3. **Device Compatibility:** Older devices may not support speech recognition

#### **iOS Issues:**
1. **Simulator Limitations:** Speech recognition may not work in iOS Simulator
2. **Privacy Settings:** Check Settings > Privacy > Microphone
3. **App Store Review:** Speech recognition requires specific privacy descriptions

### 🔄 **Step 5: Reset and Retry**

If all else fails:

1. **Clear App Data:**
   ```bash
   flutter clean
   flutter pub get
   ```

2. **Reinstall App:**
   - Uninstall the app completely
   - Reinstall from your development environment

3. **Check Dependencies:**
   ```bash
   flutter pub deps
   ```

### 🐛 **Step 6: Debug Logging**

Enable detailed logging to see what's happening:

```dart
// In your voice search service
debugPrint('Initializing voice search service...');
debugPrint('Microphone permission status: $permissionStatus');
debugPrint('Speech recognition available: $available');
```

### 📋 **Step 7: Expected Behavior**

When working correctly, you should see:

1. **Button States:**
   - Gray microphone icon (not initialized)
   - Loading spinner (initializing)
   - Blue microphone icon (ready)
   - Red pulsing microphone (listening)

2. **User Feedback:**
   - Permission request dialog
   - "Listening..." status
   - Success/error messages
   - Recognized text in search field

### 🚨 **Step 8: Emergency Fallback**

If voice search continues to fail, you can:

1. **Disable Voice Search Temporarily:**
   ```dart
   // In voice_search_button.dart
   onPressed: null, // Disable the button
   ```

2. **Show Alternative UI:**
   ```dart
   // Show text input instead
   IconButton(
     onPressed: () => _showTextInputDialog(),
     icon: Icon(Icons.keyboard),
   )
   ```

### 📞 **Step 9: Get Help**

If the issue persists:

1. **Check Flutter Version:**
   ```bash
   flutter --version
   ```

2. **Check Device Logs:**
   ```bash
   flutter logs
   ```

3. **Test on Different Devices:**
   - Try on physical device vs emulator
   - Test on different Android/iOS versions

### ✅ **Success Indicators**

Voice search is working when you see:
- ✅ Microphone permission granted
- ✅ Speech recognition available: true
- ✅ Button becomes interactive
- ✅ Visual feedback during listening
- ✅ Recognized text appears in search field

### 🔧 **Quick Fixes**

**Most Common Solutions:**
1. Grant microphone permission
2. Restart the app
3. Test on physical device
4. Check internet connection
5. Update Flutter dependencies

Remember: Voice search requires microphone permission and may not work in all emulators. Always test on a physical device for best results.
