import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../config/cloudinary_config.dart';
import '../models/user_model.dart';
import '../widgets/custom_button.dart';
import '../widgets/animated_message_dialog.dart';
import '../services/profile_service.dart';
import '../services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with TickerProviderStateMixin {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  bool _isEditing = false;
  bool _isLoading = false;
  UserModel? _user;
  bool _isLoadingUser = true;
  
  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late AnimationController _pulseController;
  
  // Animations
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;
  
  // Interactive states
  bool _showStats = false;
  
  // Image picker and profile image
  final ImagePicker _imagePicker = ImagePicker();
  File? _profileImage;
  bool _isUploadingImage = false;
  String? _cloudinaryImageUrl;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeControllers();
  }
  
  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    // Start animations
    _fadeController.forward();
    _slideController.forward();
    _scaleController.forward();
  }

  void _initializeControllers() {
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = await AuthService.getUser();
      
      if (mounted) {
        if (user != null) {
          setState(() {
            _user = user;
            _fullNameController.text = user.fullName ?? '';
            _emailController.text = user.email;
            _isLoadingUser = false;
          });
          
          // Load existing profile image if available
          await _loadExistingProfileImage();
        } else {
          setState(() {
            _isLoadingUser = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingUser = false;
        });
      }
    }
  }
  
  Future<void> _loadExistingProfileImage() async {
    try {
      // Load the saved Cloudinary URL from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final cloudinaryUrl = prefs.getString('cloudinary_image_url');
      
      if (cloudinaryUrl != null && cloudinaryUrl.isNotEmpty) {
        setState(() {
          _cloudinaryImageUrl = cloudinaryUrl;
        });
        debugPrint('Loaded existing Cloudinary image: $cloudinaryUrl');
      }
    } catch (e) {
      debugPrint('Failed to load existing profile image: $e');
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _toggleEdit() {
    HapticFeedback.lightImpact();
    setState(() {
      _isEditing = !_isEditing;
      if (!_isEditing) {
        _initializeControllers(); // Reset to original values
      }
    });
    
    // Animate the scale controller for visual feedback
    _scaleController.reset();
    _scaleController.forward();
  }

  Future<void> _saveChanges() async {
    if (_fullNameController.text.trim().isEmpty) {
      HapticFeedback.heavyImpact();
      if (mounted) {
        MessageHelper.showAnimatedMessage(
          context,
          message: 'Full name cannot be empty',
          type: MessageType.error,
          title: 'Validation Error',
        );
      }
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() {
      _isLoading = true;
    });

    try {
      if (_user == null) {
        MessageHelper.showAnimatedMessage(
          context,
          message: 'No user data available. Please log in again.',
          type: MessageType.error,
          title: 'Error',
        );
        return;
      }

      final result = await ProfileService.updateProfile(
        userId: _user!.id,
        fullName: _fullNameController.text.trim(),
      );
      
      if (result['success']) {
        HapticFeedback.heavyImpact();
        if (mounted) {
          MessageHelper.showAnimatedMessage(
            context,
            message: 'Profile updated successfully!',
            type: MessageType.success,
            title: 'Success',
          );
          
          // Update the local user data
          if (result['user'] != null) {
            setState(() {
              _user = result['user'] as UserModel;
            });
          }
          
          setState(() {
            _isEditing = false;
            _isLoading = false;
          });
        }
      } else {
        HapticFeedback.heavyImpact();
        if (mounted) {
          MessageHelper.showAnimatedMessage(
            context,
            message: result['message'] ?? 'Failed to update profile',
            type: MessageType.error,
            title: 'Error',
          );
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      HapticFeedback.heavyImpact();
      if (mounted) {
        MessageHelper.showAnimatedMessage(
          context,
          message: 'Failed to update profile. Please try again.',
          type: MessageType.error,
          title: 'Error',
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  Future<void> _refreshProfile() async {
    HapticFeedback.lightImpact();
    
    try {
      await _loadUserData();
      // Add a small delay for better UX
      await Future.delayed(const Duration(milliseconds: 500));
    } catch (e) {
      // Handle error silently or show a message
    }
  }

  Future<void> _logout() async {
    if (!mounted) return;
    
    HapticFeedback.lightImpact();
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.of(context).pop(false);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              HapticFeedback.mediumImpact();
              Navigator.of(context).pop(true);
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await AuthService.logout();
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/auth');
        }
      } catch (e) {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/auth');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isLargeTablet = screenWidth > 900;
    final isPhone = screenWidth < 600;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFBFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        toolbarHeight: isLargeTablet ? 80 : (isTablet ? 70 : 56),
        title: Text(
          'Profile',
          style: TextStyle(
            color: const Color(0xFF1F2937),
            fontWeight: FontWeight.w600,
            fontSize: isLargeTablet ? 28 : (isTablet ? 24 : 20),
          ),
        ),
        // Only show back button if this screen is not used as a tab
        leading: Navigator.of(context).canPop() 
          ? IconButton(
              icon: Icon(
                Icons.arrow_back_ios,
                color: const Color(0xFF6B7280),
                size: isLargeTablet ? 24 : (isTablet ? 20 : 18),
              ),
              onPressed: () => Navigator.of(context).pop(),
            )
          : null,
        actions: [
          if (!_isEditing)
            Container(
              margin: const EdgeInsets.only(right: 8),
              child: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2979FF).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.edit_rounded,
                    color: const Color(0xFF2979FF),
                    size: isLargeTablet ? 20 : (isTablet ? 18 : 16),
                  ),
                ),
                onPressed: _toggleEdit,
              ),
            ),
        ],
      ),
      body: _isLoadingUser
          ? _buildSkeletonScreen(isLargeTablet, isTablet, isPhone)
          : _user == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.person_off,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No User Logged In',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Please log in to view your profile',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[500],
                        ),
                      ),
                      SizedBox(height: 24),
                      CustomButton(
                        text: 'Go to Login',
                        onPressed: () {
                          Navigator.of(context).pushReplacementNamed('/auth');
                        },
                      ),
                    ],
                  ),
                )
              : SafeArea(
                  child: RefreshIndicator(
                    onRefresh: _refreshProfile,
                    color: const Color(0xFF2979FF),
                    backgroundColor: Colors.white,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.all(isLargeTablet ? 32 : (isTablet ? 24 : 16)),
                      child: AnimatedBuilder(
                        animation: _fadeAnimation,
                        builder: (context, child) {
                          return FadeTransition(
                            opacity: _fadeAnimation,
                            child: SlideTransition(
                              position: _slideAnimation,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Profile Header
                                  _buildProfileHeader(_user!, isLargeTablet, isTablet, isPhone),
                                  
                                  SizedBox(height: isLargeTablet ? 40 : (isTablet ? 32 : 24)),
                                  
                                  // Interactive Stats Section
                                  _buildInteractiveStats(isLargeTablet, isTablet, isPhone),
                                  
                                  SizedBox(height: isLargeTablet ? 40 : (isTablet ? 32 : 24)),
                                  
                                  // Profile Information
                                  _buildProfileInfo(_user!, isLargeTablet, isTablet, isPhone),
                                  
                                  SizedBox(height: isLargeTablet ? 40 : (isTablet ? 32 : 24)),
                                  
                                  // Account Settings
                                  _buildAccountSettings(isLargeTablet, isTablet, isPhone),
                                  
                                  SizedBox(height: isLargeTablet ? 40 : (isTablet ? 32 : 24)),
                                  
                                  // Action Buttons
                                  _buildActionButtons(isLargeTablet, isTablet, isPhone),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
    );
  }
  
  Widget _buildSkeletonScreen(bool isLargeTablet, bool isTablet, bool isPhone) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(isLargeTablet ? 32 : (isTablet ? 24 : 16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Header Skeleton
            Center(
              child: Column(
                children: [
                  _buildSkeletonBox(
                    width: isLargeTablet ? 160 : (isTablet ? 140 : 120),
                    height: isLargeTablet ? 160 : (isTablet ? 140 : 120),
                    borderRadius: BorderRadius.circular(80),
                  ),
                  SizedBox(height: isLargeTablet ? 24 : (isTablet ? 20 : 16)),
                  _buildSkeletonBox(
                    width: 200,
                    height: isLargeTablet ? 32 : (isTablet ? 28 : 24),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  SizedBox(height: isLargeTablet ? 12 : (isTablet ? 8 : 6)),
                  _buildSkeletonBox(
                    width: 120,
                    height: isLargeTablet ? 18 : (isTablet ? 16 : 14),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: isLargeTablet ? 40 : (isTablet ? 32 : 24)),
            
            // Stats Skeleton
            _buildSkeletonBox(
              width: double.infinity,
              height: 200,
              borderRadius: BorderRadius.circular(20),
            ),
            
            SizedBox(height: isLargeTablet ? 40 : (isTablet ? 32 : 24)),
            
            // Profile Info Skeleton
            _buildSkeletonBox(
              width: double.infinity,
              height: 300,
              borderRadius: BorderRadius.circular(16),
            ),
            
            SizedBox(height: isLargeTablet ? 40 : (isTablet ? 32 : 24)),
            
            // Settings Skeleton
            _buildSkeletonBox(
              width: double.infinity,
              height: 400,
              borderRadius: BorderRadius.circular(16),
            ),
            
            SizedBox(height: isLargeTablet ? 40 : (isTablet ? 32 : 24)),
            
            // Action Buttons Skeleton
            _buildSkeletonBox(
              width: double.infinity,
              height: isLargeTablet ? 56 : (isTablet ? 52 : 48),
              borderRadius: BorderRadius.circular(12),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSkeletonBox({
    required double width,
    required double height,
    required BorderRadius borderRadius,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: borderRadius,
      ),
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              borderRadius: borderRadius,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.grey.shade300,
                  Colors.grey.shade200,
                  Colors.grey.shade300,
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          );
        },
      ),
    );
  }
  
  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (image != null) {
        await _uploadImage(File(image.path));
      }
    } catch (e) {
      if (mounted) {
        MessageHelper.showAnimatedMessage(
          context,
          message: 'Failed to access camera: ${e.toString()}',
          type: MessageType.error,
          title: 'Camera Error',
        );
      }
    }
  }
  
  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (image != null) {
        await _uploadImage(File(image.path));
      }
    } catch (e) {
      if (mounted) {
        MessageHelper.showAnimatedMessage(
          context,
          message: 'Failed to access gallery: ${e.toString()}',
          type: MessageType.error,
          title: 'Gallery Error',
        );
      }
    }
  }
  
  // Generate Cloudinary signature for signed uploads
  String _generateSignature(Map<String, String> params) {
    // Sort parameters by key
    final sortedParams = Map.fromEntries(
      params.entries.toList()..sort((a, b) => a.key.compareTo(b.key))
    );
    
    // Create query string
    final queryString = sortedParams.entries
        .map((e) => '${e.key}=${e.value}')
        .join('&');
    
    // Add API secret to the end (no separator)
    final stringToSign = '$queryString${CloudinaryConfig.apiSecret}';
    
    // Generate SHA1 hash
    final bytes = utf8.encode(stringToSign);
    final digest = sha1.convert(bytes);
    
    return digest.toString();
  }

  Future<void> _uploadImage(File imageFile) async {
    setState(() {
      _isUploadingImage = true;
    });
    
    HapticFeedback.lightImpact();
    
    try {
      // Read the image file
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);
      
      // Generate unique public ID
      final publicId = 'profile_${_user?.id ?? 'user'}_${DateTime.now().millisecondsSinceEpoch}';
      
      // Upload to Cloudinary using HTTP request
      final uploadUrl = 'https://api.cloudinary.com/v1_1/${CloudinaryConfig.cloudName}/image/upload';
      
      // Prepare parameters for signature generation
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final params = {
        'public_id': publicId,
        'folder': 'shopradar/profiles',
        'timestamp': timestamp,
      };
      
      // Generate signature
      final signature = _generateSignature(params);
      
      // Debug: Print signature details
      print('🔍 Signature Debug:');
      print('  - Params: $params');
      print('  - Query String: ${params.entries.map((e) => '${e.key}=${e.value}').join('&')}');
      print('  - String to sign: ${params.entries.map((e) => '${e.key}=${e.value}').join('&')}${CloudinaryConfig.apiSecret}');
      print('  - Generated signature: $signature');
      
      final requestBody = {
        'file': 'data:image/jpeg;base64,$base64Image',
        'public_id': publicId,
        'folder': 'shopradar/profiles',
        'timestamp': timestamp,
        'api_key': CloudinaryConfig.apiKey,
        'signature': signature,
      };
      
      final response = await http.post(
        Uri.parse(uploadUrl),
        body: requestBody,
      );
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        setState(() {
          _cloudinaryImageUrl = responseData['public_id'];
          _isUploadingImage = false;
        });
        
        // Save the Cloudinary URL to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('cloudinary_image_url', responseData['public_id']);
        
        if (mounted) {
          MessageHelper.showAnimatedMessage(
            context,
            message: 'Profile picture uploaded to cloud successfully!',
            type: MessageType.success,
            title: 'Success',
          );
        }
      } else {
        throw Exception('Upload failed: ${response.body}');
      }
    } catch (e) {
      setState(() {
        _isUploadingImage = false;
      });
      
      if (mounted) {
        MessageHelper.showAnimatedMessage(
          context,
          message: 'Failed to upload image to cloud: ${e.toString()}',
          type: MessageType.error,
          title: 'Upload Error',
        );
      }
    }
  }
  
  Future<void> _removeProfileImage() async {
    HapticFeedback.lightImpact();
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Profile Picture'),
        content: const Text('Are you sure you want to remove your profile picture?'),
        actions: [
          TextButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.of(context).pop(false);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              HapticFeedback.mediumImpact();
              Navigator.of(context).pop(true);
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    
    if (confirmed == true && mounted) {
      // Delete the image from Cloudinary using HTTP request
      if (_cloudinaryImageUrl != null) {
        try {
          final deleteUrl = 'https://api.cloudinary.com/v1_1/${CloudinaryConfig.cloudName}/image/destroy';
          
          final response = await http.post(
            Uri.parse(deleteUrl),
            body: {
              'public_id': _cloudinaryImageUrl!,
              'api_key': CloudinaryConfig.apiKey,
              'api_secret': CloudinaryConfig.apiSecret,
            },
          );
          
          if (response.statusCode == 200) {
            debugPrint('Profile image deleted from Cloudinary');
          } else {
            debugPrint('Failed to delete image from Cloudinary: ${response.body}');
          }
        } catch (e) {
          debugPrint('Failed to delete image from Cloudinary: $e');
        }
      }
      
      setState(() {
        _cloudinaryImageUrl = null;
      });
      
      // Remove the saved Cloudinary URL from SharedPreferences
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('cloudinary_image_url');
        debugPrint('Cloudinary image URL removed from preferences');
      } catch (e) {
        debugPrint('Failed to remove image URL from preferences: $e');
      }
      
      if (mounted) {
        MessageHelper.showAnimatedMessage(
          context,
          message: 'Profile picture removed from cloud successfully!',
          type: MessageType.success,
          title: 'Removed',
        );
      }
    }
  }
  
  Future<void> _showStorageInfo() async {
    try {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Cloud Storage Information'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Storage Provider:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('Cloudinary Cloud Storage'),
                const SizedBox(height: 16),
                Text('Cloud Name:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(CloudinaryConfig.cloudName),
                const SizedBox(height: 16),
                Text('Folder:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('shopradar/profiles'),
                const SizedBox(height: 16),
                if (_cloudinaryImageUrl != null) ...[
                  Text('Current Image ID:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(_cloudinaryImageUrl!),
                  const SizedBox(height: 8),
                  Text('Image URL:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('https://res.cloudinary.com/your_cloud_name/image/upload/$_cloudinaryImageUrl'),
                ] else ...[
                  Text('No image uploaded yet', style: TextStyle(color: Colors.grey)),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      debugPrint('Failed to get storage info: $e');
    }
  }
  
  String _getCloudinaryImageUrl(String publicId) {
    // Generate Cloudinary URL with transformations
    return 'https://res.cloudinary.com/${CloudinaryConfig.cloudName}/image/upload/w_400,h_400,c_fill,g_face,q_auto,f_auto/$publicId';
  }

  Widget _buildInitialsAvatar(UserModel user, bool isLargeTablet, bool isTablet) {
    // Get user initials from full name or email
    String nameToUse = user.fullName ?? user.email;
    String initials = _getUserInitials(nameToUse);
    
    // Generate a color based on the user's name for consistency
    Color avatarColor = _getAvatarColor(nameToUse);
    
    return Container(
      width: isLargeTablet ? 140 : (isTablet ? 120 : 100),
      height: isLargeTablet ? 140 : (isTablet ? 120 : 100),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            avatarColor,
            avatarColor.withValues(alpha: 0.8),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: avatarColor.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            fontSize: isLargeTablet ? 48 : (isTablet ? 42 : 36),
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }
  
  String _getUserInitials(String name) {
    if (name.isEmpty) return 'U';
    
    // Split by spaces and get first letter of each word
    List<String> words = name.trim().split(' ');
    
    if (words.length == 1) {
      // Single name - take first two letters
      String word = words[0];
      if (word.length >= 2) {
        return word.substring(0, 2).toUpperCase();
      }
      return word.substring(0, 1).toUpperCase();
    } else {
      // Multiple words - take first letter of first two words
      String firstInitial = words[0].isNotEmpty ? words[0][0].toUpperCase() : '';
      String secondInitial = words.length > 1 && words[1].isNotEmpty 
          ? words[1][0].toUpperCase() 
          : '';
      return firstInitial + secondInitial;
    }
  }
  
  Color _getAvatarColor(String name) {
    // Generate a consistent color based on the name
    int hash = name.hashCode;
    
    // Use the hash to generate a color
    List<Color> colors = [
      const Color(0xFF2979FF), // Blue
      const Color(0xFF10B981), // Green
      const Color(0xFFF59E0B), // Orange
      const Color(0xFFEF4444), // Red
      const Color(0xFF8B5CF6), // Purple
      const Color(0xFF06B6D4), // Cyan
      const Color(0xFF84CC16), // Lime
      const Color(0xFFEC4899), // Pink
    ];
    
    return colors[hash.abs() % colors.length];
  }

  Widget _buildProfileHeader(UserModel user, bool isLargeTablet, bool isTablet, bool isPhone) {
    return Center(
      child: Column(
        children: [
          // Interactive Profile Picture
          Semantics(
            label: 'Profile picture. Tap to change photo.',
            hint: 'Double tap to open camera or gallery options',
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                _showProfilePictureOptions();
              },
              child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Container(
                    width: isLargeTablet ? 160 : (isTablet ? 140 : 120),
                    height: isLargeTablet ? 160 : (isTablet ? 140 : 120),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFFE3F2FD),
                          Color(0xFFBBDEFB),
                        ],
                      ),
                      border: Border.all(
                        color: const Color(0xFF2979FF).withValues(alpha: 0.2),
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2979FF).withValues(alpha: 0.1),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: _cloudinaryImageUrl != null
                              ? ClipOval(
                                  child: Image.network(
                                    _getCloudinaryImageUrl(_cloudinaryImageUrl!),
                                    width: isLargeTablet ? 140 : (isTablet ? 120 : 100),
                                    height: isLargeTablet ? 140 : (isTablet ? 120 : 100),
                                    fit: BoxFit.cover,
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Container(
                                        width: isLargeTablet ? 140 : (isTablet ? 120 : 100),
                                        height: isLargeTablet ? 140 : (isTablet ? 120 : 100),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.grey.shade200,
                                        ),
                                        child: Center(
                                          child: CircularProgressIndicator(
                                            value: loadingProgress.expectedTotalBytes != null
                                                ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                                : null,
                                          ),
                                        ),
                                      );
                                    },
                                    errorBuilder: (context, error, stackTrace) {
                                      return _buildInitialsAvatar(user, isLargeTablet, isTablet);
                                    },
                                  ),
                                )
                              : _buildInitialsAvatar(user, isLargeTablet, isTablet),
                        ),
                        Positioned(
                          bottom: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF2979FF).withValues(alpha: 0.2),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF2979FF).withValues(alpha: 0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: _isUploadingImage
                                ? SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        const Color(0xFF2979FF),
                                      ),
                                    ),
                                  )
                                : Icon(
                                    Icons.camera_alt_rounded,
                                    size: 18,
                                    color: const Color(0xFF2979FF),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          ),
          
          SizedBox(height: isLargeTablet ? 24 : (isTablet ? 20 : 16)),
          
          // User Name with animation
          AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Text(
                  user.fullName ?? 'User',
                  style: TextStyle(
                    fontSize: isLargeTablet ? 32 : (isTablet ? 28 : 24),
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1F2937),
                  ),
                  textAlign: TextAlign.center,
                ),
              );
            },
          ),
          
          SizedBox(height: isLargeTablet ? 12 : (isTablet ? 8 : 6)),
          
          // User Role with enhanced styling
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isLargeTablet ? 20 : (isTablet ? 16 : 12),
              vertical: isLargeTablet ? 8 : (isTablet ? 6 : 4),
            ),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE3F2FD), Color(0xFFBBDEFB)],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF2979FF),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2979FF).withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              user.role ?? 'User',
              style: TextStyle(
                fontSize: isLargeTablet ? 18 : (isTablet ? 16 : 14),
                fontWeight: FontWeight.w600,
                color: const Color(0xFF2979FF),
              ),
            ),
          ),
          
          SizedBox(height: isLargeTablet ? 8 : (isTablet ? 6 : 4)),
          
          // Email Verification Status with enhanced styling
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isLargeTablet ? 16 : (isTablet ? 12 : 8),
              vertical: isLargeTablet ? 8 : (isTablet ? 6 : 4),
            ),
            decoration: BoxDecoration(
              color: user.isEmailVerified ? Colors.green.shade50 : Colors.orange.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: user.isEmailVerified ? Colors.green.shade200 : Colors.orange.shade200,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  user.isEmailVerified ? Icons.verified : Icons.warning,
                  color: user.isEmailVerified ? Colors.green : Colors.orange,
                  size: isLargeTablet ? 24 : (isTablet ? 20 : 16),
                ),
                SizedBox(width: isLargeTablet ? 8 : (isTablet ? 6 : 4)),
                Text(
                  user.isEmailVerified ? 'Email Verified' : 'Email Not Verified',
                  style: TextStyle(
                    fontSize: isLargeTablet ? 16 : (isTablet ? 14 : 12),
                    color: user.isEmailVerified ? Colors.green.shade700 : Colors.orange.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  void _showProfilePictureOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Change Profile Picture',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1F2937),
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildOptionTile(
              icon: Icons.camera_alt_rounded,
              title: 'Take Photo',
              subtitle: 'Use camera to take a new photo',
              color: const Color(0xFF2979FF),
              onTap: () {
                Navigator.pop(context);
                _pickImageFromCamera();
              },
            ),
            _buildOptionTile(
              icon: Icons.photo_library_rounded,
              title: 'Choose from Gallery',
              subtitle: 'Select from your photo library',
              color: const Color(0xFF10B981),
              onTap: () {
                Navigator.pop(context);
                _pickImageFromGallery();
              },
            ),
            if (_profileImage != null)
              _buildOptionTile(
                icon: Icons.remove_circle_rounded,
                title: 'Remove Photo',
                subtitle: 'Remove current profile picture',
                color: const Color(0xFFEF4444),
                onTap: () {
                  Navigator.pop(context);
                  _removeProfileImage();
                },
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
  
  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: const Color(0xFF9CA3AF),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildInteractiveStats(bool isLargeTablet, bool isTablet, bool isPhone) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isLargeTablet ? 24 : (isTablet ? 20 : 16)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2979FF).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.analytics_rounded,
                  color: const Color(0xFF2979FF),
                  size: isLargeTablet ? 24 : (isTablet ? 20 : 18),
                ),
              ),
              SizedBox(width: isLargeTablet ? 12 : (isTablet ? 8 : 6)),
              Text(
                'Your Activity',
                style: TextStyle(
                  fontSize: isLargeTablet ? 24 : (isTablet ? 20 : 18),
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1F2937),
                ),
              ),
              const Spacer(),
              Semantics(
                label: 'Activity statistics. Currently ${_showStats ? 'expanded' : 'collapsed'}.',
                hint: 'Double tap to ${_showStats ? 'collapse' : 'expand'} statistics',
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() {
                      _showStats = !_showStats;
                    });
                  },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFFE5E7EB),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    _showStats ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                    color: const Color(0xFF6B7280),
                    size: 20,
                  ),
                ),
              ),
              ),
            ],
          ),
          
          SizedBox(height: isLargeTablet ? 20 : (isTablet ? 16 : 12)),
          
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: _showStats ? null : 0,
            child: _showStats ? Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Searches',
                        '24',
                        Icons.search_rounded,
                        const Color(0xFF2979FF),
                        isLargeTablet,
                        isTablet,
                      ),
                    ),
                    SizedBox(width: isLargeTablet ? 16 : (isTablet ? 12 : 8)),
                    Expanded(
                      child: _buildStatCard(
                        'Favorites',
                        '12',
                        Icons.favorite_rounded,
                        const Color(0xFF2979FF),
                        isLargeTablet,
                        isTablet,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isLargeTablet ? 16 : (isTablet ? 12 : 8)),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Reviews',
                        '8',
                        Icons.rate_review_rounded,
                        const Color(0xFF2979FF),
                        isLargeTablet,
                        isTablet,
                      ),
                    ),
                    SizedBox(width: isLargeTablet ? 16 : (isTablet ? 12 : 8)),
                    Expanded(
                      child: _buildStatCard(
                        'Visits',
                        '45',
                        Icons.location_on_rounded,
                        const Color(0xFF2979FF),
                        isLargeTablet,
                        isTablet,
                      ),
                    ),
                  ],
                ),
              ],
            ) : null,
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatCard(String label, String value, IconData icon, Color color, bool isLargeTablet, bool isTablet) {
    return Container(
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
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF2979FF).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF2979FF),
              size: isLargeTablet ? 20 : (isTablet ? 18 : 16),
            ),
          ),
          SizedBox(height: isLargeTablet ? 8 : (isTablet ? 6 : 4)),
          Text(
            value,
            style: TextStyle(
              fontSize: isLargeTablet ? 20 : (isTablet ? 18 : 16),
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1F2937),
            ),
          ),
          SizedBox(height: isLargeTablet ? 4 : (isTablet ? 2 : 1)),
          Text(
            label,
            style: TextStyle(
              fontSize: isLargeTablet ? 14 : (isTablet ? 12 : 10),
              color: const Color(0xFF6B7280),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileInfo(UserModel user, bool isLargeTablet, bool isTablet, bool isPhone) {
    return Container(
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
            'Profile Information',
            style: TextStyle(
              fontSize: isLargeTablet ? 24 : (isTablet ? 20 : 18),
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1F2937),
            ),
          ),
          
          SizedBox(height: isLargeTablet ? 24 : (isTablet ? 20 : 16)),
          
          // Full Name Field
          _buildInfoField(
            label: 'Full Name',
            controller: _fullNameController,
            icon: Icons.person,
            isEditing: _isEditing,
            isLargeTablet: isLargeTablet,
            isTablet: isTablet,
            isPhone: isPhone,
          ),
          
          SizedBox(height: isLargeTablet ? 20 : (isTablet ? 16 : 12)),
          
          // Email Field
          _buildInfoField(
            label: 'Email',
            controller: _emailController,
            icon: Icons.email,
            isEditing: false, // Email should not be editable
            isLargeTablet: isLargeTablet,
            isTablet: isTablet,
            isPhone: isPhone,
          ),
          
          SizedBox(height: isLargeTablet ? 20 : (isTablet ? 16 : 12)),
          
          // Role Field
          _buildInfoField(
            label: 'Role',
            value: user.role ?? 'User',
            icon: Icons.work,
            isEditing: false, // Role should not be editable
            isLargeTablet: isLargeTablet,
            isTablet: isTablet,
            isPhone: isPhone,
          ),
          
          SizedBox(height: isLargeTablet ? 20 : (isTablet ? 16 : 12)),
          
          // Member Since Field
          _buildInfoField(
            label: 'Member Since',
            value: user.createdAt != null 
                ? '${user.createdAt!.day}/${user.createdAt!.month}/${user.createdAt!.year}'
                : 'N/A',
            icon: Icons.calendar_today,
            isEditing: false,
            isLargeTablet: isLargeTablet,
            isTablet: isTablet,
            isPhone: isPhone,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoField({
    required String label,
    TextEditingController? controller,
    String? value,
    required IconData icon,
    required bool isEditing,
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
        
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(
            horizontal: isLargeTablet ? 16 : (isTablet ? 12 : 8),
            vertical: isLargeTablet ? 16 : (isTablet ? 12 : 8),
          ),
          decoration: BoxDecoration(
            color: isEditing ? Colors.white : const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isEditing ? const Color(0xFF2979FF) : const Color(0xFFE5E7EB),
              width: isEditing ? 2 : 1,
            ),
            boxShadow: isEditing ? [
              BoxShadow(
                color: const Color(0xFF2979FF).withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ] : null,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isEditing ? const Color(0xFF2979FF).withValues(alpha: 0.1) : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: isEditing ? const Color(0xFF2979FF) : const Color(0xFF6B7280),
                  size: isLargeTablet ? 24 : (isTablet ? 20 : 16),
                ),
              ),
              
              SizedBox(width: isLargeTablet ? 16 : (isTablet ? 12 : 8)),
              
              Expanded(
                child: isEditing && controller != null
                    ? TextField(
                        controller: controller,
                        style: TextStyle(
                          fontSize: isLargeTablet ? 16 : (isTablet ? 14 : 12),
                          color: const Color(0xFF1F2937),
                        ),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Enter your full name',
                          hintStyle: TextStyle(
                            color: const Color(0xFF9CA3AF),
                            fontSize: isLargeTablet ? 16 : (isTablet ? 14 : 12),
                          ),
                        ),
                        onChanged: (value) {
                          // Add subtle haptic feedback for typing
                          if (value.length % 5 == 0 && value.isNotEmpty) {
                            HapticFeedback.selectionClick();
                          }
                        },
                      )
                    : Text(
                        value ?? controller?.text ?? '',
                        style: TextStyle(
                          fontSize: isLargeTablet ? 16 : (isTablet ? 14 : 12),
                          color: const Color(0xFF1F2937),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
              ),
              
              if (isEditing && controller != null)
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    controller.clear();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      Icons.clear,
                      size: 16,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAccountSettings(bool isLargeTablet, bool isTablet, bool isPhone) {
    return Container(
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
            'Account Settings',
            style: TextStyle(
              fontSize: isLargeTablet ? 24 : (isTablet ? 20 : 18),
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1F2937),
            ),
          ),
          
          SizedBox(height: isLargeTablet ? 24 : (isTablet ? 20 : 16)),
          
          _buildSettingItem(
            icon: Icons.lock,
            title: 'Change Password',
            subtitle: 'Update your account password',
            onTap: () {
              Navigator.of(context).pushNamed('/change-password');
            },
            isLargeTablet: isLargeTablet,
            isTablet: isTablet,
            isPhone: isPhone,
          ),
          
          SizedBox(height: isLargeTablet ? 16 : (isTablet ? 12 : 8)),
          
          _buildSettingItem(
            icon: Icons.notifications,
            title: 'Notifications',
            subtitle: 'Manage your notification preferences',
            onTap: () {
              // TODO: Navigate to notifications screen
            },
            isLargeTablet: isLargeTablet,
            isTablet: isTablet,
            isPhone: isPhone,
          ),
          
          SizedBox(height: isLargeTablet ? 16 : (isTablet ? 12 : 8)),
          
          _buildSettingItem(
            icon: Icons.privacy_tip,
            title: 'Privacy & Security',
            subtitle: 'Manage your privacy settings',
            onTap: () {
              // TODO: Navigate to privacy screen
            },
            isLargeTablet: isLargeTablet,
            isTablet: isTablet,
            isPhone: isPhone,
          ),
          
          SizedBox(height: isLargeTablet ? 16 : (isTablet ? 12 : 8)),
          
          _buildSettingItem(
            icon: Icons.help,
            title: 'Help & Support',
            subtitle: 'Get help and contact support',
            onTap: () {
              // TODO: Navigate to help screen
            },
            isLargeTablet: isLargeTablet,
            isTablet: isTablet,
            isPhone: isPhone,
          ),
          
          SizedBox(height: isLargeTablet ? 16 : (isTablet ? 12 : 8)),
          
          _buildSettingItem(
            icon: Icons.storage,
            title: 'Storage Info',
            subtitle: 'View photo storage location and details',
            onTap: _showStorageInfo,
            isLargeTablet: isLargeTablet,
            isTablet: isTablet,
            isPhone: isPhone,
          ),
          
          SizedBox(height: isLargeTablet ? 16 : (isTablet ? 12 : 8)),
        ],
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool isLargeTablet,
    required bool isTablet,
    required bool isPhone,
  }) {
    return Dismissible(
      key: Key('setting_$title'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite,
              color: Colors.red.shade400,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              'Quick',
              style: TextStyle(
                color: Colors.red.shade400,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        HapticFeedback.mediumImpact();
        return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Quick Action'),
            content: Text('Add "$title" to favorites for quick access?'),
            actions: [
              TextButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.of(context).pop(false);
                },
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  HapticFeedback.heavyImpact();
                  Navigator.of(context).pop(true);
                },
                child: const Text('Add'),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) {
        MessageHelper.showAnimatedMessage(
          context,
          message: 'Added "$title" to favorites!',
          type: MessageType.success,
          title: 'Quick Action',
        );
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: EdgeInsets.all(isLargeTablet ? 20 : (isTablet ? 16 : 12)),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFE5E7EB),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(isLargeTablet ? 12 : (isTablet ? 10 : 8)),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE3F2FD), Color(0xFFBBDEFB)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: const Color(0xFF2979FF),
                    size: isLargeTablet ? 24 : (isTablet ? 20 : 16),
                  ),
                ),
                
                SizedBox(width: isLargeTablet ? 16 : (isTablet ? 12 : 8)),
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: isLargeTablet ? 18 : (isTablet ? 16 : 14),
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1F2937),
                        ),
                      ),
                      
                      SizedBox(height: isLargeTablet ? 4 : (isTablet ? 2 : 1)),
                      
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: isLargeTablet ? 14 : (isTablet ? 12 : 10),
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios,
                    color: const Color(0xFF6B7280),
                    size: isLargeTablet ? 20 : (isTablet ? 16 : 14),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(bool isLargeTablet, bool isTablet, bool isPhone) {
    return Column(
      children: [
        if (_isEditing) ...[
          // Save Button with enhanced animation
          AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _isLoading ? 0.95 : _scaleAnimation.value,
                child: SizedBox(
                  width: double.infinity,
                  child: CustomButton(
                    text: _isLoading ? 'Saving...' : 'Save Changes',
                    onPressed: _isLoading ? null : () {
                      HapticFeedback.mediumImpact();
                      _saveChanges();
                    },
                    height: isLargeTablet ? 56 : (isTablet ? 52 : 48),
                  ),
                ),
              );
            },
          ),
          
          SizedBox(height: isLargeTablet ? 16 : (isTablet ? 12 : 8)),
          
          // Cancel Button with enhanced styling
          SizedBox(
            width: double.infinity,
            child: CustomButton(
              text: 'Cancel',
              onPressed: () {
                HapticFeedback.lightImpact();
                _toggleEdit();
              },
              isPrimary: false,
              height: isLargeTablet ? 56 : (isTablet ? 52 : 48),
            ),
          ),
          
          SizedBox(height: isLargeTablet ? 24 : (isTablet ? 20 : 16)),
        ],
        
        // Logout Button with enhanced styling
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFE5E7EB),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                _logout();
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                height: isLargeTablet ? 56 : (isTablet ? 52 : 48),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.logout_rounded,
                        color: const Color(0xFFEF4444),
                        size: isLargeTablet ? 20 : (isTablet ? 18 : 16),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Logout',
                      style: TextStyle(
                        fontSize: isLargeTablet ? 16 : (isTablet ? 15 : 14),
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFEF4444),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
