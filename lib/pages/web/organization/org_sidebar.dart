import 'package:flutter/material.dart';
import 'manage_pets_page.dart';
import 'surrender_requests_page.dart';
import 'adoption_requests_page.dart';
import 'messages_page.dart';
import 'organization_profile_page.dart';
import 'settings_page.dart';
import 'org_dashboard.dart'; 

class OrgSidebar extends StatelessWidget {
  const OrgSidebar({super.key});

  void _navigateIfNotCurrent(BuildContext context, Widget page) {
    // Prevent navigation if already on the same page type
    final ModalRoute? currentRoute = ModalRoute.of(context);
    final String? currentName = currentRoute?.settings.name;
    final String targetName = page.runtimeType.toString();

    if (currentName == targetName) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        settings: RouteSettings(name: targetName),
        pageBuilder: (_, __, ___) => page,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 359,
      height: 1024,
      decoration: BoxDecoration(color: const Color(0xFFEFCECB)),
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            child: Container(
              width: 359,
              height: 1024,
              decoration: BoxDecoration(color: const Color(0xFFFDEAE0)),
            ),
          ),
          // Sidebar logo (replace text+image with asset)
          Positioned(
            left: 10,
            top: 40,
            child: SizedBox(
              width: 340,
              height: 170,
              child: Image.asset(
                'assets/photos/sidebar-logo.png',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Center(
                    child: Text(
                      'Logo not found',
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 18,
                        color: Colors.red,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          // Menu label
          Positioned(
            left: 31,
            top: 210,
            child: SizedBox(
              width: 107,
              height: 19,
              child: Text(
                'Menu',
                style: TextStyle(
                  color: const Color(0xFF545454),
                  fontSize: 16,
                  fontFamily: 'DM Sans',
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
            ),
          ),
          // Dashboard
          _SidebarMenuItem(
            top: 232,
            icon: Icon(Icons.dashboard, color: Color(0xFF725F63), size: 28),
            label: 'Dashboard',
            onTap: () => _navigateIfNotCurrent(context, const OrganizationDashboard()),
          ),
          // Manage Pets
          _SidebarMenuItem(
            top: 287,
            icon: Icon(Icons.pets, color: Color(0xFF725F63), size: 28),
            label: 'Manage Pets',
            onTap: () => _navigateIfNotCurrent(context, const ManagePetsPage()),
          ),
          // Surrender Requests
          _SidebarMenuItem(
            top: 342,
            icon: Icon(Icons.assignment_return, color: Color(0xFF725F63), size: 28),
            label: 'Surrender Requests',
            onTap: () => _navigateIfNotCurrent(context, const SurrenderRequestsPage()),
          ),
          // Adoption Requests
          _SidebarMenuItem(
            top: 399,
            icon: Icon(Icons.assignment_turned_in, color: Color(0xFF725F63), size: 28),
            label: 'Adoption Requests',
            onTap: () => _navigateIfNotCurrent(context, const AdoptionRequestsPage()),
          ),
          // Messages
          _SidebarMenuItem(
            top: 456,
            icon: Icon(Icons.message, color: Color(0xFF725F63), size: 28),
            label: 'Messages',
            onTap: () => _navigateIfNotCurrent(context, const MessagesPage()),
          ),
          // Account label
          Positioned(
            left: 25,
            top: 596,
            child: SizedBox(
              width: 107,
              height: 19,
              child: Text(
                'Account',
                style: TextStyle(
                  color: const Color(0xFF545454),
                  fontSize: 16,
                  fontFamily: 'DM Sans',
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
            ),
          ),
          // Account divider
          Positioned(
            left: 25,
            top: 583,
            child: Container(
              width: 308,
              height: 1,
              decoration: BoxDecoration(color: const Color(0xFF9E9E9E)),
            ),
          ),
          // Organization Profile
          _SidebarMenuItem(
            top: 628,
            icon: Icon(Icons.account_circle, color: Color(0xFF725F63), size: 28),
            label: 'Organization Profile',
            onTap: () => _navigateIfNotCurrent(context, const OrganizationProfilePage()),
          ),
          // Settings
          _SidebarMenuItem(
            top: 683,
            icon: Icon(Icons.settings, color: Color(0xFF725F63), size: 28),
            label: 'Settings',
            onTap: () => _navigateIfNotCurrent(context, const SettingsPage()),
          ),
          // Logout
          Positioned(
            left: 215,
            top: 955,
            child: Container(
              width: 103,
              height: 55,
              decoration: ShapeDecoration(
                shape: RoundedRectangleBorder(
                  side: BorderSide(
                    width: 1,
                    color: const Color(0xFFDDDDDD),
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    left: 0,
                    top: 0,
                    child: Container(
                      width: 103,
                      height: 55,
                      decoration: BoxDecoration(color: const Color(0xFFFDEAE0)),
                    ),
                  ),
                  Positioned(
                    left: 20.06,
                    top: 18,
                    child: SizedBox(
                      width: 73.91,
                      height: 19,
                      child: Text(
                        'Logout',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          color: const Color(0xFF464646),
                          fontSize: 16,
                          fontFamily: 'Arial',
                          fontWeight: FontWeight.w400,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 5.69,
                    top: 10,
                    child: Container(
                      width: 12.04,
                      height: 36,
                      child: Stack(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Logout icon
          Positioned(
            left: 229,
            top: 972,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage("https://placehold.co/22x22"),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Sidebar menu item with hover animation
class _SidebarMenuItem extends StatefulWidget {
  final double top;
  final String label;
  final VoidCallback onTap;
  final Widget? icon;

  const _SidebarMenuItem({
    required this.top,
    required this.label,
    required this.onTap,
    this.icon,
  });

  @override
  State<_SidebarMenuItem> createState() => _SidebarMenuItemState();
}

class _SidebarMenuItemState extends State<_SidebarMenuItem> with SingleTickerProviderStateMixin {
  bool _hovering = false;
  late AnimationController _controller;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 180),
      vsync: this,
    );
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _setHover(bool hover) {
    setState(() {
      _hovering = hover;
      if (hover) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 33,
      top: widget.top,
      child: MouseRegion(
        onEnter: (_) => _setHover(true),
        onExit: (_) => _setHover(false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedBuilder(
            animation: _fadeAnim,
            builder: (context, child) {
              final bgColor = Color.lerp(
                Colors.transparent,
                const Color(0xFF725F63),
                _fadeAnim.value,
              );
              final iconColor = Color.lerp(
                const Color(0xFF725F63),
                Colors.white,
                _fadeAnim.value,
              );
              final textColor = Color.lerp(
                const Color(0xFF464646),
                Colors.white,
                _fadeAnim.value,
              );
              return Container(
                width: 308,
                height: 55,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: _fadeAnim.value > 0
                      ? [
                          BoxShadow(
                            color: const Color(0xFF725F63).withOpacity(0.16 * _fadeAnim.value),
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ]
                      : [],
                ),
                child: Stack(
                  children: [
                    Container(
                      width: 308,
                      height: 55,
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                      ),
                    ),
                    if (widget.icon != null)
                      Positioned(
                        left: 21,
                        top: 10,
                        child: SizedBox(
                          width: 36,
                          height: 36,
                          child: IconTheme(
                            data: IconThemeData(
                              color: iconColor,
                            ),
                            child: widget.icon is Icon
                                ? Icon(
                                    (widget.icon as Icon).icon,
                                    color: iconColor,
                                    size: (widget.icon as Icon).size,
                                  )
                                : widget.icon!,
                          ),
                        ),
                      ),
                    Positioned(
                      left: 60,
                      top: 18,
                      child: SizedBox(
                        width: 221,
                        height: 19,
                        child: Text(
                          widget.label,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 16,
                            fontFamily: 'DM Sans',
                            fontWeight: FontWeight.w500,
                            height: 1,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
