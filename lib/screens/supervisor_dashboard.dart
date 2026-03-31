import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/supervisor_service.dart';

class SupervisorDashboard extends StatelessWidget {
  SupervisorDashboard({super.key});

  final SupervisorService supervisorService = SupervisorService();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xffF4F6FA),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('maintenance_supervisors')
            .doc(user!.uid)
            .get(),
        builder: (context, snapshot) {
          String name = "Supervisor";

          if (snapshot.hasData && snapshot.data!.exists) {
            final data = snapshot.data!.data() as Map<String, dynamic>?;
            if (data != null) {
              name =
                  data['fullName'] ??
                  data['name'] ??
                  data['username'] ??
                  "Supervisor";
            }
          }

          return Stack(
            children: [
              /// 🔵 BLUE HEADER
              Container(
                height: 220,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xff2D4AA8), Color(0xff1E3DD3)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(35),
                    bottomRight: Radius.circular(35),
                  ),
                ),
              ),

              /// 🔵 HEADER CONTENT
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 30, 20, 0),
                  child: _headerContent(name),
                ),
              ),

              /// ⚪ BODY
              Positioned(
                top: 110,
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 25, 20, 20),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(35),
                    ),
                  ),
                  child: ListView(
                    children: [
                      _statsRow(),
                      const SizedBox(height: 30),
                      _teamTitle(),
                      const SizedBox(height: 15),
                      _teamGrid(),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// 🔵 HEADER
  Widget _headerContent(String name) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Supervisor", style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 6),
            Text(
              name,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        Row(
          children: [
            _headerIcon(Icons.access_time),
            const SizedBox(width: 12),
            _headerIcon(Icons.notifications_none),
          ],
        ),
      ],
    );
  }

  Widget _headerIcon(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.7)),
      ),
      child: Icon(icon, color: Colors.white),
    );
  }

  /// 📊 STATS
  Widget _statsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        StreamBuilder(
          stream: supervisorService.getTeamMembers(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const StatCard(
                number: "...",
                label: "Team",
                icon: Icons.group,
                iconColor: Colors.black54,
                iconBg: Color(0xffE9EDF6),
              );
            }

            var count = snapshot.data!.docs.length;

            return StatCard(
              number: count.toString(),
              label: "Team",
              icon: Icons.group,
              iconColor: Colors.black54,
              iconBg: const Color(0xffE9EDF6),
            );
          },
        ),
        FutureBuilder(
          future: supervisorService.getUnassignedCount(),
          builder: (context, snapshot) {
            return StatCard(
              number: snapshot.data?.toString() ?? "...",
              label: "Unassigned",
              icon: Icons.access_time,
              iconColor: Colors.orange,
              iconBg: const Color(0xffFFE9CC),
            );
          },
        ),
        FutureBuilder(
          future: supervisorService.getAssignedCount(),
          builder: (context, snapshot) {
            return StatCard(
              number: snapshot.data?.toString() ?? "...",
              label: "Assigned",
              icon: Icons.settings,
              iconColor: Colors.blue,
              iconBg: const Color(0xffDCE8FF),
            );
          },
        ),
        FutureBuilder(
          future: supervisorService.getDoneCount(),
          builder: (context, snapshot) {
            return StatCard(
              number: snapshot.data?.toString() ?? "...",
              label: "Done",
              icon: Icons.check_circle,
              iconColor: Colors.green,
              iconBg: const Color(0xffDFF5E3),
            );
          },
        ),
      ],
    );
  }

  /// 📌 TITLE
  Widget _teamTitle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: const [
        Text(
          "My team",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text("View all >", style: TextStyle(color: Colors.grey)),
      ],
    );
  }

  /// 👥 TEAM GRID (FIXED)
  Widget _teamGrid() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'technician')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.only(top: 40),
            child: Center(
              child: Text(
                "No team members yet",
                style: TextStyle(color: Colors.grey),
              ),
            ),
          );
        }

        var team = snapshot.data!.docs;

        return SizedBox(
          height: 320,
          child: GridView.builder(
            itemCount: team.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 15,
              crossAxisSpacing: 15,
              childAspectRatio: 1,
            ),
            itemBuilder: (context, index) {
              var user = team[index];

              return TeamCard(
                technicianId: user.id,
                name: user['name'] ?? 'No Name',
                department: user['department'] ?? 'No Dept',
              );
            },
          ),
        );
      },
    );
  }
}

/// 📦 STAT CARD
class StatCard extends StatelessWidget {
  final String number;
  final String label;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;

  const StatCard({
    super.key,
    required this.number,
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 90,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xffF4F6FA),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: iconBg,
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(height: 8),
          Text(
            number,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(label, style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }
}

/// 👤 TEAM CARD (FIXED OVERFLOW)
class TeamCard extends StatelessWidget {
  final String technicianId;
  final String name;
  final String department;

  const TeamCard({
    super.key,
    required this.technicianId,
    required this.name,
    required this.department,
  });

  @override
  Widget build(BuildContext context) {
    String initials = name.length >= 2
        ? name.substring(0, 2).toUpperCase()
        : name[0].toUpperCase();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xffF4F6FA),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // ✅ FIX
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: const Color(0xffE6EBF5),
            child: Text(
              initials,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            name,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          Text(
            department,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 8), // ✅ FIX
          Row(
            children: [
              FutureBuilder<int>(
                future: SupervisorService().getTechnicianAssignedCount(
                  technicianId,
                ),
                builder: (context, snapshot) {
                  return Text(
                    "${snapshot.data ?? "..."} assigned",
                    style: const TextStyle(fontSize: 12),
                  );
                },
              ),
              const SizedBox(width: 6),
              const Text("•"),
              const SizedBox(width: 6),
              FutureBuilder<int>(
                future: SupervisorService().getTechnicianDoneCount(
                  technicianId,
                ),
                builder: (context, snapshot) {
                  return Text(
                    "${snapshot.data ?? "..."} done",
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.green,
                      fontWeight: FontWeight.w500,
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
