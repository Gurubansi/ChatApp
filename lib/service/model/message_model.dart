import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String senderId;
  final String userName;
  final String senderEmail;
  final String receiverId;
  final String message;
  final Timestamp timestamp;

  MessageModel(this.senderId, this.senderEmail, this.receiverId, this.message,
      this.timestamp,this.userName);

  // convert to a map
  Map<String, dynamic> toMap() {
    return {
      "senderId": senderId,
      "username": userName,
      "senderEmail": senderEmail,
      "receiverId": receiverId,
      "message": message,
      "timestamp": timestamp,
    };
  }
}
