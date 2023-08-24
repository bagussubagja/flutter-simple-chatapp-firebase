import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_app_firebase/services/chat/chat_service.dart';
import 'package:intl/intl.dart';

class ChatPage extends StatefulWidget {
  final String receiveruserEmail;
  final String receiverUserId;
  const ChatPage(
      {super.key,
      required this.receiverUserId,
      required this.receiveruserEmail});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _messageController = TextEditingController();
  final ChatService _chatService = ChatService();
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  void sendMessage() async {
    if (_messageController.text.isNotEmpty) {
      await _chatService.sendMessage(
          widget.receiverUserId, _messageController.text);
      _messageController.clear();
    }
  }

  String getEmailUsername(String email) {
    List<String> parts = email.split("@");
    if (parts.length > 1) {
      return parts[0];
    } else {
      return email;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(getEmailUsername(widget.receiveruserEmail)),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Expanded(
              child: _buildMessageList(),
            ),
            _buildMessageInput()
          ],
        ),
      ),
    );
  }

  Widget _buildMessageList() {
    return StreamBuilder(
      stream: _chatService.getMessages(
          widget.receiverUserId, _firebaseAuth.currentUser!.uid),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Text('Error');
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        return ListView(
            children: snapshot.data!.docs
                .map(
                  (document) => _buildMessageItem(document),
                )
                .toList());
      },
    );
  }

  Widget _buildMessageItem(DocumentSnapshot document) {
    Map<String, dynamic> data = document.data() as Map<String, dynamic>;
    var alignment = (data['senderId'] == _firebaseAuth.currentUser!.uid)
        ? Alignment.centerRight
        : Alignment.centerLeft;
    final dateTime = DateTime.fromMillisecondsSinceEpoch(
        data['timestamp'].seconds * 1000 +
            data['timestamp'].nanoseconds ~/ 1000000);
    final formattedDateTime = DateFormat('HH:mm').format(dateTime);
    return Container(
      alignment: alignment,
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: (data['senderId'] == _firebaseAuth.currentUser!.uid)
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            width: (data['senderId'] == _firebaseAuth.currentUser!.uid)
                ? MediaQuery.of(context).size.width * 0.4
                : MediaQuery.of(context).size.width * 0.5,
            decoration: BoxDecoration(
                color: Colors.purple[50],
                borderRadius: BorderRadius.circular(12)),
            child: Text(
              data['message'],
            ),
          ),
          Text(formattedDateTime)
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Row(
      children: [
        Expanded(
            child: TextFormField(
          controller: _messageController,
          obscureText: false,
          decoration: const InputDecoration(
            hintText: "Enter Message",
          ),
        )),
        IconButton(onPressed: sendMessage, icon: const Icon(Icons.arrow_upward))
      ],
    );
  }
}
