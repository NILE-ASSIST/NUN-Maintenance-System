import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nileassist/main.dart';
import 'package:nileassist/screens/chat_detail.dart';

class ChatScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const ChatScreen({super.key, required this.userData});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // stream to get the tickets based on the user's role
  Stream<QuerySnapshot> _getUserTicketsStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Stream.empty();

    final String role = widget.userData['role'] ?? '';

    //maintenance staff: queries by assignedStaffId
    if (role == 'maintenance' || role == 'maintenance_staff') {
      return _firestore
          .collection('tickets')
          .where('assignedStaffId', isEqualTo: user.uid)
          .snapshots();
    }
    // maintenance supervisor: queries by assignedTo (their supervisor ID)
    else if (role == 'maintenance_supervisor') {
      return _firestore
          .collection('tickets')
          .where('assignedTo', isEqualTo: user.uid)
          .snapshots();
    }
    // 3. Issuer (Lecturers/Hostel Supervisors/Students): Queries by issuerID
    else {
      return _firestore
          .collection('tickets')
          .where('issuerID', isEqualTo: user.uid)
          .snapshots();
    }
  }

  Future<String?> _fetchTargetProfilePicture(
    String targetId,
    bool isStaff,
  ) async {
    if (targetId.isEmpty) return null;

    try {
      if (!isStaff) {
        // if user is a Lecturer OR Supervisor -> we fetch the Staff's profile picture
        final doc = await _firestore
            .collection('maintenance')
            .doc(targetId)
            .get();
        if (doc.exists) {
          return doc.data()?['profilePicture'];
        }
      } else {
        // if user is staff fetch the Issuer's profile picture
        final collections = [
          'lecturers',
          'hostel_supervisors',
          'maintenance_supervisors',
        ];
        for (final col in collections) {
          final doc = await _firestore.collection(col).doc(targetId).get();
          if (doc.exists && doc.data()!.containsKey('profilePicture')) {
            return doc.data()?['profilePicture'];
          }
        }
      }
    } catch (e) {
      print("Error fetching profile picture: $e");
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    // determine the user's role to format the UI properly
    final String role = widget.userData['role'] ?? '';

    return Scaffold(
      backgroundColor: MyApp.nileBlue,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 20, 24, 30),
              child: Text(
                "Chats",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(40),
                    topRight: Radius.circular(40),
                  ),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 30),

                    // Search bar
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Container(
                        height: 45,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const TextField(
                          decoration: InputDecoration(
                            hintText: "Search by id or category",
                            hintStyle: TextStyle(color: Colors.grey),
                            prefixIcon: Icon(Icons.search, color: Colors.grey),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // dynamic chats list
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: _getUserTicketsStream(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          if (snapshot.hasError) {
                            return Center(
                              child: Text(
                                "FIREBASE ERROR: ${snapshot.error}",
                                style: const TextStyle(color: Colors.red),
                              ),
                            );
                          }
                          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                            return _buildEmptyState();
                          }

                          final assignedTickets = snapshot.data!.docs.where((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            final status = data['status'] ?? 'Pending';
                            final hasStaff = data['assignedStaffId'] != null;
                            final isActive = status != 'Resolved' && status != 'Completed';
                            
                            return hasStaff && isActive;
                          }).toList();

                          if (assignedTickets.isEmpty) {
                            return _buildEmptyState();
                          }

                          // Routes tickets into separate chat rooms
                          final List<Map<String, dynamic>> chatRooms = [];
                          final currentUserId = FirebaseAuth.instance.currentUser?.uid;

                          for (var doc in assignedTickets) {
                            final data = doc.data() as Map<String, dynamic>;
                            final ticketId = doc.id;
                            final location = data['location'] ?? 'Unknown Location';
                            final shortId = ticketId.length > 6 
                                ? ticketId.substring(0, 6).toUpperCase() 
                                : ticketId.toUpperCase();

                            if (role == 'maintenance' || role == 'maintenance_staff') {
                              // maintenance staff to lecturer chat (Public)
                              chatRooms.add({
                                'ticketId': ticketId,
                                'targetId': data['issuerID'] ?? '',
                                'displayName': data['issuerName'] ?? data['issuerEmail'] ?? 'User',
                                'subtitle': "Ticket #$shortId • $location",
                                'subcollection': 'messages',
                                'isStaff': true,
                                'hasUnread': data['unreadBy'] == currentUserId,
                              });

                              // maintenance staff to supervisor staff (Internal)
                              chatRooms.add({
                                'ticketId': ticketId,
                                'targetId': data['assignedTo'] ?? '',
                                'displayName': "Supervisor",
                                'subtitle': "Internal: Ticket #$shortId • $location",
                                'subcollection': 'supervisor_messages', // Uses the private folder
                                'isStaff': true,
                                'hasUnread': data['unreadBy_internal'] == currentUserId,
                              });
                            } else if (role == 'maintenance_supervisor') {
                              // maintenance supervisor to staff chat (Internal)
                              chatRooms.add({
                                'ticketId': ticketId,
                                'targetId': data['assignedStaffId'] ?? '',
                                'displayName': data['assignedStaffName'] ?? 'Assigned Staff',
                                'subtitle': "Internal: Ticket #$shortId • $location",
                                'subcollection': 'supervisor_messages',
                                'isStaff': false,
                                'hasUnread': data['unreadBy_internal'] == currentUserId,
                              });
                            } else {
                              // lecturer to maintenance staff Chat (Public)
                              chatRooms.add({
                                'ticketId': ticketId,
                                'targetId': data['assignedStaffId'] ?? '',
                                'displayName': data['assignedStaffName'] ?? 'Assigned Staff',
                                'subtitle': "Ticket #$shortId • $location",
                                'subcollection': 'messages',
                                'isStaff': false,
                                'hasUnread': data['unreadBy'] == currentUserId,
                              });
                            }
                          }

                          return ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            itemCount: chatRooms.length,
                            itemBuilder: (context, index) {
                              final chat = chatRooms[index];

                              return FutureBuilder<String?>(
                                future: _fetchTargetProfilePicture(chat['targetId'], chat['isStaff']),
                                builder: (context, picSnapshot) {
                                  return _buildChatItem(
                                    name: chat['displayName'],
                                    message: chat['subtitle'],
                                    profilePicture: picSnapshot.data,
                                    hasUnread: chat['hasUnread'],
                                    onTap: () {
                                      // clears the correct unread dot
                                      if (chat['hasUnread']) {
                                        _firestore.collection('tickets').doc(chat['ticketId']).update({
                                          chat['subcollection'] == 'messages' ? 'unreadBy' : 'unreadBy_internal': null,
                                        });
                                      }

                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ChatDetail(
                                            ticketId: chat['ticketId'],
                                            targetName: chat['displayName'],
                                            targetId: chat['targetId'],
                                            targetProfilePicture: picSnapshot.data,
                                            currentUserData: widget.userData,
                                            chatCollection: chat['subcollection'], // passes the folder name
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                              );
                            },
                          );
                        }, 
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 60,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            "No Active Chats",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Chats will appear here once a maintenance staff has been assigned to a ticket.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildChatItem({
    required String name,
    required String message,
    required VoidCallback onTap,
    String? profilePicture,
    bool hasUnread = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.grey.shade500,
                      backgroundImage: profilePicture != null && profilePicture.isNotEmpty
                          ? NetworkImage(profilePicture)
                          : null,
                      child: profilePicture == null || profilePicture.isEmpty
                          ? const Icon(
                              Icons.person,
                              size: 24,
                              color: Colors.white,
                            )
                          : null,
                    ),
                    if (hasUnread)
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: MyApp.nileGreen,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 0.5,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        message,
                        style: TextStyle(
                          color: hasUnread ? Colors.black87 : Colors.grey.shade600,
                          fontSize: 13,
                          fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            thickness: 1,
            indent: 64,
            color: Colors.grey.shade300,
          ),
        ],
      ),
    );
  }
}