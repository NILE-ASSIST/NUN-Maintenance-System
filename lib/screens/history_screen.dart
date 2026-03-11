import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:nileassist/screens/complaintDetail.dart';
import 'package:nileassist/widgets/reusable_searchbar.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  // Brand colors extracted from main.dart / Figma
  static const Color nileBlue = Color.fromARGB(255, 2, 64, 177);
  static const Color cardGray = Color(0xFFF6F6F6);
  static const Color textGray = Color(0xFF737373);
  static const Color closedGreenBg = Color(0x5276B52B);
  static const Color closedGreenText = Color(0xFF76B52B);
  
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
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
                  const Icon(
                    Icons.history,
                    color: Colors.white,
                    size: 28,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'History',
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
                    children: [
                      const SizedBox(height: 30),
                      
                      // Search Bar
                      ReusableSearchBar(
                        hintText: 'Search tasks...',
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value.toLowerCase();
                          });
                        },
                      ),
                      
                      const SizedBox(height: 25),

                      // List View using real Firestore Data
                      Expanded(
                        child: StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('tickets')
                              .where('status', isEqualTo: 'Resolved')
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                               return const Center(child: CircularProgressIndicator());
                            }

                            if (snapshot.hasError) {
                               return Center(child: Text("Error fetching history: ${snapshot.error}"));
                            }

                            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                               return const Center(child: Text("No closed tickets found."));
                            }

                            // Filter and sort docs
                            List<QueryDocumentSnapshot> docs = snapshot.data!.docs.where((doc) {
                              if (_searchQuery.isEmpty) return true;
                              final data = doc.data() as Map<String, dynamic>;
                              final title = (data['description'] ?? '').toString().toLowerCase();
                              final location = (data['location'] ?? '').toString().toLowerCase();
                              final shortId = doc.id.substring(0, 6).toLowerCase();
                              return title.contains(_searchQuery) ||
                                     location.contains(_searchQuery) || 
                                     shortId.contains(_searchQuery);
                            }).toList();

                            docs.sort((a, b) {
                              final dA = a.data() as Map<String, dynamic>;
                              final dB = b.data() as Map<String, dynamic>;
                              Timestamp? tA = dA['dateCompleted'] ?? dA['dateCreated'];
                              Timestamp? tB = dB['dateCompleted'] ?? dB['dateCreated'];
                              
                              if (tA == null) return 1;
                              if (tB == null) return -1;
                              return tB.compareTo(tA);
                            });

                            if (docs.isEmpty) {
                              return const Center(child: Text("No matching history found."));
                            }

                            return ListView.builder(
                              physics: const BouncingScrollPhysics(),
                              itemCount: docs.length,
                              itemBuilder: (context, index) {
                                final doc = docs[index];
                                final data = doc.data() as Map<String, dynamic>;
                                return _buildHistoryCard(context, doc.id, data);
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

  Widget _buildHistoryCard(BuildContext context, String docId, Map<String, dynamic> data) {
    // Parsing Data
    final String description = data['description'] ?? 'No Description provided';
    final String location = data['location'] ?? 'Unknown location';
    final String priorityStr = data['severity'] ?? 'Low';
    
    // Formatting Dates
    final Timestamp? createdTs = data['dateCreated'];
    final Timestamp? completedTs = data['dateResolved'] ?? data['dateCompleted'];

    final String dateStr = createdTs != null 
        ? DateFormat('MMM d, yyyy').format(createdTs.toDate()) 
        : '--';
        
    final String completedDateStr = completedTs != null 
        ? DateFormat('MMM d, yyyy').format(completedTs.toDate()) 
        : '--';

    final String shortId = docId.length > 6 ? docId.substring(0, 6).toUpperCase() : docId.toUpperCase();
    final String remarks = data['resolutionNotes'] ?? 'Closed by system / manager.';

    // Priority Styling Logic
    Color priorityColor;
    Color priorityBgColor;
    String priorityLabelText = priorityStr;
    
    switch (priorityStr.toLowerCase()) {
      case 'high':
      case 'urgent':
        priorityColor = Colors.red;
        priorityBgColor = Colors.red.withOpacity(0.15);
        priorityLabelText = "High";
        break;
      case 'medium':
        priorityColor = const Color(0xFFFF9800);
        priorityBgColor = const Color(0x47F1AC43); 
        priorityLabelText = "Medium";
        break;
      case 'low':
      default:
        priorityColor = Colors.grey.shade700;
        priorityBgColor = Colors.grey.shade300;
        priorityLabelText = "Low";
        break;
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ComplaintDetailScreen(ticketId: docId, data: data),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: Tracking ID & Badges & Date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      'ID: #$shortId',
                      style: const TextStyle(
                        color: textGray,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
  
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: priorityBgColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        priorityLabelText,
                        style: TextStyle(
                          color: priorityColor,
                          fontSize: 8,
                          fontWeight: FontWeight.w600,
    
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: closedGreenBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'Closed',
                        style: TextStyle(
                          color: closedGreenText,
                          fontSize: 8,
                          fontWeight: FontWeight.w600,
    
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  dateStr,
                  style: const TextStyle(
                    color: textGray,
                    fontSize: 8,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
  
            // Row 2: Title
            Text(
              description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 15,
                fontWeight: FontWeight.bold,
                fontFamily: 'Inter',
              ),
            ),
            
            const SizedBox(height: 8),
  
            // Row 3: Location
            Row(
              children: [
                const Icon(
                  Icons.location_on,
                  color: Colors.black54,
                  size: 14,
                ),
                const SizedBox(width: 4),
                 Expanded(
                   child: Text(
                    location,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 11,

                    ),
                                   ),
                 ),
              ],
            ),
  
            const SizedBox(height: 12),
  
            // Row 4: Remarks & Completion Date
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2.0),
                  child: Icon(
                    Icons.check_circle_outline,
                    color: Colors.black54,
                    size: 14,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        remarks,
                        style: const TextStyle(
                          color: Color(0xFF969696),
                          fontSize: 9,
                          fontStyle: FontStyle.italic,
    
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Completed $completedDateStr',
                        style: const TextStyle(
                           color: Color(0xFF969696),
                          fontSize: 8,
    
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
