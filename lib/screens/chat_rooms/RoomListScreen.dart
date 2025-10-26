import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'ChatRoomScreen.dart';

class RoomListScreen extends StatelessWidget {
  const RoomListScreen({super.key});

  Stream<QuerySnapshot> _roomStream() {
    return FirebaseFirestore.instance
        .collection('chatRooms')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> _createRoom(String name) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance.collection('chatRooms').add({
      'name': name,
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': user.uid,
    });
  }

  void _showCreateRoomDialog(BuildContext context) {
    final TextEditingController _roomNameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إنشاء غرفة جديدة'),
        content: TextField(
          controller: _roomNameController,
          decoration: const InputDecoration(hintText: 'اسم الغرفة'),
        ),
        actions: [
          TextButton(
            child: const Text('إلغاء'),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            child: const Text('إنشاء'),
            onPressed: () async {
              final name = _roomNameController.text.trim();
              if (name.isNotEmpty) {
                await _createRoom(name);
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('اختر غرفة المحادثة'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'إنشاء غرفة جديدة',
            onPressed: () => _showCreateRoomDialog(context),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _roomStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final rooms = snapshot.data?.docs ?? [];

          if (rooms.isEmpty) {
            return const Center(child: Text('لا توجد غرف بعد.'));
          }

          return ListView.builder(
            itemCount: rooms.length,
            itemBuilder: (context, index) {
              final room = rooms[index];
              final data = room.data() as Map<String, dynamic>;
              final roomName = data['name'] ?? 'غرفة بدون اسم';

              return ListTile(
                title: Text(roomName),
                subtitle: Text('Room ID: ${room.id}'),
                trailing: const Icon(Icons.chat),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatRoomScreen(roomId: room.id),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
