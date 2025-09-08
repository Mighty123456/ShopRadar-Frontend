import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import '../widgets/social_login_buttons.dart';
import '../widgets/role_selector.dart';
import '../services/auth_service.dart';
import '../services/location_service.dart';
import '../widgets/animated_message_dialog.dart';
import '../models/user_model.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:geolocator/geolocator.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  bool isSignIn = true;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void toggleAuthMode() {
    setState(() {
      isSignIn = !isSignIn;
      if (isSignIn) {
        _controller.reverse();
      } else {
        _controller.forward();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 800),
              child: Container(
                key: ValueKey(isDark ? 'dark' : 'light'),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                      Color(0xFFF7F8FA),
                      Color(0xFFFFFFFF),
                    ],
                        ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                double maxWidth = constraints.maxWidth < 600 ? constraints.maxWidth : 420;
                double horizontalPadding = constraints.maxWidth < 600 ? 16.0 : (constraints.maxWidth - maxWidth) / 2;
                return Center(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 32.0),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: maxWidth),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Hero(
                              tag: 'logo',
                              child: Text(
                                'SHOPRADAR',
                                style: GoogleFonts.poppins(
                                  fontSize: 44,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF2979FF),
                                  letterSpacing: 5,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black12,
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 36),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(28),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.06),
                                    blurRadius: 24,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
                              child: Column(
                                children: [
                                    Container(
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF7F8FA),
                                        borderRadius: BorderRadius.circular(24),
                                      ),
                                      child: Row(
                                    children: [
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () {
                                            if (!isSignIn) toggleAuthMode();
                                          },
                                          child: AnimatedContainer(
                                            duration: const Duration(milliseconds: 300),
                                            decoration: BoxDecoration(
                                                  color: isSignIn ? const Color(0xFF2979FF) : Colors.transparent,
                                                  borderRadius: BorderRadius.circular(24),
                                            ),
                                            child: Center(
                                              child: Text(
                                                'Sign In',
                                                style: GoogleFonts.poppins(
                                                  fontWeight: FontWeight.w600,
                                                      fontSize: 16,
                                                      color: isSignIn ? Colors.white : Color(0xFF232136),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () {
                                            if (isSignIn) toggleAuthMode();
                                          },
                                          child: AnimatedContainer(
                                            duration: const Duration(milliseconds: 300),
                                            decoration: BoxDecoration(
                                                  color: !isSignIn ? const Color(0xFF2979FF) : Colors.transparent,
                                                  borderRadius: BorderRadius.circular(24),
                                            ),
                                            child: Center(
                                              child: Text(
                                                'Sign Up',
                                                style: GoogleFonts.poppins(
                                                  fontWeight: FontWeight.w600,
                                                      fontSize: 16,
                                                      color: !isSignIn ? Colors.white : Color(0xFF232136),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                  ),
                                  AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 500),
                                    transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
                                    child: isSignIn
                                          ? Column(
                                        children: [
                                          const SizedBox(height: 28),
                                          _SignInForm(key: const ValueKey('signIn')),
                                        ],
                                      )
                                          : Column(
                                        children: [
                                          const SizedBox(height: 28),
                                          _SignUpForm(key: const ValueKey('signUp')),
                                        ],
                                      ),
                                  ),
                                ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 36),
                            Text(
                              'Smart Store Finder with AI Offers',
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w400,
                                color: Color(0xFF6B7280),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SignInForm extends StatefulWidget {
  const _SignInForm({super.key});

  @override
  State<_SignInForm> createState() => _SignInFormState();
}

class _SignInFormState extends State<_SignInForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final result = await AuthService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      ).timeout(
        const Duration(seconds: 20),
        onTimeout: () {
          return {
            'success': false,
            'message': 'Request timed out. Please check your connection and try again.',
            'timeoutError': true,
          };
        },
      );

      if (!mounted) return;

      final navigator = Navigator.of(context);
      
      if (result['success']) {
        final user = result['user'] as UserModel?;
        final isShopOwner = user?.role == 'shop';
        
        MessageHelper.showAnimatedMessage(
          context,
          message: isShopOwner ? 'Login successful! Redirecting to shop dashboard...' : 'Login successful!',
          type: MessageType.success,
          title: 'Welcome Back!',
        );
        
        if (isShopOwner) {
          navigator.pushReplacementNamed('/shop-owner-dashboard');
        } else {
          navigator.pushReplacementNamed('/home');
        }
      } else {
        MessageHelper.showAnimatedMessage(
          context,
          message: result['message'],
          type: MessageType.error,
          title: 'Login Failed',
        );
      }
    } catch (e) {
      if (!mounted) return;
      MessageHelper.showAnimatedMessage(
        context,
        message: 'An error occurred: $e',
        type: MessageType.error,
        title: 'Error',
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _emailController,
            decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF7F8FA),
              labelText: 'Email',
              labelStyle: GoogleFonts.poppins(
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w500,
              fontSize: 16,
              ),
            prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF6B7280)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFF2979FF), width: 2),
            ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Colors.red),
              ),
          ),
          style: GoogleFonts.poppins(
            color: Color(0xFF232136),
            fontWeight: FontWeight.w500,
            fontSize: 16,
            ),
            keyboardType: TextInputType.emailAddress,
          cursorColor: const Color(0xFF2979FF),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your email';
              }
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ),
        const SizedBox(height: 18),
          TextFormField(
            controller: _passwordController,
            decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF7F8FA),
              labelText: 'Password',
              labelStyle: GoogleFonts.poppins(
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w500,
              fontSize: 16,
              ),
            prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF6B7280)),
              suffixIcon: IconButton(
                icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFF2979FF), width: 2),
            ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Colors.red),
              ),
          ),
          style: GoogleFonts.poppins(
            color: Color(0xFF232136),
            fontWeight: FontWeight.w500,
            fontSize: 16,
            ),
            obscureText: _obscurePassword,
          cursorColor: const Color(0xFF2979FF),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your password';
              }
              if (value.length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8.0, bottom: 18.0),
          child: Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).pushNamed('/forgot-password');
              },
              child: Text(
                'Forgot Password?',
                style: GoogleFonts.poppins(
                  color: const Color(0xFF2979FF),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        ),
          ElevatedButton(
            onPressed: _isLoading ? null : _signIn,
            style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2979FF),
            foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 2,
            ),
            child: _isLoading
                ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text('Sign In', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
          ),
        const SizedBox(height: 14),
          const SocialLoginButtons(),
        ],
      ),
    );
  }
}

