import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:pawsmatch/firebase_options.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Update the sign-in method with better error handling and delay
  Future<UserCredential> signInWithEmailAndPassword(String email, String password) async {
    try {
      // First ensure Firebase is properly initialized
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      
      // Add a small delay between initialization and auth operations
      await Future.delayed(Duration(milliseconds: 500));
      
      // Perform the sign in
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Add another small delay before any Firestore operations happen
      await Future.delayed(Duration(milliseconds: 500));
      
      return userCredential;
    } on FirebaseAuthException catch (e) {
      print('Authentication error: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      print('Login error: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  User? getCurrentUser() {
    return _auth.currentUser;
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<UserCredential> createUserWithEmailAndPassword(String email, String password) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } on FirebaseAuthException catch (e) {
      print('Registration error: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      print('Registration error: $e');
      rethrow;
    }
  }
}