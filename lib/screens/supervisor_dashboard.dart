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
      body: SafeArea(
        child: Column(
          children: [
            FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('maintenance_supervisors')
                  .doc(user!.uid)
                  .get(),
              builder: (context, snapshot) {
                String name = "Supervisor";

                if (snapshot.hasData && snapshot.data!.exists) {
                  name = snapshot.data!['fullName'];
                }

                return _header(name);
              },
            ),

            Expanded(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(35)),
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
        ),
      ),
    );
  }

  Widget _header(String name) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 30, 20, 30),
      decoration: const BoxDecoration(
        color: Color(0xff2F4DA0),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Supervisor", style: TextStyle(color: Colors.white70)),

              const SizedBox(height: 4),

              Text(
                name,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),

          Row(
            children: [
              _headerIcon(Icons.access_time),
              const SizedBox(width: 10),
              _headerIcon(Icons.notifications_none),
            ],
          ),
        ],
      ),
    );
  }

  Widget _headerIcon(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white),
      ),
      child: Icon(icon, color: Colors.white),
    );
  }

  Widget _statsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        /// TEAM
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

        /// UNASSIGNED
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

        /// ASSIGNED
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

        /// DONE
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

  Widget _teamGrid() {
    return StreamBuilder(
      stream: supervisorService.getTeamMembers(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        var team = snapshot.data!.docs;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: team.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 15,
            crossAxisSpacing: 15,
            childAspectRatio: 1.35,
          ),
          itemBuilder: (context, index) {
            var user = team[index];

            return TeamCard(
              technicianId: user.id,
              name: user['name'],
              department: user['department'],
            );
          },
        );
      },
    );
  }
}

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
      width: 85,
      padding: const EdgeInsets.symmetric(vertical: 14),
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

          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Colors.black87),
          ),
        ],
      ),
    );
  }
}

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
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: const Color(0xffE6EBF5),
            child: Text(
              initials,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),

          const SizedBox(height: 5),

          Text(
            name,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),

          Text(
            department,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),

          Row(
            children: [
              FutureBuilder<int>(
                future: SupervisorService().getTechnicianAssignedCount(
                  technicianId,
                ),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Text("...", style: TextStyle(fontSize: 12));
                  }

                  return Text(
                    "${snapshot.data} assigned",
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
                  if (!snapshot.hasData) {
                    return const Text("...", style: TextStyle(fontSize: 12));
                  }

                  return Text(
                    "${snapshot.data} done",
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
