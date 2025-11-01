# Minimal Loader Migration Guide

## Overview
The app now uses a consistent minimalist blue curved line loader (`MinimalLoader`) throughout the application. This replaces all `CircularProgressIndicator` instances for a more cohesive and modern look.

## Usage

### Basic Usage
```dart
import '../widgets/minimal_loader.dart';

// Simple loader
const MinimalLoader()

// Custom size
const MinimalLoader(size: 50)

// With message
MinimalLoader(
  size: 40,
  message: 'Loading...',
)

// Custom color
MinimalLoader(
  color: Colors.orange,
  strokeWidth: 3.5,
)
```

### Inline Loader (for small spaces)
```dart
import '../widgets/minimal_loader.dart';

// Small inline loader
const MinimalLoaderInline(size: 24)
```

### Full Screen Overlay
```dart
import '../widgets/minimal_loader.dart';

MinimalLoadingOverlay(
  isLoading: _isLoading,
  message: 'Loading data...',
  child: YourContentWidget(),
)
```

## Migration Pattern

### Replace this:
```dart
CircularProgressIndicator()
```

### With this:
```dart
const MinimalLoader()
```

### Replace this:
```dart
CircularProgressIndicator(
  strokeWidth: 4,
  valueColor: AlwaysStoppedAnimation(Color(0xFF2979FF)),
)
```

### With this:
```dart
MinimalLoader(
  size: 48,
  strokeWidth: 4,
)
```

## Files Updated
- ✅ `lib/widgets/loading_widget.dart` - Added MinimalLoader
- ✅ `lib/widgets/minimal_loader.dart` - New standalone loader widget
- ✅ `lib/screens/home_screen.dart` - Replaced CircularProgressIndicator
- ✅ `lib/screens/stores_screen.dart` - Replaced CircularProgressIndicator  
- ✅ `lib/screens/search_results_screen.dart` - Replaced CircularProgressIndicator

## Files Still Needing Update
- `lib/screens/shop_details_screen.dart` (2 instances)
- `lib/screens/category_products_screen.dart` (2 instances)
- `lib/screens/hierarchical_product_screen.dart` (2 instances)
- `lib/screens/product_management_screen.dart` (3 instances)
- `lib/screens/profile_screen.dart` (2 instances)
- `lib/widgets/voice_search_button.dart` (1 instance)

## Quick Replace Command
Use your IDE's find and replace:
- Find: `CircularProgressIndicator()`
- Replace: `MinimalLoader()`
- Don't forget to add: `import '../widgets/minimal_loader.dart';`

