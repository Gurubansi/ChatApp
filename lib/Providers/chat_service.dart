import 'package:chat_app/service/model/message_model.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class chatService extends ChangeNotifier {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// send message
  Future<void> sendMessage(String receiverId, String message) async {
    /// get current user info
    final currentUserId = _firebaseAuth.currentUser!.uid;
    final currentUserEmail = _firebaseAuth.currentUser!.email.toString();
    final Timestamp timestamp = Timestamp.now();

    /// create a new message
    MessageModel msg = MessageModel(
        currentUserId, currentUserEmail, receiverId, message, timestamp);

    /// construct chat room id for current user id and receiver id
    List<String> ids = [receiverId, currentUserId];
    ids.sort(); // sort the ids ( this ensures the chat room id is always same for any pair of people )
    String chatRoomId = ids.join(
        "_"); // combine both ids into single String to use as a chatroom id

    /// add new message to database
    await _firestore
        .collection('chat_room')
        .doc(chatRoomId)
        .collection('messages')
        .add(msg.toMap());
  }

  /// GET messages
  Stream<QuerySnapshot> getMessages(String userID, String otherUserId) {
    /// construct chat room id from user ids (sorted to ensure it matches the id used when sending  message
    List<String> ids = [userID, otherUserId];
    ids.sort();
    String chatroomId = ids.join('_');

    return _firestore
        .collection('chat_room')
        .doc(chatroomId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }
}
