import 'package:chat_app/view/auth/sign_in.dart';
import 'package:chat_app/view/chat/chat_home.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Functions {
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<bool> isUsernameAvailable(String username) async {
    final query = await _firestore
        .collection('user')
        .where('username', isEqualTo: username)
        .get();
    return query.docs.isEmpty;
  }

  Future<void> signUpFunction({
    required BuildContext context,
    required String email,
    required String password,
    required String username,
  }) async {
    if (email.isEmpty || password.isEmpty || username.isEmpty) {
      Fluttertoast.showToast(msg: "Enter Required Fields..!");
      return;
    }

    // Check if username is available
    bool isAvailable = await isUsernameAvailable(username);
    if (!isAvailable) {
      Fluttertoast.showToast(msg: "Username is already taken.");
      return;
    }

    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      // Update displayName in Firebase Authentication
      await userCredential.user?.updateProfile(displayName: username);
      await userCredential.user?.reload();

      // Save user data in Firestore
      await _firestore.collection('user').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'email': email,
        'username': username,
        'createdAt': FieldValue.serverTimestamp(),
      });

      Fluttertoast.showToast(msg: "Sign Up Successful!");
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => SignInScreen()),
      );
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'weak-password':
          errorMessage = "The password provided is too weak.";
          break;
        case 'email-already-in-use':
          errorMessage = "The account already exists for that email.";
          break;
        case 'invalid-email':
          errorMessage = "Invalid email format.";
          break;
        default:
          errorMessage = "Sign-up failed: ${e.message}";
      }
      Fluttertoast.showToast(msg: errorMessage);
      debugPrint("Sign-up error: $e");
    } catch (e) {
      Fluttertoast.showToast(msg: "An unexpected error occurred");
      debugPrint("Sign-up error: $e");
    }
  }

  Future<void> signInFunction({
    required BuildContext context,
    required String email,
    required String password,
  }) async {
    try {
      if (email.isEmpty || password.isEmpty) {
        Fluttertoast.showToast(msg: "Please enter email and password");
        return;
      }

      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      // Ensure user data exists in Firestore (merge to avoid overwriting username)
      await _firestore.collection('user').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'email': email,
      }, SetOptions(merge: true));

      Fluttertoast.showToast(msg: "Login Successfully...");
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ChatHomeScreen()),
      );
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'invalid-email':
          errorMessage = "Invalid email format";
          break;
        case 'user-not-found':
          errorMessage = "No user found with this email";
          break;
        case 'wrong-password':
          errorMessage = "Incorrect password";
          break;
        case 'user-disabled':
          errorMessage = "This account has been disabled";
          break;
        default:
          errorMessage = "Login failed: ${e.message}";
      }
      Fluttertoast.showToast(msg: errorMessage);
      debugPrint("Login error: $e");
    } catch (e) {
      Fluttertoast.showToast(msg: "An unexpected error occurred");
      debugPrint("Login error: $e");
    }
  }

  Future<void> updateUsername({
    required BuildContext context,
    required String newUsername,
    required String email,
    required String password,
  }) async {
    if (newUsername.isEmpty) {
      Fluttertoast.showToast(msg: "Please enter a username");
      return;
    }

    // Check if username is available
    bool isAvailable = await isUsernameAvailable(newUsername);
    if (!isAvailable) {
      Fluttertoast.showToast(msg: "Username is already taken.");
      return;
    }

    try {
      User? user = _auth.currentUser;
      if (user == null) {
        Fluttertoast.showToast(msg: "No user is signed in.");
        return;
      }

      // Re-authenticate user
      AuthCredential credential = EmailAuthProvider.credential(
        email: email.trim(),
        password: password.trim(),
      );
      await user.reauthenticateWithCredential(credential);

      // Update displayName in Firebase Authentication
      await user.updateProfile(displayName: newUsername);
      await user.reload();

      // Update username in Firestore
      await _firestore.collection('user').doc(user.uid).update({
        'username': newUsername,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      Fluttertoast.showToast(msg: "Username updated successfully!");
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'wrong-password':
          errorMessage = "Incorrect password";
          break;
        case 'invalid-email':
          errorMessage = "Invalid email format";
          break;
        case 'user-not-found':
          errorMessage = "User not found";
          break;
        default:
          errorMessage = "Update failed: ${e.message}";
      }
      Fluttertoast.showToast(msg: errorMessage);
      debugPrint("Update username error: $e");
    } catch (e) {
      Fluttertoast.showToast(msg: "An unexpected error occurred");
      debugPrint("Update username error: $e");
    }
  }

  Future<void> signOut(BuildContext context) async {
    await _googleSignIn.signOut();
    await _auth.signOut();
    Fluttertoast.showToast(msg: "Signed out successfully");
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => SignInScreen()),
    );
  }
}