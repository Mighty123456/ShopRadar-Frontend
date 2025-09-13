import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onFinish;
  const OnboardingScreen({super.key, required this.onFinish});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> with TickerProviderStateMixin {
  final PageController _controller = PageController();
  int _currentPage = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final List<_OnboardingStep> _steps = [
    _OnboardingStep(
      title: 'Welcome to ShopRadar',
      description: 'Your smart shopping companion that helps you find the best deals and track prices across all your favorite stores.',
      svgAsset: 'assets/images/onboarding_radar.svg',
      fallbackIcon: Icons.radar,
      color: Color(0xFF2979FF),
    ),
    _OnboardingStep(
      title: 'Find the Best Deals',
      description: 'Discover nearby stores, compare prices, and get personalized recommendations based on your shopping preferences.',
      svgAsset: 'assets/images/onboarding_deals.svg',
      fallbackIcon: Icons.local_offer,
      color: Color(0xFFFF6B35),
    ),
    _OnboardingStep(
      title: 'Track Price History',
      description: 'Monitor price changes, set alerts for your favorite products, and never miss a great deal again.',
      svgAsset: 'assets/images/onboarding_analytics.svg',
      fallbackIcon: Icons.analytics,
      color: Color(0xFF2DD4BF),
    ),
    _OnboardingStep(
      title: 'Smart Shopping List',
      description: 'Organize your shopping needs, get reminders, and find the best prices for items on your list.',
      svgAsset: 'assets/images/onboarding_shopping.svg',
      fallbackIcon: Icons.shopping_cart,
      color: Color(0xFF10B981),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _finishOnboarding() {
    widget.onFinish();
  }

  void _nextPage() {
    if (_currentPage < _steps.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
      _animationController.reset();
      _animationController.forward();
    } else {
      _finishOnboarding();
    }
  }

  Widget _buildImageWidget(_OnboardingStep step, double size) {
    return SvgPicture.asset(
      step.svgAsset,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return Icon(
          step.fallbackIcon,
          size: size * 0.6,
          color: step.color,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;
    final isLargeScreen = size.width > 900;
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: EdgeInsets.all(isTablet ? 24.0 : 16.0),
                child: TextButton(
                  onPressed: _finishOnboarding,
                  child: Text(
                    'Skip',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: isTablet ? 18 : (isLargeScreen ? 20 : 16),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
            
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _steps.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                  _animationController.reset();
                  _animationController.forward();
                },
                itemBuilder: (context, index) {
                  final step = _steps[index];
                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: isTablet ? 48.0 : 32.0),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: SlideTransition(
                            position: _slideAnimation,
                            child: Container(
                              width: isTablet ? size.width * 0.5 : size.width * 0.6,
                              height: isTablet ? size.width * 0.5 : size.width * 0.6,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    step.color.withValues(alpha: 0.1),
                                    step.color.withValues(alpha: 0.05),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(isTablet ? 32 : 24),
                                border: Border.all(
                                  color: step.color.withValues(alpha: 0.2),
                                  width: 2,
                                ),
                              ),
                              child: Padding(
                                padding: EdgeInsets.all(isTablet ? 32.0 : 20.0),
                                child: _buildImageWidget(step, isTablet ? size.width * 0.3 : size.width * 0.4),
                              ),
                            ),
                          ),
                        ),
                        
                        SizedBox(height: isTablet ? 48 : 32),
                        
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: SlideTransition(
                            position: _slideAnimation,
                            child: Text(
                              step.title,
                              style: TextStyle(
                                fontSize: isTablet ? 36 : (isLargeScreen ? 40 : 28),
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                                height: 1.2,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        
                        SizedBox(height: isTablet ? 24 : 16),
                        
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: SlideTransition(
                            position: _slideAnimation,
                            child: Text(
                              step.description,
                              style: TextStyle(
                                fontSize: isTablet ? 20 : (isLargeScreen ? 22 : 16),
                                color: Colors.grey[600],
                                height: 1.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                  );
                },
              ),
            ),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_steps.length, (index) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: EdgeInsets.symmetric(
                    horizontal: isTablet ? 6 : 4, 
                    vertical: isTablet ? 20 : 16
                  ),
                  width: _currentPage == index ? (isTablet ? 40 : 32) : (isTablet ? 12 : 8),
                  height: isTablet ? 12 : 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? _steps[_currentPage].color
                        : Colors.grey[300],
                    borderRadius: BorderRadius.circular(isTablet ? 6 : 4),
                  ),
                );
              }),
            ),
            
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 48.0 : 32.0, 
                vertical: isTablet ? 32.0 : 24.0
              ),
              child: Row(
                children: [
                  if (_currentPage > 0)
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            vertical: isTablet ? 20 : 16,
                            horizontal: isTablet ? 24 : 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
                          ),
                          side: BorderSide(color: Colors.grey[300]!),
                        ),
                        onPressed: () {
                          _controller.previousPage(
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeInOut,
                          );
                        },
                        child: Text(
                          'Previous',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: isTablet ? 16 : 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  
                  if (_currentPage > 0) SizedBox(width: isTablet ? 20 : 16),
                  
                  Expanded(
                    flex: _currentPage > 0 ? 1 : 1,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _steps[_currentPage].color,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          vertical: isTablet ? 20 : 16,
                          horizontal: isTablet ? 24 : 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
                        ),
                        elevation: 2,
                      ),
                      onPressed: _nextPage,
                      child: Text(
                        _currentPage == _steps.length - 1 ? 'Get Started' : 'Next',
                        style: TextStyle(
                          fontSize: isTablet ? 16 : 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingStep {
  final String title;
  final String description;
  final String svgAsset;
  final IconData fallbackIcon;
  final Color color;
  
  const _OnboardingStep({
    required this.title,
    required this.description,
    required this.svgAsset,
    required this.fallbackIcon,
    required this.color,
  });
} 