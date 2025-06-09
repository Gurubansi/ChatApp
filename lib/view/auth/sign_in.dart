import 'package:chat_app/Providers/authProvider.dart' as provider;
import 'package:chat_app/service/auth_service/Functions.dart';
import 'package:chat_app/view/auth/SocialButton.dart';
import 'package:chat_app/view/auth/signup.dart';
import 'package:chat_app/view/chat/chat_home.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';


class SignInScreen extends StatelessWidget {
   SignInScreen({super.key});


  @override
  Widget build(BuildContext context) {
    final _formKey = GlobalKey<FormState>();
    final Functions functions = Functions();
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Consumer<provider.AuthProvider>(builder: (context, value, child) {
            return Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 35),
                  // Header with logo
                  Center(
                    child: Image.asset('assets/chat.png',height: 80,width: 80,),
                  ),
                  const SizedBox(height: 25),
                  const Center(
                    child: Text(
                      'Welcome Back!',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      'Sign in to continue your journey',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Email Field
                  Text(
                    'Email',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: value.mailController,
                    decoration: InputDecoration(
                      hintText: 'Enter your mail',
                      prefixIcon: Icon(Icons.email_outlined, color: Colors.grey[600]),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (val) {
                      if (val == null || val.isEmpty) return 'Please enter your email';
                      if (!RegExp(r'\S+@\S+\.\S+').hasMatch(val)) return 'Enter a valid email';
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  // Password Field
                  Text(
                    'Password',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: value.passwordController,
                    obscureText: value.isPasswordVisible,
                    decoration: InputDecoration(
                      hintText: '••••••••',
                      prefixIcon: Icon(Icons.lock_outline, color: Colors.grey[600]),
                      suffixIcon: IconButton(
                        icon: Icon(value.isPasswordVisible ? Icons.visibility : Icons.visibility_off),
                        onPressed: value.togglePasswordVisibility,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                    ),
                    validator: (val) {
                      if (val == null || val.isEmpty) return 'Please enter your password';
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  // Forgot password
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {},
                      child: Text(
                        'Forgot Password?',
                        style: TextStyle(
                          color: Colors.blue[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Sign In Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if(_formKey.currentState!.validate()) {
                          functions.signInFunction(context: context,
                              email: value.mailController.text,
                              password: value.passwordController.text);
                        }},
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.blue[600],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                        shadowColor: Colors.transparent,
                      ),
                      child: const Text(
                        'Sign In',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Divider with text
                  Row(
                    children: [
                      Expanded(
                        child: Divider(
                          color: Colors.grey[300],
                          thickness: 1,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          "Or continue with",
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          color: Colors.grey[300],
                          thickness: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Social Buttons
                  value.isLoading ? const Center(child: CircularProgressIndicator()) : SocialButton(
                    iconImage: 'assets/google.png',
                    label: 'Continue with Google',
                    color: Colors.white,
                    textColor: Colors.black87,
                    borderColor: Colors.grey[300],
                    onTap: () async {
                      User? user = await value.signInWithGoogle();
                      if(user != null){
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const ChatHomeScreen(),));
                        print('Signed in: ${user.displayName}');
                      } else {
                        print('Sign-in failed or cancelled');
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  SocialButton(
                    icon: Icons.facebook,
                    label: 'Continue with Facebook',
                    color: const Color(0xFF1877F2),
                    textColor: Colors.white,
                    onTap: () {},
                  ),
                  const SizedBox(height: 32),
                  // Sign up prompt
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account?",
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const SignUpScreen(),));
                          },
                          child: Text(
                            'Sign Up',
                            style: TextStyle(
                              color: Colors.blue[600],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },),
        ),
      ),
    );
  }
}

