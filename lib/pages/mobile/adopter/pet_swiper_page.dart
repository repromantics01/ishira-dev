import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Add this import for SystemUiOverlayStyle
import 'package:pawsmatch/models/pet.dart';
import 'package:pawsmatch/pages/mobile/adopter/swipe_pet_details.dart';
import 'package:pawsmatch/services/firebase_pet_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';

class PetSwiperPage extends StatefulWidget {
  const PetSwiperPage({Key? key}) : super(key: key);

  @override
  _PetSwiperPageState createState() => _PetSwiperPageState();
}

class _PetSwiperPageState extends State<PetSwiperPage> with TickerProviderStateMixin {
  final FirebasePetService _petService = FirebasePetService();
  
  List<Pet> _pets = [];
  bool _isLoading = true;
  int _currentIndex = 0;
  
  // Animation controllers
  late AnimationController _swipeController;
  late AnimationController _progressController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;
  
  // Swipe state tracking
  Offset _dragOffset = Offset.zero;
  bool _isDragging = false;
  bool _isSwipingRight = false;
  bool _isSwipingLeft = false;
  
  // Screen width for calculations
  double _screenWidth = 0;

  // Track if a swipe animation is in progress
  bool _isAnimating = false;
  
  // Track if we need to show the previous pet for animation purposes
  bool _showPreviousPet = false;
  Pet? _previousPet;

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controllers
    _swipeController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    
    _progressController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
    
    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset(1.5, 0.0),
    ).animate(CurvedAnimation(
      parent: _swipeController,
      curve: Curves.easeOut,
    ));
    
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.1,
    ).animate(CurvedAnimation(
      parent: _swipeController,
      curve: Curves.easeOut,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.9,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _swipeController,
      curve: Curves.easeOut,
    ));
    
    _loadPets();
  }
  
  @override
  void dispose() {
    _swipeController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  Future<void> _loadPets() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get multiple pets to swipe through
      final pets = await _petService.getPets(limit: 10);
      
      setState(() {
        _pets = pets;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading pets: $e');
      setState(() {
        _pets = [];
        _isLoading = false;
      });
    }
  }

  void _handleSwipeLeft() async {
    if (_isAnimating) return; // Prevent multiple animations
    
    setState(() {
      _isAnimating = true;
      _showPreviousPet = true;
      _previousPet = _pets[_currentIndex]; // Store current pet as previous
    });
    
    // Set the end position for the swipe animation - fix direction to match gesture
    _slideAnimation = Tween<Offset>(
      begin: _dragOffset,
      end: Offset(-2.0, 0.0), // Keep this direction for left swipe
    ).animate(CurvedAnimation(
      parent: _swipeController,
      curve: Curves.easeOut,
    ));

    // Trigger the animation
    await _swipeController.forward();
    
    // First update UI to show next pet before any async operations
    if (_currentIndex < _pets.length - 1) {
      setState(() {
        _currentIndex++;
        _dragOffset = Offset.zero;
        _isDragging = false;
        _isSwipingLeft = false;
      });
    } else {
      // No more pets
      setState(() {
        _dragOffset = Offset.zero;
        _isDragging = false;
        _isSwipingLeft = false;
      });
    }
    
    // Now record the swipe in the background
    _recordSwipe(false);
    
    // Clean up animation state after a short delay to ensure smooth transition
    Future.delayed(Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _showPreviousPet = false;
          _isAnimating = false;
        });
        _swipeController.reset();
      }
    });
  }

  void _handleSwipeRight() async {
    if (_isAnimating) return; // Prevent multiple animations
    
    setState(() {
      _isAnimating = true;
      _showPreviousPet = true;
      _previousPet = _pets[_currentIndex]; // Store current pet as previous
    });
    
    // Set the end position for the swipe animation - fix direction to match gesture
    _slideAnimation = Tween<Offset>(
      begin: _dragOffset,
      end: Offset(2.0, 0.0), // Keep this direction for right swipe
    ).animate(CurvedAnimation(
      parent: _swipeController,
      curve: Curves.easeOut,
    ));

    // Trigger the animation
    await _swipeController.forward();
    
    // First update UI to show next pet before any async operations
    if (_currentIndex < _pets.length - 1) {
      setState(() {
        _currentIndex++;
        _dragOffset = Offset.zero;
        _isDragging = false;
        _isSwipingRight = false;
      });
    } else {
      // No more pets
      setState(() {
        _dragOffset = Offset.zero;
        _isDragging = false;
        _isSwipingRight = false;
      });
    }
    
    // Now record the swipe in the background
    _recordSwipe(true);
    
    // Clean up animation state after a short delay to ensure smooth transition
    Future.delayed(Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _showPreviousPet = false;
          _isAnimating = false;
        });
        _swipeController.reset();
      }
    });
  }

  Future<void> _recordSwipe(bool liked) async {
    if (_currentIndex < _pets.length) {
      try {
        // Get the current user's ID
        final User? user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          // Record the swipe in Firestore
          await FirebaseFirestore.instance.collection('swipes').add({
            'account_id': user.uid,
            'pet_id': _pets[_currentIndex].pet_id,
            'liked': liked,
            'timestamp': FieldValue.serverTimestamp(),
          });
          
          // Show feedback
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(liked ? 'Pet liked!' : 'Skipped this pet'),
              duration: Duration(seconds: 1),
            ),
          );
        }
      } catch (e) {
        print('Error recording swipe: $e');
      }
    }
  }

  void _resetPosition() {
    // Return card to center when swipe isn't enough
    _slideAnimation = Tween<Offset>(
      begin: _dragOffset,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _swipeController,
      curve: Curves.easeOut,
    ));
    
    _swipeController.forward().then((_) {
      setState(() {
        _dragOffset = Offset.zero;
        _isDragging = false;
        _isSwipingLeft = false;
        _isSwipingRight = false;
      });
      _swipeController.reset();
    });
  }

  // Fix back button - make it much simpler
  @override
  Widget build(BuildContext context) {
    _screenWidth = MediaQuery.of(context).size.width;
    
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFFEF5F0),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedBuilder(
                animation: _progressController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: 1.0 + (_progressController.value * 0.1),
                    child: Icon(
                      Icons.pets,
                      size: 80,
                      color: Color(0xFFDDCAC0),
                    ),
                  );
                },
              ),
              SizedBox(height: 20),
              Text(
                'Finding pets for you...',
                style: TextStyle(
                  color: Color(0xFF545454),
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_pets.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFFFEF5F0),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.pets, size: 80, color: Color(0xFFDDCAC0)),
              SizedBox(height: 20),
              Text(
                'No pets available',
                style: TextStyle(
                  color: Color(0xFF545454),
                  fontSize: 24,
                  fontFamily: 'Arial',
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFEF5F0),
      // Make AppBar completely transparent (0 opacity) but keep the back button
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        backgroundColor: Colors.transparent, // Completely transparent background
        elevation: 0,
        toolbarHeight: kToolbarHeight,
        // Optional: customize the status bar to match your design
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
      ),
      body: Stack(
        children: [
          // Main content container
          Container(
            child: SafeArea(
              bottom: false,
              child: _currentIndex < _pets.length 
                ? SwipePetDetails(
                    key: ValueKey('current-pet-${_pets[_currentIndex].pet_id}'),
                    pet: _pets[_currentIndex],
                    onSwipeLeft: _handleSwipeLeft,
                    onSwipeRight: _handleSwipeRight,
                    showInteractions: false,
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.pets, size: 80, color: Color(0xFFDDCAC0)),
                        SizedBox(height: 20),
                        Text(
                          'No more pets to show',
                          style: TextStyle(
                            color: Color(0xFF545454),
                            fontSize: 24,
                            fontFamily: 'Arial',
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () => _loadPets(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF725F63),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          ),
                          child: Text('Find More Pets'),
                        ),
                      ],
                    ),
                  ),
            ),
          ),
          
          // Bottom buttons with transparent background
          if (_currentIndex < _pets.length && !_isAnimating)
            Positioned(
              left: 0,
              right: 0,
              bottom: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Dislike button
                  Material(
                    color: Colors.white,
                    elevation: 8,
                    shadowColor: Colors.black.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(50),
                    child: InkWell(
                      onTap: _handleSwipeLeft,
                      borderRadius: BorderRadius.circular(50),
                      child: Container(
                        width: 65,
                        height: 65,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close,
                          color: Colors.red.shade400,
                          size: 30,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 40),
                  // Like button
                  Material(
                    color: Colors.white,
                    elevation: 8,
                    shadowColor: Colors.black.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(50),
                    child: InkWell(
                      onTap: _handleSwipeRight,
                      borderRadius: BorderRadius.circular(50),
                      child: Container(
                        width: 65,
                        height: 65,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.favorite,
                          color: Colors.pink.shade400,
                          size: 30,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
          // Animation and other elements
          if (_showPreviousPet && _previousPet != null)
            AnimatedBuilder(
              animation: _swipeController,
              builder: (context, child) {
                final offset = _isDragging ? _dragOffset : _slideAnimation.value;
                
                // Calculate rotation based on horizontal offset
                double rotation = _isDragging 
                    ? (_dragOffset.dx / _screenWidth) * 0.2
                    : _rotationAnimation.value * (_slideAnimation.value.dx > 0 ? 1 : -1);
                
                return Transform.translate(
                  offset: offset,
                  child: Transform.rotate(
                    angle: rotation,
                    child: Stack(
                      children: [
                        // Pet details card
                        child!,
                        
                        // Like indicator overlay
                        if (_isSwipingRight) 
                          Positioned(
                            top: 40,
                            right: 40,
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.8),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.favorite, color: Colors.white, size: 30),
                                  SizedBox(width: 6),
                                  Text(
                                    'LIKE',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        
                        // Dislike indicator overlay
                        if (_isSwipingLeft)
                          Positioned(
                            top: 40,
                            left: 40,
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.8),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.close, color: Colors.white, size: 30),
                                  SizedBox(width: 6),
                                  Text(
                                    'NOPE',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
              // Use key to ensure proper rebuild
              child: SwipePetDetails(
                key: ValueKey('previous-pet-${_previousPet?.pet_id ?? 'none'}'),
                pet: _previousPet!,
                onSwipeLeft: () {},
                onSwipeRight: () {},
                showInteractions: false,
              ),
            ),
            
          // Better swipe gesture detection - only in the card header area
          if (_currentIndex < _pets.length && !_isAnimating)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 220, // Reduced height to only cover top portion of the image
              child: GestureDetector(
                // Only detect horizontal drags to differentiate from scrolling
                onHorizontalDragStart: (_) {
                  setState(() {
                    _isDragging = true;
                  });
                },
                onHorizontalDragUpdate: (details) {
                  setState(() {
                    _dragOffset = Offset(
                      _dragOffset.dx + details.delta.dx,
                      0, // Lock vertical movement
                    );
                    
                    // Determine swipe direction for UI indication
                    _isSwipingRight = _dragOffset.dx > 50;
                    _isSwipingLeft = _dragOffset.dx < -50;
                  });
                },
                onHorizontalDragEnd: (details) {
                  // Detect swipe based on velocity rather than position
                  if (details.primaryVelocity != null) {
                    if (details.primaryVelocity! > 800) {
                      _handleSwipeRight();
                    } else if (details.primaryVelocity! < -800) {
                      _handleSwipeLeft();
                    } else if (_dragOffset.dx > _screenWidth * 0.3) {
                      _handleSwipeRight();
                    } else if (_dragOffset.dx < -_screenWidth * 0.3) {
                      _handleSwipeLeft();
                    } else {
                      _resetPosition();
                    }
                  }
                },
                // Use a transparent overlay
                child: Container(
                  color: Colors.transparent,
                ),
              ),
            ),
            
          // Show message when all pets have been swiped
          if (_currentIndex >= _pets.length)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.pets, size: 80, color: Color(0xFFDDCAC0)),
                  SizedBox(height: 20),
                  Text(
                    'No more pets to show',
                    style: TextStyle(
                      color: Color(0xFF545454),
                      fontSize: 24,
                      fontFamily: 'Arial',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      // Reload pets
                      _loadPets();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF725F63),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                    child: Text('Find More Pets'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
