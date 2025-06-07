import 'package:chat_app/service/model/user_chat_model.dart';
import 'package:chat_app/view/chat/chat_page.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../service/auth_service/Functions.dart';

class ChatHomeScreen extends StatefulWidget {
  const ChatHomeScreen({super.key});

  @override
  State<ChatHomeScreen> createState() => _ChatHomeScreenState();
}

class _ChatHomeScreenState extends State<ChatHomeScreen> {

  final FirebaseAuth _auth = FirebaseAuth.instance;
final Functions function = Functions();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Row(
          children: [
            SizedBox(
              height: 30,
                child: Image.asset('assets/chat.png')),
            const SizedBox(width: 10,),
            const Text('ChatApp',style: TextStyle(color: Colors.white,fontWeight: FontWeight.w500),),
          ],
        ),automaticallyImplyLeading: false,
        backgroundColor: Colors.blueGrey.shade300,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              function.signOut(context);
            },
          ),
        ],
      ),
      body: _buildUserslist(),
    );
  }

  Widget _buildUserslist() {
    return StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('user').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Text('Error');
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();
          }
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: ListView(
              children: snapshot.data!.docs
                  .map<Widget>((doc) => _buildUserslistItem(doc))
                  .toList(),
            ),
          );
        });
  }

  Widget _buildUserslistItem(DocumentSnapshot document) {
    Map<String, dynamic> data = document.data()! as Map<String, dynamic>;
    double height = MediaQuery.sizeOf(context).height;
    double width = MediaQuery.sizeOf(context).width;
    /// display all user except current user
    if (_auth.currentUser!.email != data['email']) {
      print("data ${data}");
      return Container(
        width: width * 0.9,
        height: width *0.13,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black87)
        ),
        child: ListTile(
          title: Text(data['username']),
          leading: Image.asset('assets/user.png',height: 30,),
          onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatPage(
                  userEmail: data['username'],
                  userId: data['uid'],
                ),
              )),
        ),
      );
    } else {
      return Container();
    }
  }
}
