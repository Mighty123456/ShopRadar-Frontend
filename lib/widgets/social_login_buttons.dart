import 'package:flutter/material.dart';
import '../services/google_auth_service.dart';
import '../widgets/animated_message_dialog.dart';
import '../models/user_model.dart';
import 'package:google_fonts/google_fonts.dart';

class SocialLoginButtons extends StatefulWidget {
  final VoidCallback? onGooglePressed;
  
  const SocialLoginButtons({
    super.key,
    this.onGooglePressed,
  });

  @override
  State<SocialLoginButtons> createState() => _SocialLoginButtonsState();
}

class _SocialLoginButtonsState extends State<SocialLoginButtons> {
  bool _isLoading = false;

  Future<void> _handleGoogleSignIn() async {
    if (widget.onGooglePressed != null) {
      widget.onGooglePressed!();
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await GoogleAuthService.signIn();
      
      if (result['success']) {
        if (mounted) {
          final user = result['user'] as UserModel?;
          final isShopOwner = user?.role == 'shop';
          
          MessageHelper.showAnimatedMessage(
            context,
            message: isShopOwner ? 'Google sign in successful! Redirecting to shop dashboard...' : 'Google sign in successful!',
            type: MessageType.success,
            title: 'Welcome!',
          );
          
          if (isShopOwner) {
            Navigator.of(context).pushReplacementNamed('/shop-owner-dashboard');
          } else {
            Navigator.of(context).pushReplacementNamed('/home');
          }
        }
      } else {
        if (mounted) {
          MessageHelper.showAnimatedMessage(
            context,
            message: result['message'],
            type: MessageType.error,
            title: 'Sign In Failed',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        MessageHelper.showAnimatedMessage(
          context,
          message: 'An error occurred: $e',
          type: MessageType.error,
          title: 'Error',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildGoogleLogo() {
    return Image.asset(
      'assets/images/Google_Favicon_2025.svg.png',
      width: 20,
      height: 20,
      fit: BoxFit.contain,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;
    
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _isLoading ? null : _handleGoogleSignIn,
        icon: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : _buildGoogleLogo(),
        label: Text(
          _isLoading ? 'Signing in...' : 'Continue with Google',
          style: GoogleFonts.poppins(
            fontSize: isSmallScreen ? 14 : 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.symmetric(
            vertical: isSmallScreen ? 14 : 16,
            horizontal: 16,
          ),
          side: const BorderSide(color: Color(0xFFE0E0E0)),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
      ),
    );
  }
} 