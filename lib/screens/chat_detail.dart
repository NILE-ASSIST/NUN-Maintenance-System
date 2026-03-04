import 'package:flutter/material.dart';
import 'package:nileassist/main.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatDetail extends StatefulWidget {
  final String ticketId;
  final String targetName;
  final String targetId;
  final String? targetProfilePicture;
  final Map<String, dynamic> currentUserData;
  final String chatCollection;

  const ChatDetail({
    super.key,
    required this.ticketId,
    required this.targetName,
    required this.targetId,
    this.targetProfilePicture,
    required this.currentUserData,
    required this.chatCollection,
  });

  @override
  State<ChatDetail> createState() => _ChatDetailState();
}

class _ChatDetailState extends State<ChatDetail> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  //sends the message to Firestore
  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    //clear the input field immediately for a snappy user experience
    _messageController.clear();

    //adds the message to the ticket's 'messages' subcollection
    await _firestore
        .collection('tickets')
        .doc(widget.ticketId)
        .collection(widget.chatCollection)
        .add({
          'text': text,
          'senderId': currentUser.uid,
          'timestamp': FieldValue.serverTimestamp(),
        });
        await _firestore.collection('tickets').doc(widget.ticketId).update({
      widget.chatCollection == 'messages' ? 'unreadBy' : 'unreadBy_internal': widget.targetId,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 1,
        shadowColor: Colors.black12,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: widget.targetProfilePicture != null
                  ? NetworkImage(widget.targetProfilePicture!)
                  : null,
              child: widget.targetProfilePicture == null
                  ? Icon(Icons.person)
                  : null,
            ),
            const SizedBox(width: 25),
            Text(
              widget.targetName,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        backgroundColor: MyApp.nileBlue,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('tickets')
                  .doc(widget.ticketId)
                  .collection(widget.chatCollection)
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text("No messages yet. Start the conversation!"),
                  );
                }

                final messages = snapshot.data!.docs;

                return ListView.builder(
                  reverse:
                      true, // Pushes messages to the bottom and scrolls up naturally
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 20,
                  ),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final data = messages[index].data() as Map<String, dynamic>;
                    final isMe = data['senderId'] == _auth.currentUser?.uid;

                    // Handle timestamp conversion
                    final Timestamp? timestamp = data['timestamp'];
                    final String timeString = timestamp != null
                        ? DateFormat('h:mm a').format(timestamp.toDate())
                        : 'Sending...';

                    return _buildMessageBubble(
                      text: data['text'] ?? '',
                      time: timeString,
                      isMe: isMe,
                    );
                  },
                );
              },
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble({
    required String text,
    required String time,
    required bool isMe,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isMe ? MyApp.nileGreen : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                text,
                style: TextStyle(color: isMe ? Colors.white : Colors.black),
              ),
              const SizedBox(height: 4),
              Text(
                time,
                style: TextStyle(
                  fontSize: 10,
                  color: isMe ? Colors.white70 : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.send, color: MyApp.nileBlue),
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }
}
