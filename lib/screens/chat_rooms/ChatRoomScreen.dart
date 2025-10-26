import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ChatRoomScreen extends StatefulWidget {
  final String roomId;
  const ChatRoomScreen({super.key, required this.roomId});

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final TextEditingController _messageController = TextEditingController();
  final user = FirebaseAuth.instance.currentUser;

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || user == null) return;

    await FirebaseFirestore.instance
        .collection('chatRooms')
        .doc(widget.roomId)
        .collection('messages')
        .add({
      'text': text,
      'senderId': user!.uid,
      'timestamp': FieldValue.serverTimestamp(),
    });

    _messageController.clear();
  }

  Stream<QuerySnapshot> _messageStream() {
    return FirebaseFirestore.instance
        .collection('chatRooms')
        .doc(widget.roomId)
        .collection('messages')
        .orderBy('timestamp')
        .snapshots();
  }

  Widget _buildRoomStats() {
    return StreamBuilder<QuerySnapshot>(
      stream: _messageStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();

        final messages = snapshot.data!.docs;
        final uniqueSenders = messages
            .map((doc) => (doc.data() as Map)['senderId'])
            .toSet()
            .length;

        return Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('عدد الرسائل: ${messages.length}'),
              Text('عدد المشاركين: $uniqueSenders'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMessageItem(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final isMe = data['senderId'] == user?.uid;

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(data['senderId'])
          .get(),
      builder: (context, snapshot) {
        final userData = snapshot.data?.data() as Map<String, dynamic>?;
        final firstName = userData?['firstName'] ?? '';
        final lastName = userData?['lastName'] ?? '';
        final rawName = '$firstName $lastName'.trim();
        final username = rawName.isEmpty ? 'مستخدم' : rawName;

        return Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isMe ? Colors.blue[100] : Colors.grey[300],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Text(username,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 4),
                Text(data['text'] ?? ''),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('غرفة المحادثة')),
      body: Column(
        children: [
          _buildRoomStats(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _messageStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data?.docs ?? [];
                return ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: docs.length,
                  itemBuilder: (context, index) =>
                      _buildMessageItem(docs[index]),
                );
              },
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration:
                        const InputDecoration(hintText: 'اكتب رسالتك...'),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
