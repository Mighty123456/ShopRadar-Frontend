import 'package:flutter/material.dart';
import 'services/network_config.dart';
import 'screens/auth_screen.dart';
import 'screens/otp_verification_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/reset_password_screen.dart';
import 'screens/home_screen.dart';
import 'screens/auth_success_screen.dart';
import 'screens/verification_success_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/change_password_screen.dart';
import 'screens/shop_owner_dashboard.dart';
import 'screens/map_screen_free.dart';
import 'screens/shop_details_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/shop_comparison_screen.dart';
import 'screens/favorites_screen.dart';
import 'screens/stores_screen.dart';

import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'widgets/auth_wrapper.dart';
import 'widgets/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/search_results_screen.dart';
import 'services/realtime_service.dart';
import 'debug/voice_search_debug.dart';

Future<void> main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  // Use physical device environment and set the hosted backend URL explicitly
  NetworkConfig.setEnvironment(NetworkConfig.physicalDevice);
  NetworkConfig.setPhysicalDeviceBaseUrl('https://shopradarbackend-ob4u.onrender.com');
  runApp(const ShopRadarApp());
  NetworkConfig.refreshNetworkConfig();
}

class ShopRadarApp extends StatefulWidget {
  const ShopRadarApp({super.key});

  @override
  State<ShopRadarApp> createState() => _ShopRadarAppState();
}

class _ShopRadarAppState extends State<ShopRadarApp> {      
  bool _showOnboarding = false;
  bool _isInitializing = true;
  bool _showSplashBeforeOnboarding = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    debugPrint('🚀 Starting app initialization...');
    
    // Show splash screen for 3 seconds
    await Future.delayed(const Duration(seconds: 3));
    
    debugPrint('✅ Initial splash screen duration complete');
    
    if (mounted) {
      setState(() {
        _showSplashBeforeOnboarding = true; // Show splash before onboarding
        _isInitializing = false;
      });
      
      // Remove native splash screen
      FlutterNativeSplash.remove();
      
      // Initialize realtime service in background
      RealtimeService().initialize();

      // Show splash screen before onboarding for 2 more seconds
      await Future.delayed(const Duration(seconds: 2));
      
      if (mounted) {
        setState(() {
          _showSplashBeforeOnboarding = false;
          _showOnboarding = true; // Now show onboarding
        });
        debugPrint('🎯 App ready! Showing onboarding');
      }
    }
  }



  @override
  Widget build(BuildContext context) {
    
    if (_isInitializing || _showSplashBeforeOnboarding) {
      debugPrint('📱 Showing animated splash screen');
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: SplashScreen(
          message: _isInitializing ? 'Initializing ShopRadar...' : 'Preparing your experience...',
          duration: const Duration(seconds: 3),
        ),
      );
    }
    return MaterialApp(
      title: 'ShopRadar',
      debugShowCheckedModeBanner: false,
       theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: const ColorScheme(
          brightness: Brightness.light,
          primary: Color(0xFF2979FF),
          onPrimary: Colors.white,
          secondary: Color(0xFF2DD4BF),
          onSecondary: Colors.white,
          surface: Color(0xFFF7F8FA),
          onSurface: Color(0xFF232136),
          error: Color(0xFFF44336),
          onError: Colors.white,
        ),
        textTheme: GoogleFonts.poppinsTextTheme(),
      ),
      home: _showOnboarding
          ? OnboardingScreen(onFinish: () async {
              debugPrint('🎯 Onboarding finished, showing splash before auth');
              
              // Show splash screen before going to auth
              setState(() {
                _showOnboarding = false;
                _showSplashBeforeOnboarding = true;
              });
              
              // Wait for splash screen duration
              await Future.delayed(const Duration(seconds: 2));
              
              if (mounted) {
                setState(() {
                  _showSplashBeforeOnboarding = false;
                });
                debugPrint('🎯 Now showing auth screen');
              }
            })
          : Builder(
              builder: (context) {
                debugPrint('🎯 Showing AuthWrapper');
                return const AuthWrapper();
              },
            ),
      routes: {
        '/auth': (context) => const AuthScreen(),
        '/otp-verification': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
          return OTPVerificationScreen(
            email: args?['email'] ?? '',
            userId: args?['userId'] ?? '',
          );
        },
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/reset-password': (context) {
          final email = ModalRoute.of(context)!.settings.arguments as String? ?? '';
          return ResetPasswordScreen(email: email);
        },
        '/home': (context) => const HomeScreen(),
        '/auth-success': (context) => const AuthSuccessScreen(),
        '/verification-success': (context) => const VerificationSuccessScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/change-password': (context) => const ChangePasswordScreen(),
        '/shop-owner-dashboard': (context) => const ShopOwnerDashboard(),
        '/map': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
          return MapScreenFree(
            searchQuery: args?['searchQuery'],
            category: args?['category'],
            shopsOverride: args?['shops'],
          );
        },
        '/search-results': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
          final String query = args?['query'] ?? '';
          return SearchResultsScreen(query: query);
        },
        '/shop-details': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
          return ShopDetailsScreen(shop: args?['shop']);
        },
        '/notifications': (context) => const NotificationsScreen(),
        '/shop-comparison': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
          return ShopComparisonScreen(shops: args?['shops'] ?? []);
        },
        '/stores': (context) => const StoresScreen(),
        '/favorites': (context) => const FavoritesScreen(),
        '/voice-debug': (context) => const VoiceSearchDebugScreen(),

      },
    );
  }
}
