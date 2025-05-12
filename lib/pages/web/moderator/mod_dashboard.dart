import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:pawsmatch/models/organization.dart';
import 'package:pawsmatch/services/firebase_organization_service.dart';
import 'package:pawsmatch/services/firebase_photo_service.dart'; 
import 'package:pawsmatch/widgets/logout_button.dart';
import 'package:pawsmatch/utils/url_launcher_web.dart';
import 'dart:math';
import 'package:pawsmatch/services/notification_service.dart'; 
import 'package:pawsmatch/services/firebase_account_service.dart';
import 'package:pawsmatch/utils/email_js_interop.dart'; 

class ModeratorDashboard extends StatefulWidget {
  const ModeratorDashboard({super.key});

  @override
  _ModeratorDashboardState createState() => _ModeratorDashboardState();
}

class _ModeratorDashboardState extends State<ModeratorDashboard> {
  final FirebaseOrganizationService _organizationService = FirebaseOrganizationService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebasePhotoService _photoService = FirebasePhotoService();
  final NotificationService _notificationService = NotificationService(); // Add notification service
  final DatabaseAccountService _accountService = DatabaseAccountService(); // Add account service
  
  List<Organization> _unverifiedOrgs = [];
  bool _isLoading = true;
  String _errorMessage = '';
  String _selectedFilter = 'Verification Requests';

