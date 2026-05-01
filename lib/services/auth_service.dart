import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserModel> signUp({
    required String name,
    required String email,
    required String password,
    required String country,
    required String occupation,
    double? monthlyIncome,
    double? currentSavings,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await cred.user!.updateDisplayName(name);

    final user = UserModel(
      uid: cred.user!.uid,
      name: name.trim(),
      email: email.trim(),
      country: country,
      occupation: occupation,
      monthlyIncome: monthlyIncome,
      currentSavings: currentSavings ?? 0.0,
      createdAt: DateTime.now(),
    );

    await _db.collection('users').doc(cred.user!.uid).set(user.toMap());

    try {
      await cred.user!.sendEmailVerification();
    } finally {
      await _auth.signOut();
    }

    return user;
  }

  Future<UserModel?> signIn({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    await cred.user!.reload();
    final firebaseUser = _auth.currentUser ?? cred.user!;

    if (!firebaseUser.emailVerified) {
      try {
        await firebaseUser.sendEmailVerification();
      } catch (_) {
        // Firebase may rate-limit repeated verification emails.
      }
      await _auth.signOut();
      throw FirebaseAuthException(
        code: 'email-not-verified',
        message:
            'Please verify your email before signing in. We sent a verification link to your inbox.',
      );
    }

    return getUser(cred.user!.uid);
  }

  Future<UserModel?> getUser(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromMap(doc.data()!, uid);
  }

  Future<void> updateSavings(String uid, double newSavings) async {
    await _db.collection('users').doc(uid).update({
      'currentSavings': newSavings,
    });
  }

  Future<void> signOut() async => _auth.signOut();
}
