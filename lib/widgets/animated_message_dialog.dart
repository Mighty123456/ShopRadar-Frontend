import 'package:flutter/material.dart';

class AnimatedMessageDialog extends StatefulWidget {
  final String message;
  final MessageType type;
  final Duration duration;
  final VoidCallback? onDismiss;
  final bool isOTPNotification;
  final String? title;
  final List<DialogAction>? actions;

  const AnimatedMessageDialog({
    super.key,
    required this.message,
    this.type = MessageType.info,
    this.duration = const Duration(seconds: 3),
    this.onDismiss,
    this.isOTPNotification = false,
    this.title,
    this.actions,
  });

  @override
  State<AnimatedMessageDialog> createState() => _AnimatedMessageDialogState();
}

class _AnimatedMessageDialogState extends State<AnimatedMessageDialog>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward();

    if (widget.isOTPNotification) {
      _pulseController.repeat(reverse: true);
    }

    Future.delayed(widget.duration, () {
      if (mounted) {
        _dismiss();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _dismiss() {
    _animationController.reverse().then((_) {
      if (mounted) {
        widget.onDismiss?.call();
      }
    });
  }

  Color _getPrimaryColor() {
    switch (widget.type) {
      case MessageType.success:
        return const Color(0xFF10B981);
      case MessageType.error:
        return const Color(0xFFEF4444);
      case MessageType.warning:
        return const Color(0xFFF59E0B);
      case MessageType.info:
        return const Color(0xFF3B82F6);
    }
  }

  Color _getBackgroundColor() {
    switch (widget.type) {
      case MessageType.success:
        return const Color(0xFFECFDF5);
      case MessageType.error:
        return const Color(0xFFFEF2F2);
      case MessageType.warning:
        return const Color(0xFFFFFBEB);
      case MessageType.info:
        return const Color(0xFFEFF6FF);
    }
  }

  Color _getBorderColor() {
    switch (widget.type) {
      case MessageType.success:
        return const Color(0xFFD1FAE5);
      case MessageType.error:
        return const Color(0xFFFECACA);
      case MessageType.warning:
        return const Color(0xFFFED7AA);
      case MessageType.info:
        return const Color(0xFFDBEAFE);
    }
  }

  IconData _getIcon() {
    switch (widget.type) {
      case MessageType.success:
        return Icons.check_circle_rounded;
      case MessageType.error:
        return Icons.error_rounded;
      case MessageType.warning:
        return Icons.warning_rounded;
      case MessageType.info:
        return Icons.info_rounded;
    }
  }

  String _getTitle() {
    if (widget.title != null) return widget.title!;
    
    switch (widget.type) {
      case MessageType.success:
        return 'Success!';
      case MessageType.error:
        return 'Oops!';
      case MessageType.warning:
        return 'Warning!';
      case MessageType.info:
        return 'Information';
    }
  }

  String _getSubtitle() {
    switch (widget.type) {
      case MessageType.success:
        return 'Operation completed successfully';
      case MessageType.error:
        return 'Something went wrong';
      case MessageType.warning:
        return 'Please pay attention';
      case MessageType.info:
        return 'Important information';
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;
    
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _opacityAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  margin: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 16 : 24,
                    vertical: isSmallScreen ? 32 : 48,
                  ),
                  child: widget.isOTPNotification 
                      ? _buildOTPNotification(isSmallScreen)
                      : _buildConceptNotification(isSmallScreen),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildOTPNotification(bool isSmallScreen) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Container(
            padding: EdgeInsets.all(isSmallScreen ? 20 : 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF3B82F6),
                  const Color(0xFF8B5CF6),
                ],
                stops: const [0.0, 1.0],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.25),
                  blurRadius: 24,
                  spreadRadius: 0,
                  offset: const Offset(0, 12),
                ),
                BoxShadow(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                  blurRadius: 40,
                  spreadRadius: 0,
                  offset: const Offset(0, 20),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: const Icon(
                        Icons.email_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'OTP Sent Successfully!',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isSmallScreen ? 18 : 20,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Check your email for the verification code',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: isSmallScreen ? 14 : 15,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildCloseButton(),
                  ],
                ),
                
                SizedBox(height: isSmallScreen ? 20 : 24),
                
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(isSmallScreen ? 18 : 20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.25),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.security_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Security Notice',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isSmallScreen ? 16 : 17,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: isSmallScreen ? 12 : 16),
                      Text(
                        widget.message,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.95),
                          fontSize: isSmallScreen ? 14 : 15,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: isSmallScreen ? 16 : 20),
                
                Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        'Dismiss',
                        Colors.white.withValues(alpha: 0.2),
                        Colors.white,
                        _dismiss,
                        isSmallScreen,
                      ),
                    ),
                    SizedBox(width: isSmallScreen ? 12 : 16),
                    Expanded(
                      child: _buildActionButton(
                        'Got it!',
                        Colors.white,
                        const Color(0xFF3B82F6),
                        _dismiss,
                        isSmallScreen,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildConceptNotification(bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 20 : 24),
      decoration: BoxDecoration(
        color: _getBackgroundColor(),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _getBorderColor(),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: _getPrimaryColor().withValues(alpha: 0.1),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: _getPrimaryColor().withValues(alpha: 0.05),
            blurRadius: 40,
            spreadRadius: 0,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getPrimaryColor().withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _getPrimaryColor().withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Icon(
                  _getIcon(),
                  color: _getPrimaryColor(),
                  size: 28,
                ),
              ),
              SizedBox(width: isSmallScreen ? 16 : 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getTitle(),
                      style: TextStyle(
                        color: _getPrimaryColor(),
                        fontSize: isSmallScreen ? 18 : 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getSubtitle(),
                      style: TextStyle(
                        color: _getPrimaryColor().withValues(alpha: 0.7),
                        fontSize: isSmallScreen ? 14 : 15,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              _buildCloseButton(),
            ],
          ),
          
          SizedBox(height: isSmallScreen ? 20 : 24),
          
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(isSmallScreen ? 18 : 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _getBorderColor(),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: _getPrimaryColor().withValues(alpha: 0.05),
                  blurRadius: 10,
                  spreadRadius: 0,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              widget.message,
              style: TextStyle(
                color: const Color(0xFF374151),
                fontSize: isSmallScreen ? 14 : 15,
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          
          SizedBox(height: isSmallScreen ? 20 : 24),
          
          if (widget.actions != null && widget.actions!.isNotEmpty)
            ...widget.actions!.map((action) => _buildActionButton(
              action.label,
              action.isPrimary ? _getPrimaryColor() : Colors.white,
              action.isPrimary ? Colors.white : _getPrimaryColor(),
              action.onPressed ?? _dismiss,
              isSmallScreen,
            ))
          else
            _buildActionButton(
              'Got it!',
              _getPrimaryColor(),
              Colors.white,
              _dismiss,
              isSmallScreen,
            ),
        ],
      ),
    );
  }

  Widget _buildCloseButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
        onPressed: _dismiss,
        icon: Icon(
          Icons.close_rounded,
          color: Colors.white.withValues(alpha: 0.8),
          size: 20,
        ),
        padding: const EdgeInsets.all(8),
        constraints: const BoxConstraints(
          minWidth: 36,
          minHeight: 36,
        ),
        style: IconButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white.withValues(alpha: 0.8),
        ),
      ),
    );
  }

  Widget _buildActionButton(
    String label,
    Color backgroundColor,
    Color textColor,
    VoidCallback onTap,
    bool isSmallScreen,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: isSmallScreen ? 44 : 48,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: backgroundColor == Colors.white ? _getBorderColor() : Colors.transparent,
            width: 1.5,
          ),
          boxShadow: [
            if (backgroundColor != Colors.white)
              BoxShadow(
                color: backgroundColor.withValues(alpha: 0.3),
                blurRadius: 8,
                spreadRadius: 0,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: isSmallScreen ? 14 : 15,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.2,
            ),
          ),
        ),
      ),
    );
  }
}

enum MessageType {
  success,
  error,
  warning,
  info,
}

class DialogAction {
  final String label;
  final VoidCallback? onPressed;
  final bool isPrimary;

  const DialogAction({
    required this.label,
    this.onPressed,
    this.isPrimary = false,
  });
}

class MessageHelper {
  static void showAnimatedMessage(
    BuildContext context, {
    required String message,
    MessageType type = MessageType.info,
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onDismiss,
    bool isOTPNotification = false,
    String? title,
    List<DialogAction>? actions,
  }) {
    _removeExistingOverlays(context);

    late OverlayEntry overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (context) => AnimatedMessageDialog(
        message: message,
        type: type,
        duration: duration,
        onDismiss: () {
          overlayEntry.remove();
          onDismiss?.call();
        },
        isOTPNotification: isOTPNotification,
        title: title,
        actions: actions,
      ),
    );

    Overlay.of(context).insert(overlayEntry);
  }

  static void _removeExistingOverlays(BuildContext context) {
    // Simple approach - relies on auto-dismiss functionality
  }
} 