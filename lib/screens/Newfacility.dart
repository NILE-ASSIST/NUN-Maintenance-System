

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nileassist/main.dart';
import 'package:nileassist/screens/complaintDetail.dart';

class NewFMDashboard extends StatelessWidget {
  const NewFMDashboard({super.key});

  Stream<QuerySnapshot<Map<String, dynamic>>> _ticketsStream() {
    return FirebaseFirestore.instance.collection('tickets').snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyApp.nileBlue,
      body: SafeArea(
        bottom: false,
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _ticketsStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final docs = (snapshot.data?.docs ??
                    <QueryDocumentSnapshot<Map<String, dynamic>>>[])
              ..sort((a, b) {
                final aDate = a.data()['dateCreated'] as Timestamp?;
                final bDate = b.data()['dateCreated'] as Timestamp?;
                if (aDate == null && bDate == null) return 0;
                if (aDate == null) return 1;
                if (bDate == null) return -1;
                return bDate.compareTo(aDate);
              });

            final stats = _buildStats(docs);
            final recentComplaints = docs.take(3).toList();

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
                  child: _buildHeroHeader(),
                ),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    clipBehavior: Clip.antiAlias,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF8F9FC),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(40),
                        topRight: Radius.circular(40),
                      ),
                    ),
                    child: _buildBodyCard(context, stats, recentComplaints),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Map<String, int> _buildStats(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    int pending = 0;
    int inProgress = 0;
    int resolved = 0;

    final activeUsers = <String>{};
    final categories = <String, int>{};

    for (final doc in docs) {
      final data = doc.data();
      final status = (data['status'] ?? '').toString().trim().toLowerCase();
      final issuerId = (data['issuerID'] ?? '').toString();
      final category = (data['category'] ?? 'General').toString();

      if (issuerId.isNotEmpty) {
        activeUsers.add(issuerId);
      }

      categories[category] = (categories[category] ?? 0) + 1;

      if (status == 'pending') {
        pending += 1;
      } else if (status == 'in progress' || status == 'ongoing' || status == 'being validated') {
        inProgress += 1;
      } else if (status == 'resolved' || status == 'completed') {
        resolved += 1;
      }
    }

    int frequentIssueCount = 0;
    for (final entry in categories.entries) {
      if (entry.value > frequentIssueCount) {
        frequentIssueCount = entry.value;
      }
    }

    return {
      'total': docs.length,
      'inProgress': inProgress,
      'pending': pending,
      'activeUsers': activeUsers.length,
      'resolved': resolved,
      'frequentIssues': frequentIssueCount,
    };
  }

  Widget _buildHeroHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'FACILITY MANAGER',
                    style: TextStyle(
                      color: Color(0xFFCDD6FF),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Dr.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ),
            _iconChip(Icons.timer_outlined),
            const SizedBox(width: 10),
            _iconChip(Icons.notifications_none_rounded),
          ],
        ),
        const SizedBox(height: 44),
        const Text(
          'Operations overview for today',
          style: TextStyle(
            color: Color(0xFFE2E8FF),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _iconChip(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.42)),
      ),
      child: Icon(icon, color: Colors.white, size: 19),
    );
  }

  Widget _buildBodyCard(
    BuildContext context,
    Map<String, int> stats,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> recentComplaints,
  ) {
    final items = [
      _StatItem(
        'Total Complaints',
        stats['total'] ?? 0,
        Icons.confirmation_num,
        const Color(0xFF222222),
        const Color(0xFFF1F3F7),
      ),
      _StatItem(
        'In Progress',
        stats['inProgress'] ?? 0,
        Icons.sync_rounded,
        const Color(0xFF4A66E8),
        const Color(0xFFEAF0FF),
      ),
      _StatItem(
        'Pending',
        stats['pending'] ?? 0,
        Icons.access_time_filled_rounded,
        const Color(0xFFEF9C14),
        const Color(0xFFFFF5E4),
      ),
      _StatItem(
        'Active Users',
        stats['activeUsers'] ?? 0,
        Icons.group_rounded,
        const Color(0xFF555B6D),
        const Color(0xFFEFF2F8),
      ),
      _StatItem(
        'Resolved',
        stats['resolved'] ?? 0,
        Icons.check_circle_rounded,
        const Color(0xFF63B53F),
        const Color(0xFFE9F7E3),
      ),
      _StatItem(
        'Frequent Issues',
        stats['frequentIssues'] ?? 0,
        Icons.warning_amber_rounded,
        const Color(0xFFECA62D),
        const Color(0xFFFFF3DF),
      ),
    ];

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
      children: [
        const Text(
          'Today',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: Color(0xFF17181D),
          ),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth = (constraints.maxWidth - 12) / 2;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: items
                  .map(
                    (item) => SizedBox(
                      width: cardWidth,
                      child: _statCard(item),
                    ),
                  )
                  .toList(),
            );
          },
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Complaints',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Color(0xFF12131A),
              ),
            ),
            TextButton(
              onPressed: () {},
              child: Text(
                'View All',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: MyApp.nileBlue.withOpacity(0.9),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (recentComplaints.isEmpty)
          _emptyCard()
        else
          ...recentComplaints.map((doc) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _complaintCard(context, doc),
              )),
      ],
    );
  }

  Widget _statCard(_StatItem stat) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE9EDF5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: stat.bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(stat.icon, color: stat.iconColor, size: 22),
          ),
          const SizedBox(height: 8),
          Text(
            stat.value.toString(),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Color(0xFF141720),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            stat.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF6A7283),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text('No complaints found right now.'),
    );
  }

  Widget _complaintCard(BuildContext context, QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final status = (data['status'] ?? 'Pending').toString();
    final timestamp = data['dateCreated'] as Timestamp?;
    final date = timestamp != null ? DateFormat('MMM d, yyyy').format(timestamp.toDate()) : 'Just now';

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ComplaintDetailScreen(ticketId: doc.id, data: data, currentUserRole: 'facility_manager'),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE9EDF5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.025),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Tracking ID #${doc.id.length > 7 ? doc.id.substring(0, 7).toUpperCase() : doc.id.toUpperCase()}',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _statusChip(status),
                const SizedBox(width: 8),
                Text(
                  date,
                  style: const TextStyle(color: Color(0xFF6A7283), fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              (data['description'] ?? 'No description').toString(),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Color(0xFF202124),
                height: 1.25,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${data['category'] ?? 'General'} | ${data['location'] ?? 'Unknown'}',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF5A6070),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusChip(String status) {
    final normalized = status.toLowerCase();

    Color bg;
    Color fg;

    if (normalized == 'in progress' || normalized == 'ongoing' || normalized == 'being validated') {
      bg = const Color(0xFFE8EDFF);
      fg = const Color(0xFF4A66E8);
    } else if (normalized == 'resolved' || normalized == 'completed') {
      bg = const Color(0xFFE6F5E0);
      fg = const Color(0xFF5BAA37);
    } else {
      bg = const Color(0xFFFFF2DD);
      fg = const Color(0xFFEF9C14);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status,
        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: fg),
      ),
    );
  }
}

class _StatItem {
  final String title;
  final int value;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;

  const _StatItem(this.title, this.value, this.icon, this.iconColor, this.bgColor);
}
