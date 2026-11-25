
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
  }) {
    return _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<UserCredential> signInWithGoogle() async {
    final googleSignIn = GoogleSignIn.instance;

    if (!googleSignIn.supportsAuthenticate()) {
      throw UnsupportedError(
        'Google Sign-In is not supported on this platform.',
      );
    }

    final googleUser = await googleSignIn.authenticate();
    final googleAuth = googleUser.authentication;

    final idToken = googleAuth.idToken;

    if (idToken == null) {
      throw StateError('Google did not provide an ID token.');
    }

    final credential = GoogleAuthProvider.credential(
      idToken: idToken,
    );

    return _auth.signInWithCredential(credential);
  }

  Future<void> signOut() async {
    await _auth.signOut();

    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {
      // Firebase sign-out has already completed.
    }
  }

  String friendlyError(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'weak-password':
        return 'Please choose a stronger password.';
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        return 'Incorrect email or password.';
      case 'account-exists-with-different-credential':
        return 'This email uses another sign-in method.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Check your internet connection.';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }
}
