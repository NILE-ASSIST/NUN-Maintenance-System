import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Status Timeline Widget
class StatusTimeline extends StatelessWidget {
  final String status;
  final Map<String, dynamic> data;

  const StatusTimeline({super.key, required this.status, required this.data});

  @override
  Widget build(BuildContext context) {
    final s = status.toLowerCase();
    
    final bool isSubmitted = true; 
    final bool isInProgress = s != 'pending'; 
    final bool isResolved = s == 'resolved';

    String? assignedName = data['assignedStaffName'] ?? data['assignedToName'];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Status Timeline",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          _buildTimelineStep(
            title: "Submitted",
            icon: Icons.description_rounded,
            isActive: isSubmitted,
            isLast: false,
          ),
          _buildTimelineStep(
            title: "In Progress",
            subtitle: isInProgress && assignedName != null ? "Assigned to: $assignedName" : null,
            icon: Icons.autorenew_rounded,
            isActive: isInProgress,
            isLast: false,
          ),
          _buildTimelineStep(
            title: "Resolved",
            icon: Icons.check_circle_rounded,
            isActive: isResolved,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineStep({
    required String title,
    String? subtitle,
    required IconData icon,
    required bool isActive,
    required bool isLast,
  }) {
    final boxColor = isActive ? const Color(0xFFDCECC9) : Colors.grey.shade300;
    final iconColor = isActive ? const Color(0xFF7CB342) : Colors.grey.shade500;
    final lineColor = isActive ? const Color(0xFF7CB342) : Colors.grey.shade300;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: boxColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: lineColor,
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                ]
              ],
            ),
          ),
        ),
      ],
    );
  }
}

//Person card widget (For fetching maintenance staff/supervisors) 
class AsyncPersonCard extends StatelessWidget {
  final String title;
  final String userId;
  final String collection;

  const AsyncPersonCard({
    super.key,
    required this.title,
    required this.userId,
    required this.collection,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection(collection).doc(userId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final userData = snapshot.data!.data() as Map<String, dynamic>?;
        if (userData == null) return const SizedBox.shrink();
        final name = userData['fullName'] ?? 'Unknown';
        final pfp = userData['profilePicture'];
        
        return Column(
          children: [
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title, 
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.bold)
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20, 
                        backgroundColor: Colors.blue.shade100, 
                        backgroundImage: pfp != null ? NetworkImage(pfp) : null, 
                        child: pfp == null ? const Icon(Icons.person, color: Colors.blue) : null
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

// Person card(For Issuer Info)
class PersonCard extends StatelessWidget {
  final String title;
  final String name;
  final String role;
  final IconData icon;
  final bool isEmail;

  const PersonCard({
    super.key,
    required this.title,
    required this.name,
    required this.role,
    required this.icon,
    this.isEmail = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4FF), 
        borderRadius: BorderRadius.circular(12), 
        border: Border.all(color: const Color(0xFFD0E0FF))
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.blue.shade700, size: 20), 
              const SizedBox(width: 8), 
              Text(title, style: TextStyle(color: Colors.blue.shade900, fontWeight: FontWeight.bold, fontSize: 12))
            ]
          ),
          const SizedBox(height: 8),
          isEmail 
              ? SelectableText(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Colors.black87)) 
              : Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Colors.black87)),
          isEmail 
              ? SelectableText(role, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Colors.grey)) 
              : Text(role, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Colors.grey)),
        ],
      ),
    );
  }
}

//Info Tile(For Location/Category)
class InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const InfoTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB), 
          borderRadius: BorderRadius.circular(12), 
          border: Border.all(color: Colors.grey.shade200)
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.grey.shade600, size: 20),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}