class _SignUpForm extends StatefulWidget {
  const _SignUpForm({super.key});

  @override
  State<_SignUpForm> createState() => _SignUpFormState();
}

class _SignUpFormState extends State<_SignUpForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _shopNameController = TextEditingController();
  final _licenseNumberController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  
  bool agreeToTerms = false;
  String selectedRole = 'user';
  String selectedState = 'Maharashtra';
  bool _isLoading = false;
  bool _obscurePassword = true;
  File? _licenseFile;
  String? _licenseFileName;
  bool _isUploading = false;
  
  // Location verification variables
  Position? _currentPosition;
  String? _gpsAddress;
  bool _isLocationVerified = false;
  bool _isCapturingLocation = false;
  
  // List of Indian states
  final List<String> _states = [
    'Andhra Pradesh', 'Arunachal Pradesh', 'Assam', 'Bihar', 'Chhattisgarh',
    'Goa', 'Gujarat', 'Haryana', 'Himachal Pradesh', 'Jharkhand', 'Karnataka',
    'Kerala', 'Madhya Pradesh', 'Maharashtra', 'Manipur', 'Meghalaya', 'Mizoram',
    'Nagaland', 'Odisha', 'Punjab', 'Rajasthan', 'Sikkim', 'Tamil Nadu',
    'Telangana', 'Tripura', 'Uttar Pradesh', 'Uttarakhand', 'West Bengal',
    'Delhi', 'Jammu and Kashmir', 'Ladakh', 'Chandigarh', 'Dadra and Nagar Haveli',
    'Daman and Diu', 'Lakshadweep', 'Puducherry', 'Andaman and Nicobar Islands'
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _shopNameController.dispose();
    _licenseNumberController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickLicenseFile() async {
    try {
      setState(() => _isUploading = true);
      
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        allowMultiple: false,
      );
      
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.path != null) {
          setState(() {
            _licenseFile = File(file.path!);
            _licenseFileName = file.name;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        MessageHelper.showAnimatedMessage(
          context,
          message: 'Error picking file: $e',
          type: MessageType.error,
          title: 'File Error',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  Future<void> _captureLocation() async {
    if (_addressController.text.trim().isEmpty) {
      MessageHelper.showAnimatedMessage(
        context,
        message: 'Please enter your shop address first',
        type: MessageType.warning,
        title: 'Address Required',
      );
      return;
    }

    setState(() => _isCapturingLocation = true);

    try {
      // Check and request location permission
      bool hasPermission = await LocationService.isLocationPermissionGranted();
      if (!hasPermission) {
        hasPermission = await LocationService.requestLocationPermission();
        if (!hasPermission) {
          if (mounted) {
            MessageHelper.showAnimatedMessage(
              context,
              message: 'Location permission is required to verify your address. Please enable it in settings.',
              type: MessageType.error,
              title: 'Permission Required',
            );
          }
          return;
        }
      }

      // Get current location
      Position? position = await LocationService.getCurrentLocation();
      if (position == null) {
        if (mounted) {
          MessageHelper.showAnimatedMessage(
            context,
            message: 'Unable to get your current location. Please check your GPS settings and try again.',
            type: MessageType.error,
            title: 'Location Error',
          );
        }
        return;
      }

      // Get address from coordinates
      String? gpsAddress = await LocationService.getAddressFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (gpsAddress == null) {
        if (mounted) {
          MessageHelper.showAnimatedMessage(
            context,
            message: 'Unable to get address from your location. Please try again.',
            type: MessageType.error,
            title: 'Address Error',
          );
        }
        return;
      }

      // Compare addresses
      bool addressesMatch = LocationService.compareAddresses(
        _addressController.text.trim(),
        gpsAddress,
      );

      setState(() {
        _currentPosition = position;
        _gpsAddress = gpsAddress;
        _isLocationVerified = addressesMatch;
      });

      if (mounted) {
        if (addressesMatch) {
          MessageHelper.showAnimatedMessage(
            context,
            message: '✅ Location verified successfully! Your address matches your current location.',
            type: MessageType.success,
            title: 'Location Verified',
          );
        } else {
          MessageHelper.showAnimatedMessage(
            context,
            message: '⚠️ Your current location does not match the entered address. Please verify your address or re-upload your license document.',
            type: MessageType.warning,
            title: 'Address Mismatch',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        MessageHelper.showAnimatedMessage(
          context,
          message: 'Error capturing location: $e',
          type: MessageType.error,
          title: 'Location Error',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCapturingLocation = false);
      }
    }
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (selectedRole == 'shop') {
      if (_licenseFile == null) {
        MessageHelper.showAnimatedMessage(
          context,
          message: 'Please upload your Shop Act License',
          type: MessageType.warning,
          title: 'License Required',
        );
        return;
      }
      
      if (!_isLocationVerified) {
        MessageHelper.showAnimatedMessage(
          context,
          message: 'Please verify your location by clicking "Verify Location" button',
          type: MessageType.warning,
          title: 'Location Verification Required',
        );
        return;
      }
    }
    
    if (!agreeToTerms) {
      MessageHelper.showAnimatedMessage(
        context,
        message: 'Please agree to Terms & Conditions',
        type: MessageType.warning,
        title: 'Terms Required',
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await AuthService.register(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        fullName: _nameController.text.trim(),
        role: selectedRole,
        shopName: selectedRole == 'shop' ? _shopNameController.text.trim() : null,
        licenseNumber: selectedRole == 'shop' ? _licenseNumberController.text.trim() : null,
        state: selectedRole == 'shop' ? selectedState : null,
        phone: selectedRole == 'shop' ? _phoneController.text.trim() : null,
        address: selectedRole == 'shop' ? _addressController.text.trim() : null,
        licenseFile: selectedRole == 'shop' ? _licenseFile : null,
        location: selectedRole == 'shop' && _currentPosition != null 
            ? LocationService.getLocationMap(_currentPosition!) 
            : null,
        gpsAddress: selectedRole == 'shop' ? _gpsAddress : null,
        isLocationVerified: selectedRole == 'shop' ? _isLocationVerified : null,
      ).timeout(
        const Duration(seconds: 35),
        onTimeout: () {
          return {
            'success': false,
            'message': 'Request timed out. Please check your connection and try again.',
            'timeoutError': true,
          };
        },
      );

      if (!mounted) return;

      final navigator = Navigator.of(context);
      
      if (result['success']) {
        MessageHelper.showAnimatedMessage(
          context,
          message: 'Registration successful! Please check your email for OTP.',
          type: MessageType.success,
          title: 'Account Created!',
        );
        navigator.pushNamed('/otp-verification', arguments: {
          'email': _emailController.text.trim(),
          'userId': result['userId'],
        });
      } else {
        MessageHelper.showAnimatedMessage(
          context,
          message: result['message'],
          type: MessageType.error,
          title: 'Registration Failed',
        );
      }
    } catch (e) {
      if (!mounted) return;
      MessageHelper.showAnimatedMessage(
        context,
        message: 'An error occurred: $e',
        type: MessageType.error,
        title: 'Error',
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
        TextFormField(
            controller: _nameController,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF7F8FA),
            labelText: selectedRole == 'user' ? 'Full Name' : 'Owner Name',
            labelStyle: GoogleFonts.poppins(
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w500,
              fontSize: 16,
            ),
            prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF6B7280)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFF2979FF), width: 2),
            ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Colors.red),
              ),
          ),
          style: GoogleFonts.poppins(
            color: Color(0xFF232136),
            fontWeight: FontWeight.w500,
            fontSize: 16,
          ),
          keyboardType: TextInputType.name,
          cursorColor: const Color(0xFF2979FF),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your name';
              }
              return null;
            },
        ),
        const SizedBox(height: 18),
        
        if (selectedRole == 'shop') ...[
          // Shop Name Field
          TextFormField(
            controller: _shopNameController,
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFF7F8FA),
              labelText: 'Shop Name *',
              labelStyle: GoogleFonts.poppins(
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w500,
                fontSize: 16,
              ),
              prefixIcon: const Icon(Icons.store, color: Color(0xFF6B7280)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFF2979FF), width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Colors.red),
              ),
            ),
            style: GoogleFonts.poppins(
              color: Color(0xFF232136),
              fontWeight: FontWeight.w500,
              fontSize: 16,
            ),
            cursorColor: const Color(0xFF2979FF),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter shop name';
              }
              if (value.length < 3) {
                return 'Shop name must be at least 3 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 18),
          
          // License Number Field
          TextFormField(
            controller: _licenseNumberController,
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFF7F8FA),
              labelText: 'Shop Act License Number *',
              labelStyle: GoogleFonts.poppins(
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w500,
                fontSize: 16,
              ),
              prefixIcon: const Icon(Icons.verified_user, color: Color(0xFF6B7280)),
              hintText: 'Enter your license number',
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFF2979FF), width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Colors.red),
              ),
            ),
            style: GoogleFonts.poppins(
              color: Color(0xFF232136),
              fontWeight: FontWeight.w500,
              fontSize: 16,
            ),
            cursorColor: const Color(0xFF2979FF),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter license number';
              }
              if (value.length < 5) {
                return 'License number must be at least 5 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 18),
          
          // State Dropdown
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF7F8FA),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: DropdownButtonFormField<String>(
              value: selectedState,
              decoration: InputDecoration(
                labelText: 'State *',
                labelStyle: GoogleFonts.poppins(
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
                prefixIcon: const Icon(Icons.location_on, color: Color(0xFF6B7280)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              style: GoogleFonts.poppins(
                color: Color(0xFF232136),
                fontWeight: FontWeight.w500,
                fontSize: 16,
              ),
              dropdownColor: Colors.white,
              items: _states.map((String state) {
                return DropdownMenuItem<String>(
                  value: state,
                  child: Text(state),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    selectedState = newValue;
                  });
                }
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select a state';
                }
                return null;
              },
            ),
          ),
          const SizedBox(height: 18),
          
          // Phone Number Field
          TextFormField(
            controller: _phoneController,
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFF7F8FA),
              labelText: 'Phone Number *',
              labelStyle: GoogleFonts.poppins(
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w500,
                fontSize: 16,
              ),
              prefixIcon: const Icon(Icons.phone, color: Color(0xFF6B7280)),
              hintText: 'Enter your phone number',
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFF2979FF), width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Colors.red),
              ),
            ),
            style: GoogleFonts.poppins(
              color: Color(0xFF232136),
              fontWeight: FontWeight.w500,
              fontSize: 16,
            ),
            keyboardType: TextInputType.phone,
            cursorColor: const Color(0xFF2979FF),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter phone number';
              }
              if (!RegExp(r'^[0-9]{10}$').hasMatch(value)) {
                return 'Please enter a valid 10-digit phone number';
              }
              return null;
            },
          ),
          const SizedBox(height: 18),
          
          // Address Field with Location Verification
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _addressController,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFFF7F8FA),
                  labelText: 'Shop Address *',
                  labelStyle: GoogleFonts.poppins(
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                  prefixIcon: const Icon(Icons.location_on, color: Color(0xFF6B7280)),
                  hintText: 'Enter your complete shop address',
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: _isLocationVerified ? const Color(0xFF4CAF50) : const Color(0xFFE5E7EB),
                      width: _isLocationVerified ? 2 : 1,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFF2979FF), width: 2),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Colors.red),
                  ),
                ),
                style: GoogleFonts.poppins(
                  color: Color(0xFF232136),
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
                maxLines: 3,
                cursorColor: const Color(0xFF2979FF),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter shop address';
                  }
                  if (value.length < 10) {
                    return 'Address must be at least 10 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              
              // Location Verification Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isCapturingLocation ? null : _captureLocation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isLocationVerified 
                        ? const Color(0xFF4CAF50) 
                        : const Color(0xFF2979FF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  icon: _isCapturingLocation
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Icon(
                          _isLocationVerified ? Icons.check_circle : Icons.my_location,
                          size: 20,
                        ),
                  label: Text(
                    _isCapturingLocation
                        ? 'Capturing Location...'
                        : _isLocationVerified
                            ? 'Location Verified ✓'
                            : 'Verify Location',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              
              // Location Status Display
              if (_gpsAddress != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _isLocationVerified 
                        ? const Color(0xFFE8F5E8) 
                        : const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _isLocationVerified 
                          ? const Color(0xFF4CAF50) 
                          : const Color(0xFFFF9800),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isLocationVerified ? Icons.check_circle : Icons.warning,
                        color: _isLocationVerified 
                            ? const Color(0xFF4CAF50) 
                            : const Color(0xFFFF9800),
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _isLocationVerified 
                              ? 'GPS Address matches entered address'
                              : 'GPS Address: $_gpsAddress',
                          style: GoogleFonts.poppins(
                            color: _isLocationVerified 
                                ? const Color(0xFF4CAF50) 
                                : const Color(0xFFFF9800),
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 18),
          
          // License File Upload
          Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: _licenseFile != null ? const Color(0xFF2979FF) : const Color(0xFFE5E7EB),
                width: _licenseFile != null ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(14),
              color: const Color(0xFFF7F8FA),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.upload_file,
                        color: _licenseFile != null ? const Color(0xFF2979FF) : const Color(0xFF6B7280),
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Shop Act License *',
                              style: GoogleFonts.poppins(
                                color: const Color(0xFF6B7280),
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Upload PDF, JPG, or PNG (Max 10MB)',
                              style: GoogleFonts.poppins(
                                color: const Color(0xFF6B7280),
                                fontWeight: FontWeight.w400,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (_licenseFile != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3F2FD),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF2979FF)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: const Color(0xFF2979FF),
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _licenseFileName ?? 'File uploaded',
                            style: GoogleFonts.poppins(
                              color: const Color(0xFF2979FF),
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _licenseFile = null;
                              _licenseFileName = null;
                            });
                          },
                          icon: const Icon(Icons.close, color: Color(0xFF2979FF)),
                          iconSize: 20,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isUploading ? null : _pickLicenseFile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _licenseFile != null 
                            ? const Color(0xFFE3F2FD) 
                            : const Color(0xFF2979FF),
                        foregroundColor: _licenseFile != null 
                            ? const Color(0xFF2979FF) 
                            : Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      icon: _isUploading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2979FF)),
                              ),
                            )
                          : Icon(
                              _licenseFile != null ? Icons.refresh : Icons.upload_file,
                              size: 20,
                            ),
                      label: Text(
                        _isUploading
                            ? 'Uploading...'
                            : _licenseFile != null
                                ? 'Change File'
                                : 'Choose File',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          
          // Verification Notice
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFF9800)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: const Color(0xFFFF9800),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Verification Process',
                        style: GoogleFonts.poppins(
                          color: const Color(0xFFFF9800),
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '• Your account will be marked as "Pending Verification" until we verify your license and location\n• License verification typically takes 24-48 hours\n• Location verification helps prevent fake registrations\n• Admin approval required before shop goes live',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFFFF9800),
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
        ],
        
        TextFormField(
            controller: _emailController,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF7F8FA),
            labelText: 'Email',
            labelStyle: GoogleFonts.poppins(
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w500,
              fontSize: 16,
            ),
            prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF6B7280)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFF2979FF), width: 2),
            ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Colors.red),
              ),
          ),
          style: GoogleFonts.poppins(
            color: Color(0xFF232136),
            fontWeight: FontWeight.w500,
            fontSize: 16,
          ),
          keyboardType: TextInputType.emailAddress,
          cursorColor: const Color(0xFF2979FF),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your email';
              }
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                return 'Please enter a valid email';
              }
              return null;
            },
        ),
        const SizedBox(height: 18),
        
        TextFormField(
            controller: _passwordController,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF7F8FA),
            labelText: 'Password',
            labelStyle: GoogleFonts.poppins(
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w500,
              fontSize: 16,
            ),
            prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF6B7280)),
              suffixIcon: IconButton(
                icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFF2979FF), width: 2),
            ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Colors.red),
              ),
          ),
          style: GoogleFonts.poppins(
            color: Color(0xFF232136),
            fontWeight: FontWeight.w500,
            fontSize: 16,
          ),
            obscureText: _obscurePassword,
          cursorColor: const Color(0xFF2979FF),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your password';
              }
              if (value.length < 8) {
                return 'Password must be at least 8 characters long';
              }
              if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)').hasMatch(value)) {
                return 'Password must contain uppercase, lowercase, and number';
              }
              return null;
            },
          ),
        const SizedBox(height: 18),
        
          RoleSelector(
            selectedRole: selectedRole,
            onChanged: (role) => setState(() => selectedRole = role),
          ),
        const SizedBox(height: 18),
        
          Row(
            children: [
              Checkbox(
                value: agreeToTerms,
                onChanged: (v) => setState(() => agreeToTerms = v ?? false),
              activeColor: const Color(0xFF2979FF),
              checkColor: Colors.white,
              ),
              Expanded(
                child: Text(
                  'I agree to the Terms & Conditions',
                  style: GoogleFonts.poppins(
                  color: const Color(0xFF2979FF),
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        const SizedBox(height: 18),
        
          ElevatedButton(
            onPressed: agreeToTerms && !_isLoading ? _signUp : null,
            style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2979FF),
            foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 2,
            ),
            child: _isLoading
                ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
            selectedRole == 'user' ? 'Sign Up' : 'Register Shop',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)
          ),
          ),
        const SizedBox(height: 14),
        
          const SocialLoginButtons(),
        ],
      ),
    );
  }
} 