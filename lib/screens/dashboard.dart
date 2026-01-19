import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  // Fake dynamic data (later this comes from backend)
  final List<Map<String, dynamic>> stats = const [
    {"title": "Total", "value": 4, "icon": Icons.description},
    {"title": "Pending", "value": 1, "icon": Icons.schedule},
    {"title": "In Progress", "value": 1, "icon": Icons.sync},
    {"title": "Resolved", "value": 1, "icon": Icons.check_circle},
  ];

  final List<Map<String, dynamic>> tickets = const [
    {
      "status": "Pending",
      "color": Colors.orange,
      "title": "AC not cooling properly",
      "category": "Plumbing",
      "date": "Jan 19, 2024",
    },
    {
      "status": "In Progress",
      "color": Colors.blue,
      "title": "AC not cooling properly",
      "category": "Plumbing",
      "date": "Jan 19, 2024",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _header(),
              const SizedBox(height: 20),
              _statsRow(),
              const SizedBox(height: 20),
              _submitButton(),
              const SizedBox(height: 20),
              _recentTicketsSection(),
              const SizedBox(height: 20),
              _draftsCard(),
            ],
          ),
        ),
      ),
    );
  }

  // HEADER
  Widget _header() {
    return Container(
      height: 160,
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Color(0xFF243C8F),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "Greeting,\nDr.",
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.notifications, color: Colors.white),
          ),
        ],
      ),
    );
  }

  // STATS ROW
  Widget _statsRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: stats.map((stat) {
          return _StatCard(
            title: stat["title"],
            value: stat["value"].toString(),
            icon: stat["icon"],
          );
        }).toList(),
      ),
    );
  }

  // SUBMIT BUTTON
  Widget _submitButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          minimumSize: const Size(double.infinity, 55),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        onPressed: () {},
        icon: const Icon(Icons.add),
        label: const Text(
          "Submit New Complaint",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  // RECENT TICKETS
  Widget _recentTicketsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                "Recent Complaint Ticket",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text("View All >", style: TextStyle(color: Colors.blue)),
            ],
          ),
          const SizedBox(height: 12),
          ...tickets.map((ticket) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ticketCard(
                status: ticket["status"],
                color: ticket["color"],
                title: ticket["title"],
                category: ticket["category"],
                date: ticket["date"],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _ticketCard({
    required String status,
    required Color color,
    required String title,
    required String category,
    required String date,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text("Tracking ID"),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(color: color, fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(category),
                const SizedBox(height: 4),
                Text(date, style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, size: 16),
        ],
      ),
    );
  }

  // DRAFTS
  Widget _draftsCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: const [
            Icon(Icons.description),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Drafts", style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    "1 unsaved drafts",
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
  }
}

// STAT CARD WIDGET
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 75,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.blue),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}
