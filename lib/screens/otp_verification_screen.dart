import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../services/auth_service.dart';
import '../services/auth_flow_manager.dart';
import '../widgets/custom_button.dart';
import '../widgets/animated_message_dialog.dart';

class OTPVerificationScreen extends StatefulWidget {
  final String email;
  final String userId;

  const OTPVerificationScreen({
    super.key,
    required this.email,
    required this.userId,
  });

  @override
  State<OTPVerificationScreen> createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(
    6,
    (index) => FocusNode(),
  );

  bool _isLoading = false;
  bool _isResending = false;
  int _resendTimer = 60;
  bool _canResend = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _startResendTimer() {
    _timer?.cancel();
    
    setState(() {
      _canResend = false;
      _resendTimer = 60;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      if (_resendTimer > 0) {
        setState(() {
          _resendTimer--;
        });
      } else {
        setState(() {
          _canResend = true;
        });
        timer.cancel();
      }
    });
  }

  String _getOTP() {
    return _otpControllers.map((controller) => controller.text).join();
  }

  void _onOTPChanged(int index) {
    if (index < 5 && _otpControllers[index].text.isNotEmpty) {
      _focusNodes[index + 1].requestFocus();
    }
  }

  Future<void> _verifyOTP() async {
    final otp = _getOTP();
    if (otp.length != 6) {
      _showAnimatedMessage('Please enter the complete 6-digit code');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await AuthService.verifyOTP(
        email: widget.email,
        otp: otp,
      );

      if (result['success']) {
        if (mounted) {
          await AuthFlowManager.handleSuccessfulVerification(
            context: context,
            message: result['message'],
          );
        }
      } else {
        if (mounted) {
          _showAnimatedMessage(result['message']);
        }
      }
    } catch (e) {
      if (mounted) {
        _showAnimatedMessage('An error occurred. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _resendOTP() async {
    if (!_canResend) return;

    setState(() {
      _isResending = true;
    });

    try {
      final result = await AuthService.resendOTP(email: widget.email);

      if (result['success']) {
        if (mounted) {
          _showAnimatedMessage(result['message'], isSuccess: true);
          _startResendTimer();
        }
      } else {
        if (mounted) {
          _showAnimatedMessage(result['message']);
        }
      }
    } catch (e) {
      if (mounted) {
        _showAnimatedMessage('An error occurred. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isResending = false;
        });
      }
    }
  }

  void _showAnimatedMessage(String message, {bool isSuccess = false}) {
    MessageHelper.showAnimatedMessage(
      context,
      message: message,
      type: isSuccess ? MessageType.success : MessageType.error,
      title: isSuccess ? 'OTP Sent!' : 'Verification Failed',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;
            final titleSize = screenWidth < 360
                ? 24.0
                : (screenWidth < 420 ? 26.0 : 28.0);
            final subtitleSize = screenWidth < 360 ? 14.0 : 16.0;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 48, // Account for padding
                ),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
              const SizedBox(height: 20),
              Text(
                'Verify Your Email',
                style: TextStyle(
                  fontSize: titleSize,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'We\'ve sent a 6-digit verification code to\n${widget.email}',
                style: TextStyle(
                  fontSize: subtitleSize,
                  color: Colors.grey,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 40),
              
              // Responsive OTP input boxes
              LayoutBuilder(
                builder: (context, constraints) {
                  final availableWidth = constraints.maxWidth;
                  // Aim for 6 in a row on roomy screens; wrap to new lines on compact
                  final idealBoxWidth = (availableWidth - (5 * 8)) / 6;
                  final boxSize = idealBoxWidth.clamp(44.0, 56.0);
                  
                  return Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    runAlignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 12,
                    children: List.generate(6, (index) {
                      return SizedBox(
                        width: boxSize,
                        height: boxSize,
                        child: TextField(
                          controller: _otpControllers[index],
                          focusNode: _focusNodes[index],
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          maxLength: 1,
                          style: TextStyle(
                            fontSize: boxSize * 0.4,
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: InputDecoration(
                            counterText: '',
                            contentPadding: EdgeInsets.zero,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.grey),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.blue, width: 2),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.grey),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.red),
                            ),
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          onChanged: (value) {
                            if (value.isNotEmpty) {
                              _onOTPChanged(index);
                            } else if (value.isEmpty && index > 0) {
                              _focusNodes[index - 1].requestFocus();
                            }
                          },
                        ),
                      );
                    }),
                  );
                },
              ),
              
              const SizedBox(height: 40),
              
              // Verify button with proper constraints
              ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: 50,
                  maxHeight: 60,
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: CustomButton(
                    text: _isLoading ? 'Verifying...' : 'Verify Email',
                    onPressed: _isLoading ? null : _verifyOTP,
                    isLoading: _isLoading,
                  ),
                ),
              ),
              
              const SizedBox(height: 30),
              
              // Add flexible space to prevent overflow
              const Spacer(),
              
              Center(
                child: Column(
                  children: [
                    if (!_canResend) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.timer, color: Colors.blue, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              'Resend in $_resendTimer seconds',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.blue,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ] else ...[
                      Text(
                        'Didn\'t receive the code?',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    TextButton(
                      onPressed: _canResend && !_isResending ? _resendOTP : null,
                      child: Text(
                        _isResending ? 'Sending...' : 'Resend Code',
                        style: TextStyle(
                          color: _canResend && !_isResending
                              ? Colors.blue
                              : Colors.grey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 40),
              
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacementNamed('/auth');
                  },
                  child: const Text(
                    'Back to Login',
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
} 