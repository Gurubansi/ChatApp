import 'package:chat_app/view/chat/chat_page.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../../service/auth_service/Functions.dart';

class ChatHomeScreen extends StatefulWidget {
  const ChatHomeScreen({super.key});

  @override
  State<ChatHomeScreen> createState() => _ChatHomeScreenState();
}

class _ChatHomeScreenState extends State<ChatHomeScreen> with SingleTickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Functions function = Functions();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late final controller = SlidableController(this);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Chats', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.teal,
        elevation: 4,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () {
              showLogoutDialog(context);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.teal.withOpacity(0.1),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.archive, color: Colors.teal),
                const SizedBox(width: 16),
                const Text('Archived', style: TextStyle(fontWeight: FontWeight.w500)),
                const Spacer(),
                Text('2', style: TextStyle(color: Colors.teal.shade700)),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _buildUsersList(),
          ),
        ],
      ),
    );

  }

  Future<void> showLogoutDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: const Text(
            'Log Out',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.teal,
            ),
          ),
          content: const Text(
            'Are you sure you want to log out?',
            style: TextStyle(fontSize: 16),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.grey),
              ),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
            TextButton(
              child: const Text(
                'Log Out',
                style: TextStyle(color: Colors.red),
              ),
              onPressed: () => function.signOut(context),
            ),
          ],
        );
      },
    );
  }

  Widget _buildUsersList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('user').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Error loading chats'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final currentUserId = _auth.currentUser!.uid;
        final users = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return currentUserId != data['uid'];
        }).toList();

        if (users.isEmpty) {
          return const Center(child: Text('No users available'));
        }

        return ListView.separated(
          padding: const EdgeInsets.only(top: 8),
          itemCount: users.length,
          separatorBuilder: (context, index) => const Divider(height: 1, indent: 72),
          itemBuilder: (context, index) {
            final doc = users[index];
            return _buildUserListItem(doc);
          },
        );
      },
    );
  }

  Widget _buildUserListItem(DocumentSnapshot userDoc) {
    final userData = userDoc.data()! as Map<String, dynamic>;
    final currentUserId = _auth.currentUser!.uid;
    final chatPartnerId = userData['uid'];

    // Determine the chat room ID (sorted to ensure consistency)
    final chatRoomId = currentUserId.compareTo(chatPartnerId) < 0
        ? '$currentUserId-$chatPartnerId'
        : '$chatPartnerId-$currentUserId';

    print('Checking chat room: $chatRoomId'); // Debug print

    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('chat_rooms')
          .doc(chatRoomId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .snapshots(),
      builder: (context, messageSnapshot) {
        // Debug prints
        print('Message snapshot state: ${messageSnapshot.connectionState}');
        if (messageSnapshot.hasError) {
          print('Error in message stream: ${messageSnapshot.error}');
        }

        String lastMessage = '';
        String lastMessageTime = '';
        bool isCurrentUserSender = false;

        if (messageSnapshot.hasData && messageSnapshot.data!.docs.isNotEmpty) {
          final lastMsg = messageSnapshot.data!.docs.first;
          print('Found last message: ${lastMsg.data()}'); // Debug print

          // Try both 'content' and 'message' fields
          lastMessage =  lastMsg['message'] ?? '';
          isCurrentUserSender = lastMsg['senderId'] == currentUserId;

          final timestamp = lastMsg['timestamp'] as Timestamp?;
          if (timestamp != null) {
            lastMessageTime = _formatMessageTime(timestamp.toDate());
          }
        } else {
          print('No messages found in chat room $chatRoomId'); // Debug print
        }

        return Slidable(
          key: const ValueKey(0),
          endActionPane: ActionPane(
            motion: const ScrollMotion(),
            children: [
              SlidableAction(
                flex: 1,
                onPressed: (_) => controller.openEndActionPane(),
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                icon: Icons.archive,
                label: 'Archive',
              ),
            ],
          ),

          child: ListTile(
            leading: CircleAvatar(
              radius: 24,
              backgroundColor: Colors.teal.shade100,
              child: const Icon(Icons.person, color: Colors.teal),
            ),
            title: Text(
              userData['username'] ?? 'Unknown',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: Text(
              lastMessage.isEmpty
                  ? 'Start a conversation....'
                  : (isCurrentUserSender ? 'You: $lastMessage' : lastMessage),
              style: TextStyle(
                color: Colors.grey,
                fontStyle: lastMessage.isEmpty ? FontStyle.italic : FontStyle.normal,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            trailing: lastMessage.isEmpty
                ? null
                : Text(
              lastMessageTime,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatPage(
                  userEmail: userData['username'],
                  userId: userData['uid'],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatMessageTime(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final messageDate = DateTime(time.year, time.month, time.day);

    if (messageDate == today) {
      return DateFormat('h:mm a').format(time);
    } else if (messageDate == yesterday) {
      return 'Yesterday';
    } else {
      return DateFormat('MMM d').format(time);
    }
  }
}