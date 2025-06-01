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

  Future<void> signUpFunction({required BuildContext context,required String email,required String password}) async {
    if( email.isEmpty && password.isEmpty){
      Fluttertoast.showToast(msg: "Enter Required Fields..!");
    }
    else{
      UserCredential userCredential;
      try{
        userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: password);
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => SignInScreen(),));

        _firestore.collection('user').doc(userCredential.user!.uid).set({'uid':userCredential.user!.uid,'email':email});


      }
      on FirebaseException catch(e){
        print(e);
        Fluttertoast.showToast(msg: e.code.toString());
      }
    }
  }

  Future<void> signIpFunction({required BuildContext context, required String email, required String password}) async {
    try {
      if (email.isEmpty || password.isEmpty) {
        Fluttertoast.showToast(msg: "Please enter email and password");
        return;
      }

      final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      /// add a new documents  for the user in user collection if it is  doesn't exits
      _firestore.collection('user').doc(userCredential.user!.uid).set({'uid':userCredential.user!.uid,'email':email},SetOptions(merge: true));
      // Successfully logged in
      if (userCredential.user != null) {
        Fluttertoast.showToast(msg: "Login Successfully...");
        Navigator.push(context, MaterialPageRoute(builder: (context) => const ChatHomeScreen(),));
      }
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
    } catch (e) {
      Fluttertoast.showToast(msg: "An unexpected error occurred");
      debugPrint("Login error: $e");
    }
  }

  Future<void> signOut(BuildContext context) async {
    await _googleSignIn.signOut();
    await _auth.signOut();
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => SignInScreen(),));
  }

}

