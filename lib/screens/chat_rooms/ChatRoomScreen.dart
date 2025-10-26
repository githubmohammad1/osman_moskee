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
  String? userRole;

  @override
  void initState() {
    super.initState();
    _fetchUserRole();
  }

  Future<void> _fetchUserRole() async {
    if (user == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .get();
    setState(() {
      userRole = doc.data()?['role'];
    });
  }

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
      'isRead': false,
    });

    _messageController.clear();
    _updateTyping(false);
  }

  void _updateTyping(bool isTyping) {
    if (user != null) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .update({'isTyping': isTyping});
    }
  }

  Future<void> _deleteMessage(DocumentSnapshot doc) async {
    await doc.reference.delete();
  }

  Future<void> _editMessage(DocumentSnapshot doc) async {
    final TextEditingController editController =
        TextEditingController(text: (doc.data() as Map)['text']);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تعديل الرسالة'),
        content: TextField(controller: editController),
        actions: [
          TextButton(
            child: const Text('إلغاء'),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            child: const Text('حفظ'),
            onPressed: () async {
              final newText = editController.text.trim();
              if (newText.isNotEmpty) {
                await doc.reference.update({'text': newText});
              }
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Stream<QuerySnapshot> _messageStream() {
    return FirebaseFirestore.instance
        .collection('chatRooms')
        .doc(widget.roomId)
        .collection('messages')
        .orderBy('timestamp')
        .snapshots();
  }

  Widget _buildMessageItem(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final isMe = data['senderId'] == user?.uid;
    final canEditOrDelete = isMe || (userRole == 'teacher' || userRole == 'admin');

    if (!isMe && !(data['isRead'] ?? false)) {
      doc.reference.update({'isRead': true});
    }

    final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
    final timeString = timestamp != null
        ? '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}'
        : '';

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(data['senderId'])
          .get(),
      builder: (context, snapshot) {
        final userData = snapshot.data?.data() as Map<String, dynamic>?;
        final firstName = userData?['firstName'] ?? '';
        // print( firstName);
        final lastName = userData?['lastName'] ?? '';
        final username = '$firstName $lastName'.trim().isEmpty ? 'مستخدم' : '$firstName $lastName';

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
                Text('$timeString - ${data['text'] ?? ''}'),
                if (canEditOrDelete)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, size: 18),
                        onPressed: () => _editMessage(doc),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, size: 18),
                        onPressed: () => _deleteMessage(doc),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTypingIndicator() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('isTyping', isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        final typingUsers = snapshot.data?.docs ?? [];
        if (typingUsers.isEmpty) return const SizedBox();
        return Padding(
          padding: const EdgeInsets.all(8),
          child: Text('يكتب الآن...', style: TextStyle(color: Colors.grey[600])),
        );
      },
    );
  }

  @override
  void dispose() {
    _updateTyping(false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('غرفة المحادثة')),
      body: Column(
        children: [
          _buildTypingIndicator(),
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
                    onChanged: (text) => _updateTyping(text.isNotEmpty),
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
