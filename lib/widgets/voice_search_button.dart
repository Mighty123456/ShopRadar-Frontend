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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
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
