import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// List of available avatar assets
const List<String> availableAvatars = [
  'bear.png',
  'beaver.png',
  'cat.png',
  'cheetah.png',
  'chicken.png',
  'cow.png',
  'dog (1).png',
  'dog.png',
  'dragon.png',
  'duck.png',
  'frog-.png',
  'giraffe.png',
  'gorilla.png',
  'hen.png',
  'hippopotamus.png',
  'koala.png',
  'lion.png',
  'meerkat.png',
  'owl.png',
  'panda.png',
  'penguin.png',
  'puffer-fish.png',
  'rabbit.png',
  'sea-lion.png',
  'shark.png',
  'sloth.png',
  'tiger.png',
];

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  Future<User?> signInAnonymously() async {
    final cred = await _auth.signInAnonymously();
    return cred.user;
  }

  Future<User?> signInWithGoogle() async {
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null; // User cancelled

    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential = await _auth.signInWithCredential(credential);
    return userCredential.user;
  }

  Future<User?> signInWithEmail(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return cred.user;
  }

  Future<User?> signUpWithEmail(String email, String password) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    return cred.user;
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> updatePassword(String oldPassword, String newPassword) async {
    final user = _auth.currentUser;
    if (user != null && user.email != null) {
      // Re-authenticate user before changing password
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: oldPassword,
      );
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
    }
  }

  Future<void> updateEmail(String newEmail) async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.verifyBeforeUpdateEmail(newEmail);
    }
  }

  /// Save user avatar to Firestore
  Future<void> saveUserAvatar(String avatarFileName) async {
    final user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).set({
        'avatar': avatarFileName,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  /// Get user avatar from Firestore
  Future<String?> getUserAvatar([String? userId]) async {
    final uid = userId ?? _auth.currentUser?.uid;
    if (uid == null) return null;
    
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists) {
      return doc.data()?['avatar'] as String?;
    }
    return null;
  }

  /// Stream user avatar changes
  Stream<String?> userAvatarStream([String? userId]) {
    final uid = userId ?? _auth.currentUser?.uid;
    if (uid == null) return Stream.value(null);
    
    return _firestore.collection('users').doc(uid).snapshots().map((doc) {
      if (doc.exists) {
        return doc.data()?['avatar'] as String?;
      }
      return null;
    });
  }
}
