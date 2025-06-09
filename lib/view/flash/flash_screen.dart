import 'package:chat_app/service/auth_service/Functions.dart';
import 'package:chat_app/view/auth/sign_in.dart';
import 'package:chat_app/view/chat/chat_home.dart';
import 'package:flutter/material.dart';

class FlashScreen extends StatefulWidget {
  const FlashScreen({super.key});

  @override
  State<FlashScreen> createState() => _FlashScreenState();
}

class _FlashScreenState extends State<FlashScreen> with TickerProviderStateMixin {
  late final AnimationController _controller =
  AnimationController(vsync: this,duration: const Duration(seconds: 2))..repeat(reverse: true);
  late final Animation<double> _animation = CurvedAnimation(parent: _controller, curve: Curves.fastOutSlowIn);
  final Functions functions = Functions();

@override
  void initState() {
    // TODO: implement initState
    super.initState();
    _navigateBasedOnUserId();
}
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  Future<void> _navigateBasedOnUserId() async {
    // Wait for a short duration to show the splash screen
    await Future.delayed(const Duration(seconds: 4));

    // Get userId
    final userId = await functions.getUserId();

    // Navigate based on userId
    if (userId == null || userId.isEmpty) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) =>  SignInScreen()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) =>  const ChatHomeScreen()),
      );
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ScaleTransition(scale: _animation,child: Image.asset("assets/chat.png",height: 90,width: 90,),),
      ),
    );
  }
}
