import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pawsmatch/models/pet.dart';
import 'package:pawsmatch/pages/mobile/adopter/swipe_pet_details.dart';
import 'package:pawsmatch/services/firebase_pet_service.dart';
import 'package:pawsmatch/services/firebase_swipe_service.dart'; // Add this import
import 'dart:math';

class PetSwiperPage extends StatefulWidget {
  const PetSwiperPage({Key? key}) : super(key: key);

  @override
  _PetSwiperPageState createState() => _PetSwiperPageState();
}

class _PetSwiperPageState extends State<PetSwiperPage> with TickerProviderStateMixin {
  final FirebasePetService _petService = FirebasePetService();
  final FirebaseSwipeService _swipeService = FirebaseSwipeService(); // Add this
  
  List<Pet> _pets = [];
  bool _isLoading = true;
  int _currentIndex = 0;
  
  // Animation controllers
  late AnimationController _swipeController;
  late AnimationController _progressController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _nextCardScaleAnimation;
  
  // Swipe state tracking
  Offset _dragOffset = Offset.zero;
  bool _isDragging = false;
  bool _isSwipingRight = false;
  bool _isSwipingLeft = false;
  
  // Screen width for calculations
  double _screenWidth = 0;
  double _screenHeight = 0;

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
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
    
    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(1.5, 0.0),
    ).animate(CurvedAnimation(
      parent: _swipeController,
      curve: Curves.easeOutBack,
    ));
    
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.3,  // Increased rotation for more visual appeal
    ).animate(CurvedAnimation(
      parent: _swipeController,
      curve: Curves.easeOutCubic,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.8,  // Card scales down slightly as it swipes away
    ).animate(CurvedAnimation(
      parent: _swipeController,
      curve: Curves.easeOutCubic,
    ));
    
    _nextCardScaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,  // Next card scales up as current card swipes away
    ).animate(CurvedAnimation(
      parent: _swipeController,
      curve: Curves.easeOutCubic,
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
    
    // Set the end position for the swipe animation
    _slideAnimation = Tween<Offset>(
      begin: _dragOffset,
      end: Offset(-2.0, -0.3), // Add a slight downward motion for more natural feel
    ).animate(CurvedAnimation(
      parent: _swipeController,
      curve: Curves.easeOutCubic,
    ));

    // Trigger the animation
    await _swipeController.forward();
    
    // After animation completes, update to next pet
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
    
    // Record the swipe in the background
    _recordSwipe(false);
    
    // Clean up animation state after a short delay to ensure smooth transition
    Future.delayed(const Duration(milliseconds: 300), () {
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
    
    // Set the end position for the swipe animation
    _slideAnimation = Tween<Offset>(
      begin: _dragOffset,
      end: Offset(2.0, -0.3), // Add a slight downward motion for more natural feel
    ).animate(CurvedAnimation(
      parent: _swipeController,
      curve: Curves.easeOutCubic,
    ));

    // Trigger the animation
    await _swipeController.forward();
    
    // After animation completes, update to next pet
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
    
    // Record the swipe in the background
    _recordSwipe(true);
    
    // Clean up animation state after a short delay to ensure smooth transition
    Future.delayed(const Duration(milliseconds: 300), () {
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
        final success = await _swipeService.recordSwipe(
          _pets[_currentIndex].pet_id, 
          liked
        );
        
        if (success && mounted) {
          // Show feedback if successful
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
    // Return card to center with a springy animation
    _slideAnimation = Tween<Offset>(
      begin: _dragOffset,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _swipeController,
      curve: Curves.elasticOut,
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

  @override
  Widget build(BuildContext context) {
    _screenWidth = MediaQuery.of(context).size.width;
    _screenHeight = MediaQuery.of(context).size.height;
    
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
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      body: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFEF5F0),
        ),
        child: SafeArea(
          bottom: false, // Don't add padding at bottom
          child: Stack(
            children: [
              // Background layer
              Positioned.fill(
                child: Container(color: const Color(0xFFFEF5F0)),
              ),
              
              // Next card preview (shown slightly behind the current card)
              if (_currentIndex < _pets.length - 1)
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  bottom: 100,
                  child: AnimatedBuilder(
                    animation: _swipeController,
                    builder: (context, child) {
                      // Only show next card if we're swiping the current one
                      double opacity = _isDragging || _isAnimating ? 
                          0.7 + 0.3 * min(1, _dragOffset.distance / (_screenWidth * 0.5)) : 0.0;
                      
                      return Opacity(
                        opacity: opacity,
                        child: Transform.scale(
                          scale: _nextCardScaleAnimation.value,
                          child: child,
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: SwipePetDetails(
                        key: ValueKey('next-pet-${_pets[_currentIndex + 1].pet_id}'),
                        pet: _pets[_currentIndex + 1],
                        onSwipeLeft: () {},
                        onSwipeRight: () {},
                        showInteractions: false,
                      ),
                    ),
                  ),
                ),
              
              // Current pet card with interactive gestures
              if (_currentIndex < _pets.length)
                GestureDetector(
                  onPanStart: (details) {
                    setState(() {
                      _isDragging = true;
                    });
                  },
                  onPanUpdate: (details) {
                    if (_isAnimating) return;
                    setState(() {
                      _dragOffset += details.delta;
                      
                      // Keep the vertical drag limited for better UX
                      if (_dragOffset.dy > 50) _dragOffset = Offset(_dragOffset.dx, 50);
                      if (_dragOffset.dy < -50) _dragOffset = Offset(_dragOffset.dx, -50);
                      
                      // Update swipe indicators
                      _isSwipingRight = _dragOffset.dx > 50;
                      _isSwipingLeft = _dragOffset.dx < -50;
                    });
                  },
                  onPanEnd: (details) {
                    if (_isAnimating) return;
                    final velocity = details.velocity.pixelsPerSecond;
                    
                    // Calculate swipe velocity threshold based on screen width
                    final velocityThreshold = _screenWidth * 1.5;
                    final positionThreshold = _screenWidth * 0.35;
                    
                    if (velocity.dx > velocityThreshold || _dragOffset.dx > positionThreshold) {
                      _handleSwipeRight();
                    } else if (velocity.dx < -velocityThreshold || _dragOffset.dx < -positionThreshold) {
                      _handleSwipeLeft();
                    } else {
                      _resetPosition();
                    }
                  },
                  child: AnimatedBuilder(
                    animation: _swipeController,
                    builder: (context, child) {
                      // Calculate dynamic rotation based on horizontal offset
                      double rotation = 0.0;
                      if (_isDragging) {
                        rotation = (_dragOffset.dx / _screenWidth) * 0.2;
                      } else if (!_swipeController.isDismissed) {
                        rotation = _rotationAnimation.value * (_slideAnimation.value.dx > 0 ? 1 : -1);
                      }
                      
                      // Calculate scale adjustment based on drag distance
                      double scale = 1.0;
                      if (_isDragging) {
                        // Scale down slightly when dragging for better visual feedback
                        final dragPercentage = min(0.15, _dragOffset.distance / (_screenWidth * 3));
                        scale = 1.0 - dragPercentage;
                      } else if (!_swipeController.isDismissed) {
                        scale = _scaleAnimation.value;
                      }
                      
                      // Get the offset for the card
                      final offset = _isDragging ? _dragOffset : _slideAnimation.value;
                      
                      return Transform.translate(
                        offset: offset,
                        child: Transform.rotate(
                          angle: rotation,
                          child: Transform.scale(
                            scale: scale,
                            child: child,
                          ),
                        ),
                      );
                    },
                    child: SwipePetDetails(
                      key: ValueKey('current-pet-${_pets[_currentIndex].pet_id}'),
                      pet: _pets[_currentIndex],
                      onSwipeLeft: _handleSwipeLeft,
                      onSwipeRight: _handleSwipeRight,
                      showInteractions: false,
                    ),
                  ),
                ),
                
              // Previous pet being swiped away (for animation)
              if (_showPreviousPet && _previousPet != null)
                AnimatedBuilder(
                  animation: _swipeController,
                  builder: (context, child) {
                    // Get the offset for the card
                    final offset = _slideAnimation.value;
                    
                    // Calculate rotation based on horizontal offset
                    double rotation = _rotationAnimation.value * (offset.dx > 0 ? 1 : -1);
                    
                    return Transform.translate(
                      offset: offset,
                      child: Transform.rotate(
                        angle: rotation,
                        child: Transform.scale(
                          scale: _scaleAnimation.value,
                          child: child,
                        ),
                      ),
                    );
                  },
                  child: SwipePetDetails(
                    key: ValueKey('previous-pet-${_previousPet?.pet_id ?? 'none'}'),
                    pet: _previousPet!,
                    onSwipeLeft: () {},
                    onSwipeRight: () {},
                    showInteractions: false,
                  ),
                ),
              
              // Like/Dislike status indicators
              if (_isDragging || _isAnimating)
                IgnorePointer(
                  child: AnimatedOpacity(
                    opacity: (_isSwipingRight || _isSwipingLeft) ? 1.0 : 0.0,
                    duration: Duration(milliseconds: 200),
                    child: Stack(
                      children: [
                        // Like indicator
                        if (_isSwipingRight)
                          Positioned(
                            top: _screenHeight * 0.15,
                            right: 40,
                            child: Transform.rotate(
                              angle: -0.2,
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.8),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                child: Text(
                                  'LIKE',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        
                        // Dislike indicator
                        if (_isSwipingLeft)
                          Positioned(
                            top: _screenHeight * 0.15,
                            left: 40,
                            child: Transform.rotate(
                              angle: 0.2,
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.8),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                child: Text(
                                  'NOPE',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              
              // Enhanced empty state message when all pets have been swiped
              if (_currentIndex >= _pets.length)
                Positioned.fill(
                  child: Container(
                    padding: EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF5F0),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.pets_rounded,
                            size: 80,
                            color: Color(0xFFDDCAC0),
                          ),
                        ),
                        SizedBox(height: 30),
                        Text(
                          'You\'ve viewed all pets!',
                          style: TextStyle(
                            color: Color(0xFF473C38),
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Check back soon to see new pets available for adoption.',
                          style: TextStyle(
                            color: Color(0xFF8E7A72),
                            fontSize: 18,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 40),
                        Container(
                          width: double.infinity,
                          margin: EdgeInsets.symmetric(horizontal: 40),
                          child: ElevatedButton(
                            onPressed: _loadPets,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF725F63),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              padding: EdgeInsets.symmetric(vertical: 16),
                              elevation: 4,
                            ),
                            child: Text(
                              'Refresh Pet List',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 16),
                        TextButton.icon(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: Icon(Icons.arrow_back, color: Color(0xFF725F63)),
                          label: Text(
                            'Back to Home',
                            style: TextStyle(
                              color: Color(0xFF725F63),
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              
              // Action buttons with transparent background
              if (_currentIndex < _pets.length && !_isAnimating)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 20,
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 20),
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
                              width: 70,
                              height: 70,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.close,
                                color: Colors.red.shade400,
                                size: 35,
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
                              width: 70,
                              height: 70,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.favorite,
                                color: Colors.pink.shade400,
                                size: 35,
                              ),
                            ),
                          ),
                        ),
                      ],
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
