import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'ChatRoomScreen.dart';

class RoomListScreen extends StatefulWidget {
  const RoomListScreen({super.key});

  @override
  State<RoomListScreen> createState() => _RoomListScreenState();
}

class _RoomListScreenState extends State<RoomListScreen> {
  String? userRole;

  @override
  void initState() {
    super.initState();
    _fetchUserRole();
  }

  Future<void> _fetchUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    setState(() {
      userRole = doc.data()?['role'];
    });
  }

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

  Future<void> _deleteRoom(String roomId) async {
    await FirebaseFirestore.instance
        .collection('chatRooms')
        .doc(roomId)
        .delete();
  }

  void _showEditRoomDialog(BuildContext context, String roomId, String currentName) {
    final TextEditingController _roomNameController =
        TextEditingController(text: currentName);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تعديل اسم الغرفة'),
        content: TextField(
          controller: _roomNameController,
          decoration: const InputDecoration(hintText: 'اسم جديد'),
        ),
        actions: [
          TextButton(
            child: const Text('إلغاء'),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            child: const Text('حفظ'),
            onPressed: () async {
              final newName = _roomNameController.text.trim();
              if (newName.isNotEmpty) {
                await FirebaseFirestore.instance
                    .collection('chatRooms')
                    .doc(roomId)
                    .update({'name': newName});
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
    );
  }

  bool get isPrivileged => userRole == 'teacher' || userRole == 'admin';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('غرف المحادثة'),
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
            padding: const EdgeInsets.all(12),
            itemCount: rooms.length,
            itemBuilder: (context, index) {
              final room = rooms[index];
              final data = room.data() as Map<String, dynamic>;
              final roomName = data['name'] ?? 'غرفة بدون اسم';

              return Card(
                elevation: 3,
                margin: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  title: Text(
                    roomName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    'Room ID: ${room.id}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  leading: const Icon(Icons.meeting_room, color: Colors.blue),
                  trailing: isPrivileged
                      ? PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert),
                          onSelected: (value) {
                            if (value == 'edit') {
                              _showEditRoomDialog(context, room.id, roomName);
                            } else if (value == 'delete') {
                              _deleteRoom(room.id);
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Text('تعديل'),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text('حذف'),
                            ),
                          ],
                        )
                      : const Icon(Icons.chat, color: Colors.grey),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatRoomScreen(roomId: room.id),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
