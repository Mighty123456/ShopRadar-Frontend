import 'package:flutter/material.dart';
import '../widgets/custom_button.dart';
import '../widgets/animated_message_dialog.dart';
import '../services/profile_service.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (_currentPasswordController.text.trim().isEmpty) {
      MessageHelper.showAnimatedMessage(
        context,
        message: 'Current password is required',
        type: MessageType.error,
        title: 'Validation Error',
      );
      return;
    }

    if (_newPasswordController.text.trim().isEmpty) {
      MessageHelper.showAnimatedMessage(
        context,
        message: 'New password is required',
        type: MessageType.error,
        title: 'Validation Error',
      );
      return;
    }

    if (_newPasswordController.text.length < 6) {
      MessageHelper.showAnimatedMessage(
        context,
        message: 'New password must be at least 6 characters long',
        type: MessageType.error,
        title: 'Validation Error',
      );
      return;
    }

    if (_newPasswordController.text != _confirmPasswordController.text) {
      MessageHelper.showAnimatedMessage(
        context,
        message: 'New passwords do not match',
        type: MessageType.error,
        title: 'Validation Error',
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      const userId = 'user123';
      
      final result = await ProfileService.changePassword(
        userId: userId,
        currentPassword: _currentPasswordController.text.trim(),
        newPassword: _newPasswordController.text.trim(),
      );

      if (result['success']) {
        if (mounted) {
          MessageHelper.showAnimatedMessage(
            context,
            message: 'Password changed successfully!',
            type: MessageType.success,
            title: 'Success',
          );
          
          _currentPasswordController.clear();
          _newPasswordController.clear();
          _confirmPasswordController.clear();
          
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              Navigator.of(context).pop();
            }
          });
        }
      } else {
        if (mounted) {
          MessageHelper.showAnimatedMessage(
            context,
            message: result['message'] ?? 'Failed to change password',
            type: MessageType.error,
            title: 'Error',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        MessageHelper.showAnimatedMessage(
          context,
          message: 'An error occurred. Please try again.',
          type: MessageType.error,
          title: 'Error',
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isLargeTablet = screenWidth > 900;
    final isPhone = screenWidth < 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2979FF),
        elevation: 0,
        toolbarHeight: isLargeTablet ? 80 : (isTablet ? 70 : 56),
        title: Text(
          'Change Password',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: isLargeTablet ? 28 : (isTablet ? 24 : 20),
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Colors.white,
            size: isLargeTablet ? 32 : (isTablet ? 28 : 24),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isLargeTablet ? 32 : (isTablet ? 24 : 16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(isLargeTablet ? 24 : (isTablet ? 20 : 16)),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF2979FF),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.lock,
                      color: const Color(0xFF2979FF),
                      size: isLargeTablet ? 32 : (isTablet ? 28 : 24),
                    ),
                    SizedBox(width: isLargeTablet ? 16 : (isTablet ? 12 : 8)),
                    Expanded(
                      child: Text(
                        'Update your account password to keep your account secure',
                        style: TextStyle(
                          fontSize: isLargeTablet ? 16 : (isTablet ? 14 : 12),
                          color: const Color(0xFF2979FF),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: isLargeTablet ? 40 : (isTablet ? 32 : 24)),
              
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(isLargeTablet ? 32 : (isTablet ? 24 : 16)),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Password Information',
                      style: TextStyle(
                        fontSize: isLargeTablet ? 24 : (isTablet ? 20 : 18),
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1F2937),
                      ),
                    ),
                    
                    SizedBox(height: isLargeTablet ? 24 : (isTablet ? 20 : 16)),
                    
                    _buildPasswordField(
                      label: 'Current Password',
                      controller: _currentPasswordController,
                      icon: Icons.lock_outline,
                      obscureText: _obscureCurrentPassword,
                      onToggleObscure: () {
                        setState(() {
                          _obscureCurrentPassword = !_obscureCurrentPassword;
                        });
                      },
                      isLargeTablet: isLargeTablet,
                      isTablet: isTablet,
                      isPhone: isPhone,
                    ),
                    
                    SizedBox(height: isLargeTablet ? 20 : (isTablet ? 16 : 12)),
                    
                    _buildPasswordField(
                      label: 'New Password',
                      controller: _newPasswordController,
                      icon: Icons.lock,
                      obscureText: _obscureNewPassword,
                      onToggleObscure: () {
                        setState(() {
                          _obscureNewPassword = !_obscureNewPassword;
                        });
                      },
                      isLargeTablet: isLargeTablet,
                      isTablet: isTablet,
                      isPhone: isPhone,
                    ),
                    
                    SizedBox(height: isLargeTablet ? 20 : (isTablet ? 16 : 12)),
                    
                    _buildPasswordField(
                      label: 'Confirm New Password',
                      controller: _confirmPasswordController,
                      icon: Icons.lock,
                      obscureText: _obscureConfirmPassword,
                      onToggleObscure: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                      isLargeTablet: isLargeTablet,
                      isTablet: isTablet,
                      isPhone: isPhone,
                    ),
                    
                    SizedBox(height: isLargeTablet ? 20 : (isTablet ? 16 : 12)),
                    
                    Container(
                      padding: EdgeInsets.all(isLargeTablet ? 16 : (isTablet ? 12 : 8)),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFE5E7EB),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Password Requirements:',
                            style: TextStyle(
                              fontSize: isLargeTablet ? 16 : (isTablet ? 14 : 12),
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF6B7280),
                            ),
                          ),
                          SizedBox(height: isLargeTablet ? 8 : (isTablet ? 6 : 4)),
                          Text(
                            '• At least 6 characters long\n• Include a mix of letters and numbers\n• Avoid common passwords',
                            style: TextStyle(
                              fontSize: isLargeTablet ? 14 : (isTablet ? 12 : 10),
                              color: const Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: isLargeTablet ? 40 : (isTablet ? 32 : 24)),
              
              SizedBox(
                width: double.infinity,
                child: CustomButton(
                  text: _isLoading ? 'Changing Password...' : 'Change Password',
                  onPressed: _isLoading ? null : _changePassword,
                  height: isLargeTablet ? 56 : (isTablet ? 52 : 48),
                ),
              ),
              
              SizedBox(height: isLargeTablet ? 16 : (isTablet ? 12 : 8)),
              
              SizedBox(
                width: double.infinity,
                child: CustomButton(
                  text: 'Cancel',
                  onPressed: () => Navigator.of(context).pop(),
                  isPrimary: false,
                  height: isLargeTablet ? 56 : (isTablet ? 52 : 48),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required bool obscureText,
    required VoidCallback onToggleObscure,
    required bool isLargeTablet,
    required bool isTablet,
    required bool isPhone,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isLargeTablet ? 16 : (isTablet ? 14 : 12),
            fontWeight: FontWeight.w600,
            color: const Color(0xFF6B7280),
          ),
        ),
        
        SizedBox(height: isLargeTablet ? 8 : (isTablet ? 6 : 4)),
        
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: isLargeTablet ? 16 : (isTablet ? 12 : 8),
            vertical: isLargeTablet ? 16 : (isTablet ? 12 : 8),
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFE5E7EB),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: const Color(0xFF6B7280),
                size: isLargeTablet ? 24 : (isTablet ? 20 : 16),
              ),
              
              SizedBox(width: isLargeTablet ? 16 : (isTablet ? 12 : 8)),
              
              Expanded(
                child: TextField(
                  controller: controller,
                  obscureText: obscureText,
                  style: TextStyle(
                    fontSize: isLargeTablet ? 16 : (isTablet ? 14 : 12),
                    color: const Color(0xFF1F2937),
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Enter your password',
                  ),
                ),
              ),
              
              IconButton(
                onPressed: onToggleObscure,
                icon: Icon(
                  obscureText ? Icons.visibility : Icons.visibility_off,
                  color: const Color(0xFF6B7280),
                  size: isLargeTablet ? 24 : (isTablet ? 20 : 16),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
