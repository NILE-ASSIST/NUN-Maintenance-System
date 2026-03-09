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
            /// FETCH SUPERVISOR NAME FROM FIRESTORE
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
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
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
            children: const [
              Icon(Icons.access_time, color: Colors.white),
              SizedBox(width: 18),
              Icon(Icons.notifications_none, color: Colors.white),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        /// TEAM COUNT
        StreamBuilder(
          stream: supervisorService.getTeamMembers(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const StatCard(
                number: "...",
                label: "Team",
                icon: Icons.group,
              );
            }

            var count = snapshot.data!.docs.length;

            return StatCard(
              number: count.toString(),
              label: "Team",
              icon: Icons.group,
            );
          },
        ),

        /// UNASSIGNED
        FutureBuilder(
          future: supervisorService.getUnassignedCount(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const StatCard(
                number: "...",
                label: "Unassigned",
                icon: Icons.access_time,
              );
            }

            return StatCard(
              number: snapshot.data.toString(),
              label: "Unassigned",
              icon: Icons.access_time,
            );
          },
        ),

        /// ASSIGNED
        FutureBuilder(
          future: supervisorService.getAssignedCount(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const StatCard(
                number: "...",
                label: "Assigned",
                icon: Icons.settings,
              );
            }

            return StatCard(
              number: snapshot.data.toString(),
              label: "Assigned",
              icon: Icons.settings,
            );
          },
        ),

        /// DONE
        FutureBuilder(
          future: supervisorService.getDoneCount(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const StatCard(
                number: "...",
                label: "Done",
                icon: Icons.check_circle,
              );
            }

            return StatCard(
              number: snapshot.data.toString(),
              label: "Done",
              icon: Icons.check_circle,
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

  const StatCard({
    super.key,
    required this.number,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 75,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xffF4F6FA),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: Colors.blueGrey),
          const SizedBox(height: 6),
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xffF4F6FA),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CircleAvatar(
            radius: 18,
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

              const SizedBox(width: 8),

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
