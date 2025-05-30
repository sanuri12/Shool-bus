import 'package:firebase_auth/firebase_auth.dart';

class AuthenticationService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String _convertUsernameToEmail(String username) {
    return "$username@yourapp.com"; // Simulate email from username
  }

  Future<User?> signUpWithUsername({
    required String username,
    required String password,
  }) async {
    try {
      final email = _convertUsernameToEmail(username);
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } catch (e) {
      print("Sign Up Error: $e");
      rethrow;
    }
  }

  Future<User?> signInWithUsername({
    required String username,
    required String password,
  }) async {
    try {
      final email = _convertUsernameToEmail(username);
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } catch (e) {
      print("Sign In Error: $e");
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  User? getCurrentUser() {
    return _auth.currentUser;
  }

  Stream<User?> authStateChanges() {
    return _auth.authStateChanges();
  }
}
