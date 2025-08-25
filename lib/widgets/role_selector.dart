import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

class RoleSelector extends StatelessWidget {
  final String selectedRole;
  final ValueChanged<String> onChanged;
  const RoleSelector({super.key, required this.selectedRole, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;
    
    const primaryBlue = Color(0xFF2979FF);
    const gray = Color(0xFF6B7280);
    const lightBlueBg = Color(0xFFE3F2FD);
    const lightBlueBgHover = Color(0xFFBBDEFB);
    const lightGrayBg = Color(0xFFF5F5F5);
    const lightGrayBgHover = Color(0xFFE5E5E5);
    const userBlueHover = Color(0xFF2979FF);
    const lightGrayBorder = Color(0xFFE0E0E0);
    
    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: _RoleOption(
                icon: FontAwesomeIcons.user,
                label: 'User',
                selected: selectedRole == 'user',
                onTap: () => onChanged('user'),
                selectedColor: primaryBlue,
                selectedBg: lightBlueBg,
                selectedBgHover: lightBlueBgHover,
                unselectedColor: gray,
                unselectedBg: lightGrayBg,
                unselectedBgHover: userBlueHover.withValues(alpha: 0.08),
                selectedBorder: primaryBlue,
                unselectedBorder: lightGrayBorder,
                isSmallScreen: isSmallScreen,
                maxWidth: constraints.maxWidth * 0.45,
              ),
            ),
            SizedBox(width: isSmallScreen ? 12 : 16),
            Expanded(
              child: _RoleOption(
                icon: FontAwesomeIcons.store,
                label: 'Shop Owner',
                selected: selectedRole == 'shop',
                onTap: () => onChanged('shop'),
                selectedColor: primaryBlue,
                selectedBg: lightBlueBg,
                selectedBgHover: lightBlueBgHover,
                unselectedColor: gray,
                unselectedBg: lightGrayBg,
                unselectedBgHover: lightGrayBgHover,
                selectedBorder: primaryBlue,
                unselectedBorder: lightGrayBorder,
                isSmallScreen: isSmallScreen,
                maxWidth: constraints.maxWidth * 0.45,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _RoleOption extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color selectedColor;
  final Color selectedBg;
  final Color selectedBgHover;
  final Color unselectedColor;
  final Color unselectedBg;
  final Color unselectedBgHover;
  final Color selectedBorder;
  final Color unselectedBorder;
  final bool isSmallScreen;
  final double maxWidth;
  
  const _RoleOption({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    required this.selectedColor,
    required this.selectedBg,
    required this.selectedBgHover,
    required this.unselectedColor,
    required this.unselectedBg,
    required this.unselectedBgHover,
    required this.selectedBorder,
    required this.unselectedBorder,
    required this.isSmallScreen,
    required this.maxWidth,
  });

  @override
  State<_RoleOption> createState() => _RoleOptionState();
}

class _RoleOptionState extends State<_RoleOption> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.selected;
    final bgColor = isSelected 
        ? (_isHovered ? widget.selectedBgHover : widget.selectedBg)
        : (_isHovered ? widget.unselectedBgHover : widget.unselectedBg);
    final color = isSelected ? widget.selectedColor : widget.unselectedColor;
    final borderColor = isSelected ? widget.selectedBorder : widget.unselectedBorder;
    
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          constraints: BoxConstraints(maxWidth: widget.maxWidth),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(
              horizontal: widget.isSmallScreen ? 12 : 16,
              vertical: widget.isSmallScreen ? 10 : 14,
            ),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: borderColor,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : _isHovered
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : [],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FaIcon(
                  widget.icon, 
                  color: color, 
                  size: widget.isSmallScreen ? 16 : 20,
                ),
                SizedBox(width: widget.isSmallScreen ? 6 : 8),
                Flexible(
                  child: Text(
                    widget.label,
                    style: GoogleFonts.poppins(
                      color: color,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      fontSize: widget.isSmallScreen ? 13 : 15,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 