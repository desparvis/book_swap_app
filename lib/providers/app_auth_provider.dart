// lib/providers/app_auth_provider.dart
import 'package:cloud_firestore/cloud_firestore.dart'; // ← ADDED FOR USER PROFILE
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AppAuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _user;

  User? get user => _user;
  bool get isAuthenticated => _user != null;

  AppAuthProvider() {
    _auth.authStateChanges().listen((User? user) {
      _user = user;
      notifyListeners();
    });
  }

  // SIGN UP WITH NAME + SAVE TO FIRESTORE
  Future<void> signUp({
    required String name,
    required String email,
    required String password,
    required BuildContext context,
  }) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = result.user;
      if (user != null) {
        // Update display name
        await user.updateDisplayName(name);
        await user.sendEmailVerification();

        // SAVE USER TO FIRESTORE (THIS FIXES THE CRASH)
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'name': name,
          'email': email,
          'createdAt': FieldValue.serverTimestamp(),
        });

        _user = user;
        notifyListeners();
      }
    } on FirebaseAuthException catch (e) {
      if (context.mounted) {
        _showError(context, e.message ?? "Signup failed");
      }
    } catch (e) {
      if (context.mounted) {
        _showError(context, "An error occurred. Try again.");
      }
    }
  }

  // SIGN IN
  Future<void> signIn({
    required String email,
    required String password,
    required BuildContext context,
  }) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = result.user;
      if (user != null && user.emailVerified) {
        _user = user;
        notifyListeners();
      } else if (user != null && !user.emailVerified) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Please verify your email first."),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      if (context.mounted) {
        _showError(context, e.message ?? "Login failed");
      }
    }
  }

  // SIGN OUT
  Future<void> signOut(BuildContext context) async {
    await _auth.signOut();
    _user = null;
    notifyListeners();
  }

  // RESEND VERIFICATION
  Future<void> resendVerification(BuildContext context) async {
    if (_user != null && !_user!.emailVerified) {
      await _user!.sendEmailVerification();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Verification email sent!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  // HELPER: SHOW ERROR
  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}