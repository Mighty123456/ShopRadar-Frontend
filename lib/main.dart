import 'package:flutter/material.dart';
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

import 'package:google_fonts/google_fonts.dart';
import 'screens/onboarding_screen.dart';
import 'widgets/auth_wrapper.dart';
import 'utils/onboarding_utils.dart';
import 'services/network_utility.dart';

void main() {
  runApp(const ShopRadarApp());
}

class ShopRadarApp extends StatefulWidget {
  const ShopRadarApp({super.key});

  @override
  State<ShopRadarApp> createState() => _ShopRadarAppState();
}

class _ShopRadarAppState extends State<ShopRadarApp> {
  bool _showOnboarding = false;
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    _checkInitialState();
  }

  Future<void> _checkInitialState() async {
    debugPrint('Starting _checkInitialState');
    try {
      
      try {
        await NetworkUtility.initialize().timeout(
          const Duration(seconds: 15),
          onTimeout: () {
            debugPrint('Network initialization timed out, continuing with fallback');
            return;
          },
        );
        debugPrint('Network configuration initialized');
      } catch (e) {
        debugPrint('Network initialization failed, continuing with fallback: $e');
      }
      
      // Add timeout to onboarding check
      final onboardingCompleted = await OnboardingUtils.isOnboardingComplete().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          debugPrint('Onboarding check timed out, defaulting to show onboarding');
          return false;
        },
      );
      
      final isFirstTime = await OnboardingUtils.isFirstTime().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          debugPrint('First time check timed out, defaulting to true');
          return true;
        },
      );
      
      debugPrint('onboardingCompleted: $onboardingCompleted');
      debugPrint('isFirstTime: $isFirstTime');
      
      if (mounted) {
        setState(() {
        
          _showOnboarding = true;
          _isInitializing = false;
        });
      }
      debugPrint('🎯 Final decision - _showOnboarding: $_showOnboarding');
      debugPrint('🎯 onboardingCompleted value: $onboardingCompleted');
    } catch (e) {
      debugPrint('Error during initial state check: $e');
      if (mounted) {
        setState(() {
          _showOnboarding = true; 
          _isInitializing = false;
        });
      }
    }
  }



  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return const MaterialApp(
        home: Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
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
              // Mark onboarding as complete
              await OnboardingUtils.markOnboardingComplete();
              setState(() {
                _showOnboarding = false;
              });
            })
          : const AuthWrapper(),
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
        '/stores': (context) => const Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.store, size: 64, color: Color(0xFF2979FF)),
                SizedBox(height: 16),
                Text(
                  'Stores Screen',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text('Coming Soon!', style: TextStyle(fontSize: 16)),
              ],
            ),
          ),
        ),
        '/favorites': (context) => const Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.favorite, size: 64, color: Color(0xFF2979FF)),
                SizedBox(height: 16),
                Text(
                  'Favorites Screen',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text('Coming Soon!', style: TextStyle(fontSize: 16)),
              ],
            ),
          ),
        ),

      },
    );
  }
}
