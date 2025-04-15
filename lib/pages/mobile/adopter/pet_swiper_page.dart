import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pawsmatch/models/pet.dart';
import 'package:pawsmatch/pages/mobile/adopter/swipe_pet_details.dart';
import 'package:pawsmatch/services/firebase_adopt_service.dart';
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
      // Get IDs of pets the user has already liked
      final likedPetIds = await _swipeService.getCurrentUserLikedPetIds();
      
      // Get IDs of pets for which the user has active adoption requests
      final FirebaseAdoptService _adoptService = FirebaseAdoptService();
      final adoptionRequestPetIds = await _adoptService.getCurrentUserAdoptionRequestPetIds();
      
      // Get a large batch of pets to filter and shuffle
      final allPets = await _petService.getPets(limit: 50);
      
      // Filter out both liked pets and pets with adoption requests
      final availablePets = allPets.where((pet) => 
        !likedPetIds.contains(pet.pet_id) && 
        !adoptionRequestPetIds.contains(pet.pet_id)
      ).toList();
      
      // Randomize the order of pets
      if (availablePets.isNotEmpty) {
        availablePets.shuffle(Random());
      }
      
      // Take a smaller subset for better performance
      final displayPets = availablePets.take(15).toList();
      
      setState(() {
        _pets = displayPets;
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

    void _handleSwipeLeft() {
    if (_isAnimating) return;
    
    final currentPet = _pets[_currentIndex];
    
    setState(() {
      _isAnimating = true;
      _showPreviousPet = true;
      _previousPet = currentPet;
      // Save the current drag offset for the animation
      _slideAnimation = Tween<Offset>(
        begin: _dragOffset,
        end: Offset(-2.0, -0.3),
      ).animate(CurvedAnimation(
        parent: _swipeController,
        curve: Curves.easeOutCubic,
      ));
    });

    _recordSwipe(false);
    _swipeController.forward();
    
    Future.delayed(Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          if (_currentIndex < _pets.length - 1) {
            _currentIndex++;
          }
          _dragOffset = Offset.zero;
          _isDragging = false;
          _isSwipingLeft = false;
          _showPreviousPet = false;
          _isAnimating = false;
        });
        _swipeController.reset();
      }
    });
  }

  void _handleSwipeRight() {
    if (_isAnimating) return;
    
    final currentPet = _pets[_currentIndex];
    
    setState(() {
      _isAnimating = true;
      _showPreviousPet = true;
      _previousPet = currentPet;
      // Save the current drag offset for the animation
      _slideAnimation = Tween<Offset>(
        begin: _dragOffset,
        end: Offset(2.0, -0.3),
      ).animate(CurvedAnimation(
        parent: _swipeController,
        curve: Curves.easeOutCubic,
      ));
    });

    _recordSwipe(true);
    _swipeController.forward();

    Future.delayed(Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          if (_currentIndex < _pets.length - 1) {
            _currentIndex++;
          }
          // Reset state for the new current card
          _dragOffset = Offset.zero;
          _isDragging = false;
          _isSwipingRight = false;
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
        // Don't await this operation to prevent UI blocking
        _swipeService.recordSwipe(
          _pets[_currentIndex].pet_id, 
          liked
        ).then((success) {
          // Only show feedback if UI is still mounted and success is true
          if (success && mounted) {
            // Use a more subtle indication for swipe recording
            // Quick toast message instead of SnackBar for a smoother experience
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(liked ? 'Pet liked!' : 'Skipped this pet'),
                duration: Duration(milliseconds: 500), // Shorter duration
                behavior: SnackBarBehavior.floating, // Make it less intrusive
                margin: EdgeInsets.only(bottom: 100, left: 50, right: 50),
              ),
            );
          }
        });
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

  // Completely redesigned build method with isolated card animations 
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
          bottom: false,
          child: Stack(
            children: [
              // Background layer
              Positioned.fill(
                child: Container(color: const Color(0xFFFEF5F0)),
              ),
              
              // Cards stack - completely redesigned for proper isolation
              AnimatedSwitcher(
                duration: Duration(milliseconds: 300),
                child: _currentIndex < _pets.length 
                  ? _buildCardStack()
                  : _buildEmptyState(),
              ),
              
              // Action buttons
              if (_currentIndex < _pets.length && !_isAnimating)
                _buildActionButtons(),
              
              // Status indicators (Like/Dislike)
              if (_isDragging || _isAnimating)
                _buildStatusIndicators(),
            ],
          ),
        ),
      ),
    );
  }

  // New method that builds the stack of cards with proper isolation
  Widget _buildCardStack() {
    return Stack(
      key: ValueKey('card-stack-$_currentIndex'),
      children: [
        // Next card (card after the current one) - always position at the bottom
        if (_currentIndex < _pets.length - 1)
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            bottom: 100,
            child: Opacity(
              opacity: _isDragging ? 
                min(1.0, _dragOffset.distance / (_screenWidth * 0.5)) * 0.7 : 0.0,
              child: Transform.scale(
                scale: 0.95,
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
          ),

        // Current card - only affected by its own dragging
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          bottom: 100,
          child: GestureDetector(
            onPanStart: (details) {
              if (!_isAnimating) {
                setState(() {
                  _isDragging = true;
                  _dragOffset = Offset.zero;
                });
              }
            },
            onPanUpdate: (details) {
              if (!_isAnimating && _isDragging) {
                setState(() {
                  _dragOffset += details.delta;
                  
                  // Limit vertical drag
                  if (_dragOffset.dy > 50) _dragOffset = Offset(_dragOffset.dx, 50);
                  if (_dragOffset.dy < -50) _dragOffset = Offset(_dragOffset.dx, -50);
                  
                  // Update swipe indicators
                  _isSwipingRight = _dragOffset.dx > 50;
                  _isSwipingLeft = _dragOffset.dx < -50;
                });
              }
            },
            onPanEnd: (details) {
              if (_isAnimating || !_isDragging) return;
              
              final velocity = details.velocity.pixelsPerSecond;
              final positionThreshold = _screenWidth * 0.35;
              final velocityThreshold = _screenWidth * 1.5;
              
              if (velocity.dx > velocityThreshold || _dragOffset.dx > positionThreshold) {
                _handleSwipeRight();
              } else if (velocity.dx < -velocityThreshold || _dragOffset.dx < -positionThreshold) {
                _handleSwipeLeft();
              } else {
                _resetPosition();
              }
            },
            child: Transform.translate(
              offset: _dragOffset,
              child: Transform.rotate(
                angle: (_dragOffset.dx / _screenWidth) * 0.2,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SwipePetDetails(
                    key: ValueKey('current-pet-${_pets[_currentIndex].pet_id}'),
                    pet: _pets[_currentIndex],
                    onSwipeLeft: _handleSwipeLeft,
                    onSwipeRight: _handleSwipeRight,
                    showInteractions: false,
                  ),
                ),
              ),
            ),
          ),
        ),
        
        // Previous card animation - completely separated from current card
        if (_showPreviousPet && _previousPet != null)
          AnimatedBuilder(
            animation: _swipeController,
            builder: (context, child) {
              return Transform.translate(
                offset: _slideAnimation.value,
                child: Transform.rotate(
                  angle: _rotationAnimation.value * (_slideAnimation.value.dx > 0 ? 1 : -1),
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    child: child,
                  ),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: SwipePetDetails(
                key: ValueKey('previous-pet-${_previousPet!.pet_id}-${DateTime.now().millisecondsSinceEpoch}'),
                pet: _previousPet!,
                onSwipeLeft: () {},
                onSwipeRight: () {},
                showInteractions: false,
              ),
            ),
          ),
      ],
    );
  }
  
  // Helper method for status indicators
  Widget _buildStatusIndicators() {
    return IgnorePointer(
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
    );
  }
  
  // Helper method for action buttons
  Widget _buildActionButtons() {
    return Positioned(
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
    );
  }
  
  // Helper for the empty state when all cards are swiped
  Widget _buildEmptyState() {
    return Positioned.fill(
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
            // ...rest of empty state content...
          ],
        ),
      ),
    );
  }


}
