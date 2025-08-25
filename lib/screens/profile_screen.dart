import 'package:flutter/material.dart';
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

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  bool _isEditing = false;
  bool _isLoading = false;
  UserModel? _user;
  bool _isLoadingUser = true;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
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

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _toggleEdit() {
    setState(() {
      _isEditing = !_isEditing;
      if (!_isEditing) {
        _initializeControllers(); // Reset to original values
      }
    });
  }

  Future<void> _saveChanges() async {
    if (_fullNameController.text.trim().isEmpty) {
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

  Future<void> _logout() async {
    if (!mounted) return;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
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
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2979FF),
        elevation: 0,
        toolbarHeight: isLargeTablet ? 80 : (isTablet ? 70 : 56),
        title: Text(
          'Profile',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: isLargeTablet ? 28 : (isTablet ? 24 : 20),
          ),
        ),
        // Only show back button if this screen is not used as a tab
        leading: Navigator.of(context).canPop() 
          ? IconButton(
              icon: Icon(
                Icons.arrow_back,
                color: Colors.white,
                size: isLargeTablet ? 32 : (isTablet ? 28 : 24),
              ),
              onPressed: () => Navigator.of(context).pop(),
            )
          : null,
        actions: [
          if (!_isEditing)
            IconButton(
              icon: Icon(
                Icons.edit,
                color: Colors.white,
                size: isLargeTablet ? 32 : (isTablet ? 28 : 24),
              ),
              onPressed: _toggleEdit,
            ),
        ],
      ),
      body: _isLoadingUser
          ? const Center(
              child: CircularProgressIndicator(),
            )
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
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(isLargeTablet ? 32 : (isTablet ? 24 : 16)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Profile Header
                        _buildProfileHeader(_user!, isLargeTablet, isTablet, isPhone),
                        
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
                ),
    );
  }

  Widget _buildProfileHeader(UserModel user, bool isLargeTablet, bool isTablet, bool isPhone) {
    return Center(
      child: Column(
        children: [
          // Profile Picture
          Container(
            width: isLargeTablet ? 160 : (isTablet ? 140 : 120),
            height: isLargeTablet ? 160 : (isTablet ? 140 : 120),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF2979FF),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Icon(
              Icons.person,
              size: isLargeTablet ? 80 : (isTablet ? 70 : 60),
              color: Colors.white,
            ),
          ),
          
          SizedBox(height: isLargeTablet ? 24 : (isTablet ? 20 : 16)),
          
          // User Name
          Text(
            user.fullName ?? 'User',
            style: TextStyle(
              fontSize: isLargeTablet ? 32 : (isTablet ? 28 : 24),
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1F2937),
            ),
            textAlign: TextAlign.center,
          ),
          
          SizedBox(height: isLargeTablet ? 12 : (isTablet ? 8 : 6)),
          
          // User Role
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isLargeTablet ? 20 : (isTablet ? 16 : 12),
              vertical: isLargeTablet ? 8 : (isTablet ? 6 : 4),
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFE3F2FD),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF2979FF),
                width: 1,
              ),
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
          
          // Email Verification Status
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
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
                  color: user.isEmailVerified ? Colors.green : Colors.orange,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
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
        
        Container(
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
                child: isEditing && controller != null
                    ? TextField(
                        controller: controller,
                        style: TextStyle(
                          fontSize: isLargeTablet ? 16 : (isTablet ? 14 : 12),
                          color: const Color(0xFF1F2937),
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Enter your full name',
                        ),
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
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
                color: const Color(0xFFE3F2FD),
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
            
            Icon(
              Icons.arrow_forward_ios,
              color: const Color(0xFF6B7280),
              size: isLargeTablet ? 20 : (isTablet ? 16 : 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(bool isLargeTablet, bool isTablet, bool isPhone) {
    return Column(
      children: [
        if (_isEditing) ...[
          // Save Button
          SizedBox(
            width: double.infinity,
            child: CustomButton(
              text: _isLoading ? 'Saving...' : 'Save Changes',
              onPressed: _isLoading ? null : _saveChanges,
              height: isLargeTablet ? 56 : (isTablet ? 52 : 48),
            ),
          ),
          
          SizedBox(height: isLargeTablet ? 16 : (isTablet ? 12 : 8)),
          
          // Cancel Button
          SizedBox(
            width: double.infinity,
            child: CustomButton(
              text: 'Cancel',
              onPressed: _toggleEdit,
              isPrimary: false,
              height: isLargeTablet ? 56 : (isTablet ? 52 : 48),
            ),
          ),
          
          SizedBox(height: isLargeTablet ? 24 : (isTablet ? 20 : 16)),
        ],
        
        // Logout Button
        SizedBox(
          width: double.infinity,
          child: CustomButton(
            text: 'Logout',
            onPressed: _logout,
            backgroundColor: Colors.red,
            textColor: Colors.white,
            height: isLargeTablet ? 56 : (isTablet ? 52 : 48),
          ),
        ),
      ],
    );
  }
}
