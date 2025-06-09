import 'package:chat_app/Providers/chat_service.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/foundation.dart' as foundation;
import 'package:shared_preferences/shared_preferences.dart';

class ChatPage extends StatefulWidget {
  final String userEmail;
  final String userId;

  const ChatPage({super.key, required this.userEmail, required this.userId});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final chatService _chatService = chatService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  bool _showEmojiPicker = false;

  @override
  void initState() {
    super.initState();
    _scrollToBottom();
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
          _showEmojiPicker = false;
        _scrollToBottom();
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void sendMessage() async {
    final currentUser = await _chatService.getCurrentUserDetails();
    if (_messageController.text.trim().isNotEmpty) {
      await _chatService.sendMessage(
          widget.userId, _messageController.text.trim(), currentUser?['username'] ?? '');
      _messageController.clear();
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _toggleEmojiPicker() {
    setState(() {
      _showEmojiPicker = !_showEmojiPicker;
      if (_showEmojiPicker) {
        _focusNode.unfocus();
      } else {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.teal.shade100,
              child: const Icon(Icons.person, color: Colors.teal),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.userEmail,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: _buildMessageList()),
          _buildMessageInputField(),
          if (_showEmojiPicker) _buildEmojiPicker(),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    return StreamBuilder(
      stream: _chatService.getMessages(widget.userId, _auth.currentUser!.uid),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final messages = snapshot.data!.docs;

        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final currentMsg = messages[index];
            final currentDate = (currentMsg['timestamp'] as Timestamp).toDate();
            final showDateHeader = index == 0 ||
                !_isSameDay(
                  currentDate,
                  (messages[index - 1]['timestamp'] as Timestamp).toDate(),
                );

            return Column(
              children: [
                if (showDateHeader)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      _formatMessageDate(currentDate),
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                _buildMessageItem(currentMsg),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildMessageItem(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final isSender = data['senderId'] == _auth.currentUser!.uid;
    final timestamp = data['timestamp'] as Timestamp;
    final dateTime = timestamp.toDate();
    final formattedTime = DateFormat('h:mm a').format(dateTime);

    return Align(
      alignment: isSender ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isSender ? Colors.teal.shade100 : Colors.grey.shade200,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(12),
            topRight: const Radius.circular(12),
            bottomLeft: Radius.circular(isSender ? 12 : 0),
            bottomRight: Radius.circular(isSender ? 0 : 12),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment:
          isSender ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isSender)
              Text(
                data['username'] ?? 'Unknown',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.teal.shade800,
                  fontSize: 12,
                ),
              ),
            Text(
              data['message'],
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  formattedTime,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade600,
                  ),
                ),
                if (isSender)
                  const SizedBox(width: 4),
                if (isSender)
                  Icon(
                    Icons.done_all,
                    size: 14,
                    color: data['read'] == true ? Colors.blue : Colors.grey,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInputField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              _showEmojiPicker ? Icons.keyboard : Icons.emoji_emotions_outlined,
              color: Colors.grey.shade600,
            ),
            onPressed: _toggleEmojiPicker,
          ),
          Expanded(
            child: TextField(
              controller: _messageController,
              focusNode: _focusNode,
              decoration: InputDecoration(
                hintText: "Type a message...",
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (value) => sendMessage(),
            ),
          ),
          IconButton(
            icon: Icon(Icons.attach_file, color: Colors.grey.shade600),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.camera_alt, color: Colors.grey.shade600),
            onPressed: () {},
          ),
          const SizedBox(width: 4),
          CircleAvatar(
            backgroundColor: Colors.teal,
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: sendMessage,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmojiPicker() {
    return FutureBuilder<SharedPreferences>(
      future: SharedPreferences.getInstance(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 250,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return SizedBox(
            height: 250,
            child: Center(child: Text('Error loading emoji picker: ${snapshot.error}')),
          );
        }
        return SizedBox(
          height: 250,
          child: EmojiPicker(
            onEmojiSelected: (category, emoji) {
              _messageController.text = _messageController.text + emoji.emoji;
            },
            onBackspacePressed: () {
              if (_messageController.text.isNotEmpty) {
                _messageController.text = _messageController.text.substring(
                    0, _messageController.text.length - 1);
              }
            },
            config: Config(
              height: MediaQuery.sizeOf(context).height * 0.4,
              checkPlatformCompatibility: true,
              emojiViewConfig: EmojiViewConfig(
                emojiSizeMax: 28 *
                    (foundation.defaultTargetPlatform == TargetPlatform.iOS
                        ? 1.20
                        : 1.0),
              ),
              skinToneConfig: const SkinToneConfig(),
              categoryViewConfig: const CategoryViewConfig(),
              bottomActionBarConfig: const BottomActionBarConfig(),
              searchViewConfig: const SearchViewConfig(),
            ),
          ),
        );
      },
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _formatMessageDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate == today) {
      return 'Today';
    } else if (messageDate == yesterday) {
      return 'Yesterday';
    } else {
      return DateFormat('MMMM d, y').format(date);
    }
  }

}