  @override
  void initState() {
    super.initState();
    _loadOrganizations(); 
    
    // Check EmailJS availability and ensure it's loaded
    if (kIsWeb) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        EmailJsInterop.logStatus();
      });
    }
  }

  Future<void> _loadOrganizations() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });
      
      List<Organization> organizations = [];
      
      // Load organizations based on selected filter
      if (_selectedFilter == 'Verification Requests') {
        // Get unverified and non-rejected organizations
        organizations = await _organizationService.getOrganizationsByStatus(isVerified: false, isRejected: false);
        print('Loaded ${organizations.length} verification requests');
      } else if (_selectedFilter == 'Verified Organizations') {
        // Get verified organizations
        organizations = await _organizationService.getOrganizationsByStatus(isVerified: true, isRejected: false);
        print('Loaded ${organizations.length} verified organizations');
      }
      
      setState(() {
        _unverifiedOrgs = organizations; // Keep the variable name for now to avoid breaking other parts
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading organizations: $e');
      setState(() {
        _errorMessage = 'Error loading organizations: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _verifyOrganization(Organization org) async {
    // Show confirmation dialog
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Verify Organization'),
        content: Text('Are you sure you want to verify ${org.org_name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF34C2BB),
            ),
            child: Text('Verify'),
          ),
        ],
      ),
    ) ?? false;

    if (!confirm) return;

    // Update organization verification status
    try {
      // Set loading indicator
      _showLoadingDialog('Verifying organization...');

      // Update organization status
      final updatedOrg = org.copyWith(isVerified: true);
      await _organizationService.updateOrganization(org.org_id, updatedOrg);
      
      // Get emails of organization admins
      final adminEmails = <String>[];
      for (final adminId in org.admin_ids) {
        try {
          final account = await _accountService.getAccount(adminId);
          if (account.account_email.isNotEmpty) {
            adminEmails.add(account.account_email);
          }
        } catch (e) {
          print('Error getting admin email: $e');
        }
      }
      
      // Send verification email - use direct approach for testing
      if (adminEmails.isNotEmpty) {
        // Regular approach
        await _notificationService.sendOrganizationVerificationEmail(
          organization: updatedOrg,
          recipientEmails: adminEmails,
          isApproved: true,
        );
      }

      // Hide loading dialog
      Navigator.of(context).pop();
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${org.org_name} has been verified and admins have been notified'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Reload organization list
      _loadOrganizations();
    } catch (e) {
      // Hide loading dialog
      Navigator.of(context).pop();
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error verifying organization: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _rejectOrganization(Organization org) async {
    final reasonController = TextEditingController();
    
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reject Organization'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to reject ${org.org_name}\'s verification request?'),
            SizedBox(height: 16),
            Text(
              'Reason for rejection (optional):',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: 8),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                hintText: 'Enter reason for rejection',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.all(12),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
            ),
            child: Text('Reject'),
          ),
        ],
      ),
    ) ?? false;

    if (!confirm) return;

    // Update organization rejection status
    try {
      // Set loading indicator
      _showLoadingDialog('Updating organization status...');

      // Add rejected field to organization
      final updatedOrg = org.copyWith(isRejected: true);
      await _organizationService.updateOrganization(org.org_id, updatedOrg);
      
      // Get emails of organization admins
      final adminEmails = <String>[];
      for (final adminId in org.admin_ids) {
        try {
          final account = await _accountService.getAccount(adminId);
          if (account.account_email.isNotEmpty) {
            adminEmails.add(account.account_email);
          }
        } catch (e) {
          print('Error getting admin email: $e');
        }
      }
      
      if (adminEmails.isNotEmpty) {
        await _notificationService.sendOrganizationVerificationEmail(
          organization: updatedOrg,
          recipientEmails: adminEmails,
          isApproved: false,
          message: reasonController.text.trim(),
        );
      }

      Navigator.of(context).pop();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${org.org_name}\'s verification request has been rejected and admins have been notified'),
          backgroundColor: Colors.red[600],
        ),
      );
      
      _loadOrganizations();
    } catch (e) {
      Navigator.of(context).pop();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error rejecting organization: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Helper method to show loading dialog
  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(const Color(0xFF34C2BB)),
            ),
            SizedBox(height: 16),
            Text(message),
          ],
        ),
      ),
    );
  }

  // Future<void> _testEmailDirectly() async {
  //   // Show dialog to get test email
  //   final testEmailController = TextEditingController();
    
  //   final result = await showDialog<bool>(
  //     context: context,
  //     builder: (context) => AlertDialog(
  //       title: Text('Test Email Sending'),
  //       content: Column(
  //         mainAxisSize: MainAxisSize.min,
  //         children: [
  //           Text('Enter email address for test:'),
  //           SizedBox(height: 12),
  //           TextField(
  //             controller: testEmailController,
  //             decoration: InputDecoration(
  //               hintText: 'email@example.com',
  //               border: OutlineInputBorder(),
  //             ),
  //             keyboardType: TextInputType.emailAddress,
  //           ),
  //         ],
  //       ),
  //       actions: [
  //         TextButton(
  //           onPressed: () => Navigator.of(context).pop(false),
  //           child: Text('Cancel'),
  //         ),
  //         ElevatedButton(
  //           onPressed: () => Navigator.of(context).pop(true),
  //           child: Text('Send Test'),
  //         ),
  //       ],
  //     ),
  //   );
    
  //   // if (result == true && testEmailController.text.isNotEmpty) {
  //   //   _showLoadingDialog('Sending test email...');
      
  //   //   try {
  //   //     // First try the direct method
  //   //     //DirectEmailTest.sendTestEmail(testEmailController.text.trim());
        
  //   //     // Then try the debug method
  //   //     await EmailJSDebug.testEmail(testEmailController.text.trim());
        
  //   //     Navigator.of(context).pop(); // Close loading dialog
        
  //   //     ScaffoldMessenger.of(context).showSnackBar(
  //   //       SnackBar(content: Text('Test email sent - check console for logs')),
  //   //     );
  //   //   } catch (e) {
  //   //     Navigator.of(context).pop(); // Close loading dialog
  //   //     ScaffoldMessenger.of(context).showSnackBar(
  //   //       SnackBar(content: Text('Error: $e')),
  //   //     );
  //   //   }
  //   // }
  // }

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
              // Top horizontal line
              Positioned(
                left: 16,
                top: 1,
                child: Container(
                  width: 503,
                  height: 0.50,
                  decoration: BoxDecoration(color: const Color(0xFF9E9E9E)),
                ),
              ),
              
              
              Positioned(
                left: 79,
                top: 67, 
                child: SizedBox(
                  width: 536,
                  height: 60, 
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: 'Paws',
                          style: TextStyle(
                            color: const Color(0xFF725F63),
                            fontSize: 96,
                            fontFamily: 'Cherry Bomb One',
                            fontWeight: FontWeight.w400,
                            height: 0.17,
                            letterSpacing: 1.2, 
                            shadows: [
                              Shadow(
                                offset: Offset(0, 1),
                                blurRadius: 2.0,
                                color: Colors.black.withOpacity(0.1),
                              ),
                            ],
                          ),
                        ),
                        TextSpan(
                          text: 'Match',
                          style: TextStyle(
                            color: const Color(0xFFE48C8A),
                            fontSize: 96,
                            fontFamily: 'Cherry Bomb One',
                            fontWeight: FontWeight.w400,
                            height: 0.17,
                            letterSpacing: 1.2, 
                            shadows: [
                              Shadow(
                                offset: Offset(0, 1),
                                blurRadius: 2.0,
                                color: Colors.black.withOpacity(0.1),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
                 
              Positioned(
                left: 587,
                top: 99,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFCECB).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: const Color(0xFFE48C8A).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    'MODERATOR',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: const Color(0xFF725F63),
                      fontSize: 28,
                      fontFamily: 'DM Sans',
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5, 
                    ),
                  ),
                ),
              ),
              
              Positioned(
                left: 250,
                top: 186,
                child: Container(
                  width: 652,
                  height: 32,
                  child: Text(
                    _selectedFilter,
                    style: TextStyle(
                      color: const Color(0xFF636363),
                      fontSize: 36,
                      fontFamily: 'DM Sans',
                      fontWeight: FontWeight.w700,
                      height: 0.44,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
              
              Positioned(
                left: 250,
                top: 215, 
                child: Container(
                  width: 700,
                  child: Text(
                    _selectedFilter == 'Verification Requests' 
                      ? 'Review and approve organization verification requests' 
                      : 'Manage verified organizations',
                    style: TextStyle(
                      color: const Color(0xFF636363).withOpacity(0.7),
                      fontSize: 18,
                      fontFamily: 'DM Sans',
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ),
              
              Positioned(
                left: 250,
                top: 239,
                child: Container(
                  width: 202,
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  clipBehavior: Clip.antiAlias,
                  decoration: ShapeDecoration(
                    shape: RoundedRectangleBorder(
                      side: BorderSide(
                        width: 1,
                        color: const Color(0xFFC5C6CC),
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: DropdownButton<String>(
                          value: _selectedFilter,
                          isExpanded: true,
                          underline: SizedBox(), // Remove underline
                          style: TextStyle(
                            color: const Color(0xFF8F9098),
                            fontSize: 14,
                            fontFamily: 'DM Sans', // Changed from 'Inter' to 'DM Sans'
                            fontWeight: FontWeight.w400,
                          ),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setState(() {
                                _selectedFilter = newValue;
                              });
                              _loadOrganizations(); // Reload with the new filter
                            }
                          },
                          items: ['Verification Requests', 'Verified Organizations']
                              .map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Filter dropdown
              Positioned(
                left: 465,
                top: 239,
                child: Container(
                  width: 202,
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  clipBehavior: Clip.antiAlias,
                  decoration: ShapeDecoration(
                    shape: RoundedRectangleBorder(
                      side: BorderSide(
                        width: 1,
                        color: const Color(0xFFC5C6CC),
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: DropdownButton<String>(
                          value: 'Filter',
                          isExpanded: true,
                          underline: SizedBox(), 
                          style: TextStyle(
                            color: const Color(0xFF8F9098),
                            fontSize: 14,
                            fontFamily: 'DM Sans', 
                            fontWeight: FontWeight.w400,
                          ),
                          onChanged: (String? newValue) {
                            // Implement filtering logic
                          },
                          items: ['Filter', 'Newest First', 'Oldest First', 'Organization Name']
                              .map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              Positioned(
                left: 250,
                top: 317, 
                right: 250, 
                bottom: 40,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _isLoading
                    ? _buildLoadingIndicator()
                    : _errorMessage.isNotEmpty
                      ? _buildErrorMessage()
                      : _unverifiedOrgs.isEmpty
                        ? _buildEmptyState()
                        : _buildEnhancedOrganizationList(),
                ),
              ),
              
              // Modernized logout button
              Positioned(
                left: 1402,
                top: 79,
                child: Container(
                  width: 103,
                  height: 55,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        const Color(0xFFFEF5F0),
                        const Color(0xFFF9EBE6),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                    border: Border.all(
                      width: 1,
                      color: const Color(0xFFDDDDDD),
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () async {
                        await FirebaseAuth.instance.signOut();
                        Navigator.of(context).pushReplacementNamed('/login');
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.logout,
                            size: 20,
                            color: const Color(0xFF464646),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Logout',
                            style: TextStyle(
                              color: const Color(0xFF464646),
                              fontSize: 14,
                              fontFamily: 'DM Sans',
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Test Email button
              // Positioned(
              //   right: 400,
              //   top: 79,
              //   child: ElevatedButton.icon(
              //     icon: Icon(Icons.email),
              //     label: Text('Test Email'),
              //     onPressed: _testEmailDirectly,
              //     style: ElevatedButton.styleFrom(
              //       backgroundColor: Colors.grey[200],
              //       foregroundColor: Colors.black87,
              //     ),
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }
  
  // Enhanced loading indicator
  Widget _buildLoadingIndicator() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(const Color(0xFF34C2BB)),
            strokeWidth: 3,
          ),
          SizedBox(height: 24),
          Text(
            _selectedFilter == 'Verification Requests'
              ? 'Loading organization verification requests...'
              : 'Loading verified organizations...',
            style: TextStyle(
              color: const Color(0xFF545454),
              fontSize: 16,
              fontFamily: 'DM Sans',
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
  
  // Enhanced error message display
  Widget _buildErrorMessage() {
    return Center(
      child: Container(
        padding: EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.redAccent,
            ),
            SizedBox(height: 16),
            Text(
              'Error Loading Requests',
              style: TextStyle(
                color: const Color(0xFF545454),
                fontSize: 24,
                fontFamily: 'DM Sans',
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Container(
              constraints: BoxConstraints(maxWidth: 500),
              child: Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: const Color(0xFF545454),
                  fontSize: 16,
                  fontFamily: 'DM Sans',
                ),
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadOrganizations,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF34C2BB),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
  
  // Enhanced empty state
  Widget _buildEmptyState() {
    String message = _selectedFilter == 'Verification Requests'
      ? 'There are no pending organization verification requests at this time.'
      : 'There are no verified organizations at this time.';
      
    return Center(
      child: Container(
        padding: EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _selectedFilter == 'Verification Requests' 
                ? Icons.check_circle_outline
                : Icons.verified,
              size: 80,
              color: const Color(0xFF34C2BB),
            ),
            SizedBox(height: 24),
            Text(
              _selectedFilter == 'Verification Requests' 
                ? 'All Caught Up!'
                : 'No Verified Organizations',
              style: TextStyle(
                color: const Color(0xFF545454),
                fontSize: 28,
                fontFamily: 'DM Sans',
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Container(
              constraints: BoxConstraints(maxWidth: 400),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: const Color(0xFF545454),
                  fontSize: 16,
                  fontFamily: 'DM Sans',
                  height: 1.5,
                ),
              ),
            ),
            SizedBox(height: 24),
            OutlinedButton(
              onPressed: _loadOrganizations, // Updated from _loadUnverifiedOrganizations
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF34C2BB),
                side: BorderSide(color: const Color(0xFF34C2BB)),
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.refresh, size: 18),
                  SizedBox(width: 8),
                  Text('Refresh'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Modern, color-coordinated organization list table with completely redesigned UI
  Widget _buildEnhancedOrganizationList() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Table header with gradient background
          Container(
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFFB0CCCA),
                  const Color(0xFFA5C1BF),
                ],
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                // Organization Name
                Expanded(
                  flex: 5,
                  child: Text(
                    'Organization Name',
                    style: TextStyle(
                      color: const Color(0xFF3B3B3B),
                      fontSize: 15,
                      fontFamily: 'DM Sans',
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                
                // Date Requested
                Expanded(
                  flex: 3,
                  child: Text(
                    'Date Requested',
                    style: TextStyle(
                      color: const Color(0xFF3B3B3B),
                      fontSize: 15,
                      fontFamily: 'DM Sans',
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                
                // Status
                Expanded(
                  flex: 2,
                  child: Text(
                    'Status',
                    style: TextStyle(
                      color: const Color(0xFF3B3B3B),
                      fontSize: 15,
                      fontFamily: 'DM Sans',
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                
                // Action
                Expanded(
                  flex: 2,
                  child: Text(
                    'Action',
                    style: TextStyle(
                      color: const Color(0xFF3B3B3B),
                      fontSize: 15,
                      fontFamily: 'DM Sans',
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          
          // Table body with improved ListView
          Expanded(
            child: _unverifiedOrgs.isEmpty 
              ? _buildEmptyTableState() 
              : ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: _unverifiedOrgs.length,
                  itemBuilder: (context, index) {
                    final org = _unverifiedOrgs[index];
                    
                    return Column(
                      children: [
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _viewOrganizationDetails(org),
                            splashColor: const Color(0xFF34C2BB).withOpacity(0.1),
                            highlightColor: Colors.grey.withOpacity(0.05),
                            child: Container(
                              height: 70,
                              padding: EdgeInsets.symmetric(horizontal: 24),
                              decoration: BoxDecoration(
                                color: index % 2 == 0 ? Colors.white : const Color(0xFFF9FAFA),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // Organization Name with Logo
                                  Expanded(
                                    flex: 5,
                                    child: Row(
                                      children: [
                                        // Organization Logo
                                        _buildOrganizationLogo(org),
                                        SizedBox(width: 16),
                                        
                                        // Organization Name and Location
                                        Expanded(
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              // Organization Name
                                              Text(
                                                org.org_name,
                                                style: TextStyle(
                                                  color: const Color(0xFF3B3B3B),
                                                  fontSize: 14,
                                                  fontFamily: 'DM Sans',
                                                  fontWeight: FontWeight.w600,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              
                                              // Location if available
                                              if (org.location != null && org.location!.isNotEmpty) ...[
                                                SizedBox(height: 4),
                                                Row(
                                                  children: [
                                                    Icon(
                                                      Icons.location_on_outlined, 
                                                      size: 12, 
                                                      color: Colors.grey[600]
                                                    ),
                                                    SizedBox(width: 4),
                                                    Expanded(
                                                      child: Text(
                                                        org.location!,
                                                        style: TextStyle(
                                                          color: Colors.grey[600],
                                                          fontSize: 12,
                                                          fontFamily: 'DM Sans',
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  
                                  // Date Requested
                                  Expanded(
                                    flex: 3,
                                    child: Center(
                                      child: Container(
                                        padding: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF5F9FA),
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(
                                            color: Colors.grey.shade200,
                                            width: 1,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.calendar_today_outlined,
                                              size: 12,
                                              color: Colors.grey[600],
                                            ),
                                            SizedBox(width: 6),
                                            Text(
                                              DateFormat('MMM d, yyyy').format(org.date_created),
                                              style: TextStyle(
                                                color: Colors.grey[700],
                                                fontSize: 12,
                                                fontFamily: 'DM Sans',
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  
                                  // Status
                                  Expanded(
                                    flex: 2,
                                    child: Center(
                                      child: _buildStatusBadge(org),
                                    ),
                                  ),
                                  
                                  // Action
                                  Expanded(
                                    flex: 2,
                                    child: Center(
                                      child: _buildActionButton(org),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Divider after each row except the last one
                        if (index < _unverifiedOrgs.length - 1)
                          Divider(
                            height: 1,
                            thickness: 1,
                            color: Colors.grey.shade100,
                            indent: 24,
                            endIndent: 24,
                          ),
                      ],
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }
  
  // Helper method for organization logo
  Widget _buildOrganizationLogo(Organization org) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: org.logo_url != null && org.logo_url!.isNotEmpty
          ? FutureBuilder<String>(
              future: _photoService.convertToSignedUrlIfNeeded(org.logo_url!),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(const Color(0xFF34C2BB)),
                      ),
                    ),
                  );
                }
                
                final url = snapshot.data ?? '';
                if (url.isEmpty) {
                  return _buildInitialsAvatar(org.org_name);
                }
                
                return Image.network(
                  url,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return _buildInitialsAvatar(org.org_name);
                  },
                );
              },
            )
          : _buildInitialsAvatar(org.org_name),
      ),
    );
  }
  
  // Helper to create initials-based avatar when no logo is available
  Widget _buildInitialsAvatar(String name) {
    final nameParts = name.split(' ');
    String initials = '';
    
    if (nameParts.isNotEmpty) {
      if (nameParts.length == 1) {
        initials = nameParts[0].substring(0, min(nameParts[0].length, 2)).toUpperCase();
      } else {
        initials = nameParts[0][0] + (nameParts.length > 1 ? nameParts[nameParts.length - 1][0] : '');
        initials = initials.toUpperCase();
      }
    } else {
      initials = 'OR';
    }
    
    // Generate a color based on the name
    final int hashCode = name.hashCode;
    final List<Color> colorOptions = [
      Color(0xFFE57373), 
      Color(0xFF81C784), 
      Color(0xFF64B5F6), 
      Color(0xFFFFB74D), 
      Color(0xFF9575CD), 
      Color(0xFF4DB6AC), 
      Color(0xFFF06292), 
      Color(0xFFBA68C8), 
    ];
    
    final color = colorOptions[hashCode % colorOptions.length];
    
    return Container(
      color: color.withOpacity(0.2),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          color: color.withOpacity(0.9),
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
  
  Widget _buildStatusBadge(Organization org) {
    Color backgroundColor;
    Color borderColor;
    Color textColor;
    IconData icon;
    String statusText;
    
    if (org.isVerified) {
      backgroundColor = const Color(0xFFE3F2E7);
      borderColor = const Color(0xFF5BB98C);
      textColor = const Color(0xFF2D7953);
      icon = Icons.verified;
      statusText = 'Verified';
    } else if (org.isRejected) {
      backgroundColor = const Color(0xFFFFE9E9);
      borderColor = const Color(0xFFF87171);
      textColor = const Color(0xFFC0392B);
      icon = Icons.cancel_outlined;
      statusText = 'Rejected';
    } else {
      backgroundColor = const Color(0xFFFFF8E6);
      borderColor = const Color(0xFFFFCA28); 
      textColor = const Color(0xFFB7791D);
      icon = Icons.pending;
      statusText = 'Pending';
    }
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: textColor,
          ),
          SizedBox(width: 4),
          Text(
            statusText,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w600,
              fontSize: 12,
              fontFamily: 'DM Sans',
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
  
  // Helper method for action button
  Widget _buildActionButton(Organization org) {
    return Container(
      height: 34,
      constraints: BoxConstraints(maxWidth: 110),
      child: ElevatedButton.icon(
        onPressed: () => _viewOrganizationDetails(org),
        icon: Icon(
          _selectedFilter == 'Verified Organizations'
              ? Icons.manage_accounts_outlined
              : Icons.visibility_outlined,
          size: 14,
        ),
        label: Text(
          _selectedFilter == 'Verified Organizations'
              ? 'Manage'
              : 'View',
          style: TextStyle(
            fontSize: 12,
            fontFamily: 'DM Sans',
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF34C2BB),
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 0),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: const Color(0xFF34C2BB).withOpacity(0.5),
            ),
          ),
        ),
      ),
    );
  }
  
  // Helper for empty table state
  Widget _buildEmptyTableState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _selectedFilter == 'Verification Requests'
              ? Icons.inbox_outlined
              : Icons.business_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          SizedBox(height: 20),
          Text(
            _selectedFilter == 'Verification Requests'
              ? 'No Pending Requests'
              : 'No Verified Organizations',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              fontFamily: 'DM Sans',
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 12),
          Text(
            _selectedFilter == 'Verification Requests'
              ? 'There are currently no organizations awaiting verification'
              : 'No organizations have been verified yet',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 14,
              fontFamily: 'DM Sans',
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: _loadOrganizations,
            icon: Icon(Icons.refresh, size: 16),
            label: Text(
              'Refresh',
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 14,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF34C2BB),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              side: BorderSide(color: const Color(0xFF34C2BB)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Enhanced organization details dialog with tabbed interface
  void _viewOrganizationDetails(Organization org) {
    // Parse document URLs from the comma-separated string
    List<String> documentUrls = [];
    if (org.org_proof_of_validation.contains(',')) {
      documentUrls = org.org_proof_of_validation.split(',');
    } else if (org.org_proof_of_validation.trim().isNotEmpty && 
               org.org_proof_of_validation != "No documents provided") {
      documentUrls = [org.org_proof_of_validation];
    }
    
    showDialog(
      context: context,
      builder: (context) {
        final screenSize = MediaQuery.of(context).size;
        final availableHeight = screenSize.height - 80;
        
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          insetPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Container(
            width: 1115,
            constraints: BoxConstraints(
              maxHeight: availableHeight,
              maxWidth: screenSize.width - 48,
            ),
            padding: EdgeInsets.all(0),
            child: DefaultTabController(
              length: 2,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFFB0CCCA),
                          const Color(0xFFA5C1BF),
                        ],
                      ),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          offset: Offset(0, 1),
                          blurRadius: 2,
                        ),
                      ],
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 24),
                    child: Row(
                      children: [
                        Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            border: Border.all(
                              color: Colors.white,
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(35),
                            child: org.logo_url != null && org.logo_url!.isNotEmpty
                              ? FutureBuilder<String>(
                                  future: _photoService.convertToSignedUrlIfNeeded(org.logo_url!),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState == ConnectionState.waiting) {
                                      return Center(
                                        child: SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(const Color(0xFF34C2BB)),
                                          ),
                                        ),
                                      );
                                    }
                                    
                                    final url = snapshot.data ?? '';
                                    if (url.isEmpty) {
                                      return Container(
                                        color: const Color(0xFFF9F6F4),
                                        child: Icon(
                                          Icons.business,
                                          size: 30,
                                          color: Colors.grey[600],
                                        ),
                                      );
                                    }
                                    
                                    return Image.network(
                                      url,
                                      fit: BoxFit.cover,
                                      width: 70,
                                      height: 70,
                                      errorBuilder: (context, error, stackTrace) {
                                        print("Error loading logo in dialog: $error");
                                        return Container(
                                          color: const Color(0xFFF9F6F4),
                                          child: Icon(
                                            Icons.business,
                                            size: 30,
                                            color: Colors.grey[600],
                                          ),
                                        );
                                      },
                                    );
                                  },
                                )
                              : Container(
                                  color: const Color(0xFFF9F6F4),
                                  child: Icon(
                                    Icons.business,
                                    size: 30,
                                    color: Colors.grey[600],
                                  ),
                                ),
                          ),
                        ),
                        SizedBox(width: 24),
                        
                        // Organization name and status with refined typography
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                org.org_name,
                                style: TextStyle(
                                  color: const Color(0xFF3B3B3B),
                                  fontSize: 26,
                                  fontFamily: 'DM Sans',
                                  fontWeight: FontWeight.w700,
                                  height: 1.2,
                                  letterSpacing: 0.2,
                                ),
                              ),
                              SizedBox(height: 10),
                              Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: org.isVerified 
                                          ? const Color(0xFFEBF6E0) 
                                          : const Color(0xFFF6EFE0),
                                      borderRadius: BorderRadius.circular(20), // More rounded corners
                                      border: Border.all(
                                        color: org.isVerified 
                                            ? const Color(0xFFC0D6B6) 
                                            : const Color(0xFFEFCECB),
                                        width: 1,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.03),
                                          blurRadius: 2,
                                          offset: Offset(0, 1),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          org.isVerified ? Icons.verified : Icons.pending,
                                          size: 14,
                                          color: org.isVerified 
                                              ? const Color(0xFF4A7C59)
                                              : const Color(0xFFE48C8A),
                                        ),
                                        SizedBox(width: 6),
                                        Text(
                                          org.isVerified ? 'Verified Organization' : 'Verification Pending',
                                          style: TextStyle(
                                            color: org.isVerified 
                                                ? const Color(0xFF4A7C59) 
                                                : const Color(0xFF936262),
                                            fontSize: 13,
                                            fontFamily: 'DM Sans',
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 0.2,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (org.location != null && org.location!.isNotEmpty) ...[
                                    SizedBox(width: 12),
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.8),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: Colors.grey.shade300,
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.location_on_outlined,
                                            size: 14,
                                            color: const Color(0xFF725F63),
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            org.location!,
                                            style: TextStyle(
                                              color: const Color(0xFF725F63),
                                              fontSize: 13,
                                              fontFamily: 'DM Sans',
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        
                        // Styled close button
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.3),
                          ),
                          child: IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: Icon(Icons.close, color: const Color(0xFF545454)),
                            splashRadius: 20,
                            tooltip: 'Close',
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Refined tab bar with better visual appeal
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          offset: Offset(0, 1),
                          blurRadius: 2,
                        ),
                      ],
                    ),
                    child: TabBar(
                      tabs: [
                        Tab(
                          height: 56,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.business_center_outlined, size: 18),
                              SizedBox(width: 10),
                              Text(
                                'Organization Details',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'DM Sans',
                                ),
                              ),
                            ],
                          ),
                        ),
                        Tab(
                          height: 56,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.file_present_outlined, size: 18),
                              SizedBox(width: 10),
                              Text(
                                'Verification Documents',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'DM Sans',
                                ),
                              ),
                              if (documentUrls.isNotEmpty) ...[
                                SizedBox(width: 8),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF34C2BB),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    documentUrls.length.toString(),
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                      labelColor: const Color(0xFF34C2BB),
                      unselectedLabelColor: Colors.grey[600],
                      indicatorColor: const Color(0xFF34C2BB),
                      indicatorWeight: 3,
                      indicatorSize: TabBarIndicatorSize.tab,
                    ),
                  ),
                  
                  // Content area with TabBarView and refined styling
                  Flexible(
                    child: Container(
                      color: const Color(0xFFFAFAFA), // Subtle background color for content area
                      child: TabBarView(
                        children: [
                          // First tab - Organization Details with enhanced styling
                          SingleChildScrollView(
                            child: Container(
                              padding: EdgeInsets.all(30),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Organization information with enhanced styling
                                  _buildDetailSection(
                                    'Organization Information',
                                    [
                                      _buildEnhancedDetailRow('Date Created', DateFormat('MMMM d, yyyy').format(org.date_created)),
                                      _buildEnhancedDetailRow('Location', org.location ?? 'Not provided'),
                                      _buildEnhancedDetailRow('Address', org.address ?? 'Not provided'),
                                    ],
                                    icon: Icons.info_outline,
                                  ),
                                  
                                  SizedBox(height: 30),
                                  
                                  // About section with styled container
                                  _buildDetailSection(
                                    'About',
                                    [
                                      Container(
                                        width: double.infinity,
                                        padding: EdgeInsets.all(20),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: Colors.grey.shade200),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.02),
                                              blurRadius: 5,
                                              offset: Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Text(
                                          org.about ?? 'No information provided',
                                          style: TextStyle(
                                            height: 1.6,
                                            color: const Color(0xFF555555),
                                            fontSize: 15,
                                          ),
                                        ),
                                      ),
                                    ],
                                    icon: Icons.description_outlined,
                                  ),
                                  
                                  SizedBox(height: 30),
                                  
                                  // Contact information with styled rows
                                  _buildDetailSection(
                                    'Contact Information',
                                    [
                                      _buildEnhancedInfoCard(
                                        Icons.email_outlined,
                                        'Email',
                                        org.email ?? 'Not provided',
                                        const Color(0xFFE3F2FD), // Light blue background
                                        Colors.blue,
                                      ),
                                      SizedBox(height: 10),
                                      _buildEnhancedInfoCard(
                                        Icons.phone_outlined,
                                        'Phone',
                                        org.contact_numbers != null && org.contact_numbers!.isNotEmpty 
                                          ? org.contact_numbers!.join(', ')
                                          : 'Not provided',
                                        const Color(0xFFE8F5E9), // Light green background
                                        Colors.green,
                                      ),
                                    ],
                                    icon: Icons.contact_phone_outlined,
                                  ),
                                  
                                  if (org.mission != null && org.mission!.isNotEmpty) ...[
                                    SizedBox(height: 30),
                                    
                                    // Mission statement with styled container
                                    _buildDetailSection(
                                      'Mission',
                                      [
                                        Container(
                                          width: double.infinity,
                                          padding: EdgeInsets.all(20),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFFF8E1).withOpacity(0.7),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: Colors.amber.shade100),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.02),
                                                blurRadius: 5,
                                                offset: Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Icon(
                                                Icons.format_quote,
                                                color: Colors.amber[700],
                                                size: 24,
                                              ),
                                              SizedBox(height: 10),
                                              Text(
                                                org.mission!,
                                                style: TextStyle(
                                                  height: 1.6,
                                                  fontStyle: FontStyle.italic,
                                                  color: const Color(0xFF6D4C41),
                                                  fontSize: 15,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                      icon: Icons.lightbulb_outline,
                                    ),
                                  ],
                                  
                                  // Operating hours if available
                                  if ((org.weekday_hours != null && org.weekday_hours!.isNotEmpty) ||
                                      (org.weekend_hours != null && org.weekend_hours!.isNotEmpty)) ...[
                                    SizedBox(height: 30),
                                    _buildDetailSection(
                                      'Operating Hours',
                                      [
                                        Container(
                                          width: double.infinity,
                                          padding: EdgeInsets.all(20),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: Colors.grey.shade200),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.02),
                                                blurRadius: 5,
                                                offset: Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Column(
                                            children: [
                                              if (org.weekday_hours != null && org.weekday_hours!.isNotEmpty)
                                                _buildTimeRow(
                                                  'Weekdays',
                                                  org.weekday_hours!,
                                                  Icons.calendar_view_week_outlined,
                                                ),
                                              if (org.weekday_hours != null && org.weekday_hours!.isNotEmpty && 
                                                 org.weekend_hours != null && org.weekend_hours!.isNotEmpty)
                                                Divider(height: 24),
                                              if (org.weekend_hours != null && org.weekend_hours!.isNotEmpty)
                                                _buildTimeRow(
                                                  'Weekends',
                                                  org.weekend_hours!,
                                                  Icons.weekend_outlined,
                                                ),
                                            ],
                                          ),
                                        ),
                                      ],
                                      icon: Icons.access_time,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          
                          // Second tab - Verification Documents with refined styling
                          SingleChildScrollView(
                            child: Container(
                              padding: EdgeInsets.all(30),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (documentUrls.isEmpty)
                                    _buildEmptyDocumentsState(org)
                                  else
                                    _buildDocumentsList(documentUrls),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Footer with refined action buttons
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          offset: Offset(0, -1),
                          blurRadius: 3,
                        ),
                      ],
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Close button
                        TextButton.icon(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: Icon(Icons.close, size: 18),
                          label: Text('Close'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.grey[700],
                            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        
                        // Show action buttons only for unverified organizations
                        if (!org.isVerified) ...[
                          SizedBox(width: 12),
                          // Reject button with improved styling
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.of(context).pop();
                              _rejectOrganization(org);
                            },
                            icon: Icon(Icons.cancel_outlined, size: 18),
                            label: Text('Reject Request'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red[50],
                              foregroundColor: Colors.red[700],
                              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(color: Colors.red.shade300),
                              ),
                            ),
                          ),
                          
                          SizedBox(width: 12),
                          // Verify button with improved styling
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.of(context).pop();
                              _verifyOrganization(org);
                            },
                            icon: Icon(Icons.check_circle_outline, size: 18),
                            label: Text('Verify Organization'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF34C2BB),
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              elevation: 1,
                              shadowColor: const Color(0xFF34C2BB).withOpacity(0.4),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // New helper method for empty documents state
  Widget _buildEmptyDocumentsState(Organization org) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 60, horizontal: 20),
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.folder_off,
              size: 50,
              color: Colors.grey[400],
            ),
          ),
          SizedBox(height: 30),
          Text(
            'No Verification Documents',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
              fontFamily: 'DM Sans',
            ),
          ),
          SizedBox(height: 16),
          Container(
            width: 500,
            child: Text(
              org.org_proof_of_validation == "No documents provided" 
                  ? 'This organization did not provide any verification documents.'
                  : org.org_proof_of_validation,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: 40),
          if (!org.isVerified)
            Container(
              padding: EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.amber[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber[200]!),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.amber[800], size: 20),
                  SizedBox(width: 10),
                  Text(
                    'Verification documents are required',
                    style: TextStyle(
                      color: Colors.amber[900],
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

  // New helper method for documents list
  Widget _buildDocumentsList(List<String> documentUrls) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.folder_special, color: const Color(0xFF34C2BB), size: 24),
            SizedBox(width: 12),
            Text(
              'Verification Documents',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF3B3B3B),
                fontFamily: 'DM Sans',
              ),
            ),
          ],
        ),
        SizedBox(height: 18),
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            'The following documents were uploaded by the organization to validate their identity and operations. '
            'Click on any document to view it in a new tab.',
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ),
        SizedBox(height: 24),
        
        ListView.separated(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: documentUrls.length,
          separatorBuilder: (context, index) => SizedBox(height: 16),
          itemBuilder: (context, index) {
            final url = documentUrls[index];
            final fileName = _extractFileName(url);
            final fileExtension = fileName.split('.').last.toLowerCase();
            
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: () => _launchDocumentInNewTab(url),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Row(
                      children: [
                        // Document icon with colorful background
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _getFileColor(fileName).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _getFileIcon(fileName),
                            color: _getFileColor(fileName),
                            size: 28,
                          ),
                        ),
                        SizedBox(width: 20),
                        // File info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                fileName,
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 16,
                                  color: const Color(0xFF3B3B3B),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 6),
                              Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: _getFileTypeColor(fileExtension).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      fileExtension.toUpperCase(),
                                      style: TextStyle(
                                        color: _getFileTypeColor(fileExtension),
                                        fontWeight: FontWeight.w500,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  Text(
                                    'Document ${index + 1}',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 20),
                        // Open button
                        OutlinedButton.icon(
                          onPressed: () => _launchDocumentInNewTab(url),
                          icon: Icon(Icons.open_in_new, size: 16),
                          label: Text('Open'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF34C2BB),
                            side: BorderSide(color: const Color(0xFF34C2BB).withOpacity(0.5)),
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // New helper method for styled detail section
  Widget _buildDetailSection(String title, List<Widget> children, {IconData? icon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20, color: const Color(0xFF34C2BB)),
              SizedBox(width: 10),
            ],
            Text(
              title,
              style: TextStyle(
                color: const Color(0xFF3B3B3B),
                fontSize: 18,
                fontFamily: 'DM Sans',
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        ...children,
      ],
    );
  }
  
  // New enhanced info card for contact details
  Widget _buildEnhancedInfoCard(IconData icon, String label, String value, Color bgColor, Color iconColor) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: bgColor),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bgColor.withOpacity(0.8),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 18,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.black87,
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

  // New helper method for time display
  Widget _buildTimeRow(String day, String hours, IconData icon) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFEFEFEF),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: Colors.grey[700],
            size: 18,
          ),
        ),
        SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              day,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 4),
            Text(
              hours,
              style: TextStyle(
                fontSize: 15,
                color: Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  // Helper method for file type color
  Color _getFileTypeColor(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return Colors.red[700]!;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Colors.blue[700]!;
      case 'doc':
      case 'docx':
        return Colors.indigo[700]!;
      case 'xls':
      case 'xlsx':
        return Colors.green[700]!;
      default:
        return Colors.grey[700]!;
    }
  }

  // Helper methods for document handling
  void _launchDocumentInNewTab(String url) async {
    try {
      // Convert to signed URL if needed
      final signedUrl = await _photoService.convertToSignedUrlIfNeeded(url);
      // Use dart:html to open a new tab
      // This needs to be done using js interop in a web environment
      _openUrlInNewTab(signedUrl);
    } catch (e) {
      print('Error launching document: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error opening document: $e')),
      );
    }
  }

  // This method uses the UrlLauncherWeb utility to open a URL in a new tab
  void _openUrlInNewTab(String url) {
    try {
      UrlLauncherWeb.openInNewTab(url);
    } catch (e) {
      print('Error opening URL in new tab: $e');
      // Fallback for non-web platforms or if there's an error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open document. URL: $url')),
      );
    }
  }

  // Extract a readable filename from a URL
  String _extractFileName(String url) {
    try {
      // Try to get the last segment of the path
      Uri uri = Uri.parse(url);
      String path = uri.path;
      
      // Extract last part after last /
      String fileName = path.split('/').last;
      
      // Remove any query parameters
      fileName = fileName.split('?').first;
      
      // Decode URI encoded characters
      fileName = Uri.decodeComponent(fileName);
      
      // If we have a timestamp prefix, make it more readable
      if (fileName.contains('_') && RegExp(r'^\d+_').hasMatch(fileName)) {
        // Replace timestamp with "Document"
        fileName = fileName.replaceFirst(RegExp(r'^\d+_'), '');
      }
      
      return fileName.isNotEmpty ? fileName : 'Document';
    } catch (e) {
      return 'Document';
    }
  }

  // Return appropriate icon based on file extension
  IconData _getFileIcon(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    
    if (extension == 'pdf') return Icons.picture_as_pdf;
    if (['jpg', 'jpeg', 'png', 'gif'].contains(extension)) return Icons.image;
    if (['doc', 'docx'].contains(extension)) return Icons.description;
    if (['xls', 'xlsx'].contains(extension)) return Icons.table_chart;
    if (['ppt', 'pptx'].contains(extension)) return Icons.slideshow;
    
    return Icons.insert_drive_file;
  }

  // Return color based on file type
  Color _getFileColor(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    
    if (extension == 'pdf') return Colors.red;
    if (['jpg', 'jpeg', 'png', 'gif'].contains(extension)) return Colors.blue;
    if (['doc', 'docx'].contains(extension)) return Colors.indigo;
    if (['xls', 'xlsx'].contains(extension)) return Colors.green;
    if (['ppt', 'pptx'].contains(extension)) return Colors.orange;
    
    return Colors.grey;
  }
  
  // Helper method for section titles in detail dialog
  // Widget _buildDetailSection(String title, List<Widget> children) {
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       Text(
  //         title,
  //         style: TextStyle(
  //           color: const Color(0xFF3B3B3B),
  //           fontSize: 18,
  //           fontFamily: 'DM Sans',
  //           fontWeight: FontWeight.w700,
  //         ),
  //       ),
  //       SizedBox(height: 16),
  //       ...children,
  //     ],
  //   );
  // }
  
  // Enhanced detail row for organization details
  Widget _buildEnhancedDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 140,
            child: Text(
              label + ':',
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 15,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
