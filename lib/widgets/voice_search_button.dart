import 'package:flutter/material.dart';
import '../services/voice_search_service.dart';

class VoiceSearchButton extends StatefulWidget {
  final Function(String) onVoiceResult;
  final Color? iconColor;
  final double? iconSize;
  final String? tooltip;

  const VoiceSearchButton({
    super.key,
    required this.onVoiceResult,
    this.iconColor,
    this.iconSize,
    this.tooltip,
  });

  @override
  State<VoiceSearchButton> createState() => _VoiceSearchButtonState();
}

class _VoiceSearchButtonState extends State<VoiceSearchButton>
    with TickerProviderStateMixin {
  bool _isListening = false;
  bool _isInitialized = false;
  bool _isInitializing = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _initializeVoiceSearch();
  }

  Future<void> _initializeVoiceSearch() async {
    debugPrint('Initializing voice search button...');
    setState(() {
      _isInitializing = true;
    });
    
    try {
      final isAvailable = await VoiceSearchService.isAvailable();
      debugPrint('Voice search available: $isAvailable');
      setState(() {
        _isInitialized = isAvailable;
        _isInitializing = false;
      });
    } catch (e) {
      debugPrint('Error initializing voice search: $e');
      setState(() {
        _isInitialized = false;
        _isInitializing = false;
      });
    }
  }

  Future<void> _startVoiceSearch() async {
    if (!_isInitialized) {
      // Try to reinitialize if not available
      debugPrint('Voice search not initialized, attempting to reinitialize...');
      await _initializeVoiceSearch();
      
      if (!_isInitialized) {
        _showErrorSnackBar('Voice search is not available. Please check microphone permissions.');
        return;
      }
    }

    if (_isListening) {
      await VoiceSearchService.stopListening();
      setState(() {
        _isListening = false;
      });
      _animationController.stop();
      return;
    }

    try {
      setState(() {
        _isListening = true;
      });
      _animationController.repeat(reverse: true);

      final result = await VoiceSearchService.startListening(
        timeout: const Duration(seconds: 10),
      );

      setState(() {
        _isListening = false;
      });
      _animationController.stop();

      if (result != null && result.isNotEmpty) {
        widget.onVoiceResult(result);
        _showSuccessSnackBar('Voice search: "$result"');
      } else {
        _showErrorSnackBar('No speech detected. Please try again.');
      }
    } catch (e) {
      setState(() {
        _isListening = false;
      });
      _animationController.stop();
      _showErrorSnackBar('Voice search failed: ${e.toString()}');
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _showSuccessSnackBar(String message) {
    if (mounted) {
      // Extract the search keyword from the message
      final keywordMatch = RegExp(r'"([^"]+)"').firstMatch(message);
      final keyword = keywordMatch?.group(1) ?? message.replaceAll('Voice search: "', '').replaceAll('"', '');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF10B981), // Green-500
                  Color(0xFF059669), // Green-600
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF10B981).withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.mic,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Voice Search',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        keyword,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          padding: EdgeInsets.zero,
          duration: const Duration(seconds: 3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          clipBehavior: Clip.antiAlias,
          dismissDirection: DismissDirection.horizontal,
        ),
      );
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: _isInitialized ? _startVoiceSearch : null,
      icon: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _isListening ? _scaleAnimation.value : 1.0,
            child: _isInitializing 
                ? SizedBox(
                    width: widget.iconSize ?? 20,
                    height: widget.iconSize ?? 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        widget.iconColor ?? Colors.grey,
                      ),
                    ),
                  )
                : Icon(
                    _isListening ? Icons.mic : Icons.mic_none,
                    color: _isListening 
                        ? Colors.red 
                        : (_isInitialized ? widget.iconColor : Colors.grey),
                    size: widget.iconSize,
                  ),
          );
        },
      ),
      tooltip: _isInitializing 
          ? 'Initializing voice search...'
          : _isListening 
              ? 'Stop listening' 
              : (_isInitialized ? (widget.tooltip ?? 'Voice search') : 'Voice search not available'),
    );
  }
}
