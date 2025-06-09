import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider extends ChangeNotifier {
  final mailController = TextEditingController();
  final nameController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isPasswordVisible = false;
  bool isLoading = false;
  bool _isConfirmPasswordVisible = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool get isPasswordVisible => _isPasswordVisible;
  bool get isConfirmPasswordVisible => _isConfirmPasswordVisible;

  void clearField() {
    nameController.clear();
    confirmPasswordController.clear();
    mailController.clear();
    passwordController.clear();
  }
  void togglePasswordVisibility() {
    _isPasswordVisible = !_isPasswordVisible;
    notifyListeners();
  }

  void toggleConfirmPasswordVisibility() {
    _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
    notifyListeners();
  }

  Future<User?> signInWithGoogle() async {
    try {
      isLoading = true;
      notifyListeners();
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase
      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);
      /// add a new documents  for the user in user collection if it is  doesn't exits
      _firestore.collection('user').doc(userCredential.user!.uid).set(
          {'uid':userCredential.user!.uid,
            'email':userCredential.user!.email,
            'username':userCredential.user!.displayName
          },SetOptions(merge: true));
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('userId', userCredential.user!.uid.toString());
      String? userId = await prefs.getString('userId');
      print("User Id ====>> $userId");
      return userCredential.user;
    } catch (e) {
      print("Google Sign-In error: $e");
      return null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
