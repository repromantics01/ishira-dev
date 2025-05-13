import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:pawsmatch/firebase_options.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<UserCredential> signInWithEmailAndPassword(String email, String password) async {
    try {

      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      await Future.delayed(Duration(milliseconds: 500));
      
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
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

  Future<void> sendEmailVerification() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }
  
  bool isEmailVerified() {
    User? user = FirebaseAuth.instance.currentUser;
    return user?.emailVerified ?? false;
  }
  
    Future<void> reloadUser() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await user.reload();
    }
  }
}