import 'package:flutter/material.dart';
import 'package:pawsmatch/pages/web/organization/org_sidebar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pawsmatch/services/firebase_organization_service.dart';
import 'package:pawsmatch/models/organization.dart';

class OrganizationDashboard extends StatefulWidget {
  final Organization? org;
  const OrganizationDashboard({super.key, this.org});

  @override
  _OrganizationDashboardState createState() => _OrganizationDashboardState();
}

class _OrganizationDashboardState extends State<OrganizationDashboard> {
  final FirebaseOrganizationService _organizationService = FirebaseOrganizationService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  Organization? _organization;
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    if (widget.org != null) {
      _organization = widget.org;
      _isLoading = false;
    } else {
      _loadOrganizationData();
    }
  }

  Future<void> _loadOrganizationData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      // Get current user
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('No user logged in');
      }

      // Get organization data for the logged in user
      final organization = await _organizationService.getOrganizationById(user.uid);
      
      setState(() {
        _organization = organization;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load organization data: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEF5F0),
      body: Center(
        child: Container(
          width: 1584,
          height: 1024,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(color: const Color(0xFFFEF5F0)),
          child: Stack(
            children: [
              // Sidebar
              const Positioned(
                left: 0,
                top: 0,
                child: OrgSidebar(),
              ),
              // Top horizontal line
              Positioned(
                left: 16,
                top: 1,
                child: Container(
                  width: 503,
                  height: 0.5,
                  decoration: BoxDecoration(color: const Color(0xFF9E9E9E)),
                ),
              ),
              // Dashboard title
              Positioned(
                left: 429,
                top: 90,
                child: SizedBox(
                  width: 448,
                  height: 19,
                  child: Text(
                    'Dashboard',
                    style: TextStyle(
                      color: const Color(0xFF545454),
                      fontSize: 48,
                      fontFamily: 'DM Sans',
                      fontWeight: FontWeight.w700,
                      height: 0.33,
                    ),
                  ),
                ),
              ),
              // Dashboard subtitle
              Positioned(
                left: 429,
                top: 123,
                child: SizedBox(
                  width: 966,
                  height: 52,
                  child: Text(
                    'Welcome back! Here is a quick overview of the organization\'s trends.',
                    style: TextStyle(
                      color: const Color(0xFF545454),
                      fontSize: 24,
                      fontFamily: 'DM Sans',
                      fontWeight: FontWeight.w400,
                      height: 1.88,
                    ),
                  ),
                ),
              ),
              // Highlighted stats box
              Positioned(
                left: 423,
                top: 171,
                child: Container(
                  width: 1050,
                  height: 130,
                  decoration: ShapeDecoration(
                    color: const Color(0xFFFBE8DD),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  // Show loading indicator or error message
                  child: _isLoading 
                    ? const Center(child: CircularProgressIndicator())
                    : _errorMessage.isNotEmpty
                      ? Center(child: Text(_errorMessage, style: TextStyle(color: Colors.red)))
                      : null,
                ),
              ),
              // Org profile image - Organization Logo
              if (!_isLoading && _errorMessage.isEmpty && _organization != null)
                Positioned(
                  left: 494.33,
                  top: 196.28,
                  child: Container(
                    width: 87.29,
                    height: 85.45,
                    decoration: ShapeDecoration(
                      image: DecorationImage(
                        image: _organization?.logo_url != null && _organization!.logo_url!.isNotEmpty
                            ? NetworkImage(_organization!.logo_url!)
                            : const NetworkImage("https://placehold.co/87x85?text=Logo"),
                        fit: BoxFit.cover,
                        onError: (error, stackTrace) => {},
                      ),
                      shape: RoundedRectangleBorder(
                        side: BorderSide(
                          width: 1,
                          color: const Color(0x8E725F63),
                        ),
                        borderRadius: BorderRadius.circular(92.50),
                      ),
                    ),
                  ),
                ),
              // Edit Org Details button
              Positioned(
                left: 1293.84,
                top: 219,
                child: Container(
                  width: 132.47,
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  clipBehavior: Clip.antiAlias,
                  decoration: ShapeDecoration(
                    shape: RoundedRectangleBorder(
                      side: BorderSide(
                        width: 1.50,
                        color: const Color(0xFF545454),
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Edit Org Details',
                        style: TextStyle(
                          color: const Color(0xFF545454),
                          fontSize: 12,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Org name and email
              if (!_isLoading && _errorMessage.isEmpty && _organization != null)
                Positioned(
                  left: 636.91,
                  top: 208,
                  child: SizedBox(
                    width: 346.38,
                    height: 77,
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: '${_organization!.org_name}\n',
                            style: TextStyle(
                              color: const Color(0xFF545454),
                              fontSize: 28,
                              fontFamily: 'DM Sans',
                              fontWeight: FontWeight.w700,
                              height: 1.14,
                            ),
                          ),
                          TextSpan(
                            text: _organization!.email ?? 'No email provided',
                            style: TextStyle(
                              color: const Color(0xFF545454),
                              fontSize: 24,
                              fontFamily: 'DM Sans',
                              fontWeight: FontWeight.w400,
                              height: 1.33,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              // Trends section
              Positioned(
                left: 434,
                top: 326,
                child: SizedBox(
                  width: 448,
                  height: 19,
                  child: Text(
                    'Trends',
                    style: TextStyle(
                      color: const Color(0xFF545454),
                      fontSize: 32,
                      fontFamily: 'DM Sans',
                      fontWeight: FontWeight.w700,
                      height: 0.50,
                    ),
                  ),
                ),
              ),
              // Trends image placeholder
              Positioned(
                left: 423,
                top: 337,
                child: Container(
                  width: 1048.91,
                  height: 673,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: NetworkImage("https://placehold.co/1049x673"),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
