import 'package:flutter/material.dart';
import 'dart:async';
import '../widgets/social_login_buttons.dart';
import '../widgets/role_selector.dart';
import '../services/auth_service.dart';
import '../widgets/animated_message_dialog.dart';
import '../models/user_model.dart';
import 'package:google_fonts/google_fonts.dart';

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
          Navigator.of(context).pushReplacementNamed('/shop-owner-dashboard');
        } else {
          Navigator.of(context).pushReplacementNamed('/home');
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
  bool agreeToTerms = false;
  String selectedRole = 'user';
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
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

      if (result['success']) {
        MessageHelper.showAnimatedMessage(
          context,
          message: 'Registration successful! Please check your email for OTP.',
          type: MessageType.success,
          title: 'Account Created!',
        );
        Navigator.of(context).pushNamed('/otp-verification', arguments: {
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
          TextFormField(
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFF7F8FA),
              labelText: 'Shop Name',
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
            ),
            style: GoogleFonts.poppins(
              color: Color(0xFF232136),
              fontWeight: FontWeight.w500,
              fontSize: 16,
            ),
            cursorColor: const Color(0xFF2979FF),
          ),
          const SizedBox(height: 18),
          
          TextFormField(
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFF7F8FA),
              labelText: 'Business Type',
              labelStyle: GoogleFonts.poppins(
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w500,
                fontSize: 16,
              ),
              prefixIcon: const Icon(Icons.business, color: Color(0xFF6B7280)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFF2979FF), width: 2),
              ),
            ),
            style: GoogleFonts.poppins(
              color: Color(0xFF232136),
              fontWeight: FontWeight.w500,
              fontSize: 16,
            ),
            cursorColor: const Color(0xFF2979FF),
          ),
          const SizedBox(height: 18),
          
          TextFormField(
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFF7F8FA),
              labelText: 'Phone Number',
              labelStyle: GoogleFonts.poppins(
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w500,
                fontSize: 16,
              ),
              prefixIcon: const Icon(Icons.phone, color: Color(0xFF6B7280)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFF2979FF), width: 2),
              ),
            ),
            style: GoogleFonts.poppins(
              color: Color(0xFF232136),
              fontWeight: FontWeight.w500,
              fontSize: 16,
            ),
            keyboardType: TextInputType.phone,
            cursorColor: const Color(0xFF2979FF),
          ),
          const SizedBox(height: 18),
          
          TextFormField(
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFF7F8FA),
              labelText: 'Shop Address',
              labelStyle: GoogleFonts.poppins(
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w500,
                fontSize: 16,
              ),
              prefixIcon: const Icon(Icons.location_on, color: Color(0xFF6B7280)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFF2979FF), width: 2),
              ),
            ),
            style: GoogleFonts.poppins(
              color: Color(0xFF232136),
              fontWeight: FontWeight.w500,
              fontSize: 16,
            ),
            maxLines: 2,
            cursorColor: const Color(0xFF2979FF),
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