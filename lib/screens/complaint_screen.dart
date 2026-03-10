import 'package:flutter/material.dart';
import 'package:nileassist/main.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nileassist/screens/complaintDetail.dart';
import 'package:intl/intl.dart';
import 'package:nileassist/widgets/reusable_searchbar.dart';

class ComplaintScreen extends StatefulWidget {
  const ComplaintScreen({super.key});

  @override
  State<ComplaintScreen> createState() => _ComplaintScreenState();
}

class _ComplaintScreenState extends State<ComplaintScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  String _searchQuery = '';
  late Stream<QuerySnapshot> _complaintsStream;

  @override
  void initState() {
    super.initState();
    _complaintsStream = _getAllComplaintsStream();
  }

  Stream<QuerySnapshot> _getAllComplaintsStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Stream.empty();

    return _firestore
        .collection('tickets')
        .where('issuerID', isEqualTo: user.uid)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyApp.nileBlue,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'All Complaints',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Overview of all current tickets',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

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
                    const SizedBox(height: 20),
                    
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: ReusableSearchBar(
                        hintText: "Search by id or category",
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                      ),
                    ),
                    
                    const SizedBox(height: 20),

                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: _complaintsStream,
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return Center(child: Text('Something went wrong: ${snapshot.error}'));
                          }
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }

                          final allDocs = snapshot.data?.docs ?? [];
                          
                          // Filtering logic
                          final query = _searchQuery.toLowerCase().trim();
                          
                          final filteredDocs = allDocs.where((doc) {
                            if (query.isEmpty) return true;
                            
                            final data = doc.data() as Map<String, dynamic>;
                            final String fullId = doc.id.toLowerCase();
                            final String shortId = fullId.length > 6 ? fullId.substring(0, 6) : fullId;
                            final String category = (data['category'] ?? '').toString().toLowerCase();

                            return shortId.contains(query) || category.contains(query);
                          }).toList();

                          // Sort: Newest first
                          filteredDocs.sort((a, b) {
                            final tA = (a.data() as Map<String, dynamic>)['dateCreated'] as Timestamp?;
                            final tB = (b.data() as Map<String, dynamic>)['dateCreated'] as Timestamp?;
                            if (tA == null) return 1;
                            if (tB == null) return -1;
                            return tB.compareTo(tA);
                          });

                          if (filteredDocs.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.folder_open_outlined, size: 60, color: Colors.grey.shade300),
                                  const SizedBox(height: 16),
                                  Text(
                                    _searchQuery.isEmpty 
                                      ? 'No ticket history found.' 
                                      : 'No tickets match "$_searchQuery".',
                                    style: const TextStyle(color: Colors.grey)
                                  ),
                                ],
                              ),
                            );
                          }

                          return ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: filteredDocs.length,
                            itemBuilder: (context, index) {
                              final doc = filteredDocs[index];
                              final data = doc.data() as Map<String, dynamic>;
                              final status = data['status'] ?? 'Pending';
                              final timestamp = data['dateCreated'] as Timestamp?;
                              final date = timestamp != null
                                  ? DateFormat('MMM d, yyyy').format(timestamp.toDate())
                                  : 'Unknown';

                              Color statusColor;
                              Color statusBgColor;

                              switch (status.toString().toLowerCase()) {
                                case 'resolved':
                                  statusColor = Colors.green;
                                  statusBgColor = Colors.green.withOpacity(0.1);
                                  break;
                                case 'in progress':
                                  statusColor = Colors.blue;
                                  statusBgColor = Colors.blue.withOpacity(0.1);
                                  break;
                                case 'being validated':
                                  statusColor = Colors.purple;
                                  statusBgColor = Colors.purple.withOpacity(0.1);
                                  break;
                                case 'needs recheck':
                                  statusColor = Colors.red;
                                  statusBgColor = Colors.red.withOpacity(0.1);
                                  break;
                                default:
                                  statusColor = Colors.orange;
                                  statusBgColor = Colors.orange.withOpacity(0.1);
                              }

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ComplaintDetailScreen(
                                          ticketId: doc.id,
                                          data: data,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(14),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.grey.withOpacity(0.1),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Text(
                                                    "ID: #${doc.id.length > 6 ? doc.id.substring(0, 6).toUpperCase() : doc.id}",
                                                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                    decoration: BoxDecoration(
                                                      color: statusBgColor,
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                    child: Text(
                                                      status,
                                                      style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                data['description'] ?? 'No description',
                                                style: const TextStyle(fontWeight: FontWeight.bold),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(data['category'] ?? 'General'),
                                              const SizedBox(height: 4),
                                              Text(date, style: const TextStyle(color: Colors.grey)),
                                            ],
                                          ),
                                        ),
                                        const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                                      ],
                                    ),
                                  ),
                                ),
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
}