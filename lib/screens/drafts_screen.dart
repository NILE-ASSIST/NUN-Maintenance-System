import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:nileassist/main.dart'; // To access MyApp.nileBlue
import 'package:nileassist/screens/complaint_form.dart';

class DraftsScreen extends StatefulWidget {
  const DraftsScreen({super.key});

  @override
  State<DraftsScreen> createState() => _DraftsScreenState();
}

class _DraftsScreenState extends State<DraftsScreen> {
  // Brand colors matched to Figma
  static const Color nileBlue = Color.fromARGB(255, 2, 64, 177);
  static const Color cardGray = Color(0xFFF6F6F6);
  static const Color textGray = Color(0xFF737373);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('User not logged in.')),
      );
    }

    return Scaffold(
      backgroundColor: nileBlue,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Custom Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(
                      Icons.arrow_back_ios_new,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 15),
                  const Text(
                    'Drafts',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),

            // Main Content Area (Rounded Container)
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: cardGray,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(50),
                    topRight: Radius.circular(50),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 35),
                      // List View using Firestore Data
                      Expanded(
                        child: StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('drafts')
                              .where('issuerID', isEqualTo: user.uid)
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            }

                            if (snapshot.hasError) {
                              return Center(child: Text("Error fetching drafts: ${snapshot.error}"));
                            }

                            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                              return const Center(child: Text("You have no saved drafts."));
                            }

                            final docs = snapshot.data!.docs.toList();
                            docs.sort((a, b) {
                              final dA = a.data() as Map<String, dynamic>;
                              final dB = b.data() as Map<String, dynamic>;
                              Timestamp? tA = dA['lastEdited'];
                              Timestamp? tB = dB['lastEdited'];
                              if (tA == null) return 1;
                              if (tB == null) return -1;
                              return tB.compareTo(tA);
                            });

                            return ListView.builder(
                              physics: const BouncingScrollPhysics(),
                              itemCount: docs.length,
                              itemBuilder: (context, index) {
                                final doc = docs[index];
                                final data = doc.data() as Map<String, dynamic>;
                                return _buildDraftCard(context, doc.id, data);
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDraftCard(BuildContext context, String docId, Map<String, dynamic> data) {
    // Parsing Data
    String description = data['description']?.toString().trim() ?? '';
    if (description.isEmpty) description = 'Untitled Draft';
    
    final String category = data['category'] ?? 'Category missing';
    
    // Formatting Dates
    final Timestamp? lastEditedTs = data['lastEdited'];
    final String dateStr = lastEditedTs != null 
        ? DateFormat('MMM d, yyyy, h:mm a').format(lastEditedTs.toDate()) 
        : 'Just now';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Title
          Text(
            description,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 6),

          // Row 2: Category
          Text(
            category,
            style: const TextStyle(
              color: textGray,
              fontSize: 14,
            ),
          ),
          
          const SizedBox(height: 12),

          // Row 3: Date
          Text(
            'Last edited: $dateStr',
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),

          const SizedBox(height: 16),
          // Divider
          Container(
            height: 1,
            width: double.infinity,
            color: Colors.grey.shade200,
          ),
          const SizedBox(height: 12),

          // Row 4: Action Buttons (Continue Editing & Delete)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Continue Editing Button
              InkWell(
                onTap: () {
                  // Navigate to ComplaintForm with draft info
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ComplaintFormPage(
                        draftId: docId,
                        draftData: data,
                      ),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 2.0),
                  child: Row(
                    children: const [
                      Icon(Icons.edit_outlined, color: nileBlue, size: 16),
                      SizedBox(width: 6),
                      Text(
                        'Continue Editing',
                        style: TextStyle(
                          color: nileBlue,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Delete Button
              IconButton(
                onPressed: () => _showDeleteConfirmation(context, docId),
                icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, String docId) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text('Delete Draft?'),
          content: const Text('Are you sure you want to delete this draft? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                FirebaseFirestore.instance.collection('drafts').doc(docId).delete();
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Draft deleted.'), backgroundColor: Colors.orange),
                );
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}
